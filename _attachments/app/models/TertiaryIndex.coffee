timestamp = require 'time-stamp'
Case = require './Case'

class TertiaryIndex
  constructor: (options) ->
    @name = options.name
    @docsToSaveOnReset = options.docsToSaveOnReset
    @database = new PouchDB("#{Coconut.databaseURL}/zanzibar-index-#{@name.toLowerCase()}")

  latestChangeForZanzibarDatabase: =>
    new Promise (resolve,reject) =>
      Coconut.database.changes
        descending: true
        include_docs: false
        limit: 1
      .on "complete", (mostRecentChange) ->
        resolve(mostRecentChange.last_seq)
      .on "error", (error) ->
        reject error

  latestChangeForCurrentIndexDocs: =>
    @database.get "IndexData"
    .catch (error) ->
      console.error "Error while latestChangeForCurrentIndexDocs: #{error}"
      if error.reason is "missing"
        return Promise.resolve(null)
      else
        return Promise.reject("Non-missing error when latestChangeForCurrentIndexDocs")
    .then (indexData) ->
      return Promise.resolve(indexData?.lastChangeSequenceProcessed or null)

  reset: =>
    # Docs to save
    designDocs = await @database.allDocs
      startkey: "_design"
      endkey: "_design\uf777"
      include_docs: true
    .then (result) ->
      Promise.resolve _(result.rows).map (row) ->
        doc = row.doc
        delete doc._rev
        doc

    otherDocsToSave = await @database.allDocs
      include_docs: true
      keys: @docsToSaveOnReset
    .then (result) ->
      Promise.resolve( _(result.rows).chain().map (row) ->
          doc = row.doc
          delete doc._rev if doc
          doc
        .compact().value()
      )

    docsToSave = designDocs.concat(otherDocsToSave)
    databaseNameWithCredentials = @database.name

    await @database.destroy()
    .catch (error) -> 
      console.error error
      throw "Error while destroying database"

    @database = new PouchDB(databaseNameWithCredentials)
    await @database.bulkDocs docsToSave

    try
      latestChangeForZanzibarDatabase = await @latestChangeForZanzibarDatabase()

      console.log "Latest change: #{latestChangeForZanzibarDatabase}"
      console.log "Retrieving all available case IDs"

      Coconut.database.query "cases/cases"
      #Coconut.database.query "cases/cases",
      #  startkey: "0"
      #  endkey: "2"
      .then (result) =>
        allCases = _(result.rows).chain().pluck("key").uniq(true).reverse().value()
        console.log "Updating #{allCases.length} cases"

        await @updateIndexForCases
          caseIDs: allCases

        console.log "Updated #{@name} index from #{allCases.length} cases"

        @database.upsert "IndexData", (doc) =>
          doc.lastChangeSequenceProcessed = latestChangeForZanzibarDatabase
          doc
    catch error
      console.error 


  updateIndexDocs: =>
    latestChangeForZanzibarDatabase = await @latestChangeForZanzibarDatabase()
    latestChangeForCurrentIndexDocs = await @latestChangeForCurrentIndexDocs()
    #
    console.log "latestChangeForZanzibarDatabase: #{latestChangeForZanzibarDatabase?.replace(/-.*/, "")}, latestChangeForCurrentIndexDocs: #{latestChangeForCurrentIndexDocs?.replace(/-.*/,"")}"

    if latestChangeForCurrentIndexDocs
      numberLatestChangeForDatabase = parseInt(latestChangeForZanzibarDatabase?.replace(/-.*/,""))
      numberLatestChangeForCurrentIndexDocs = parseInt(latestChangeForCurrentIndexDocs?.replace(/-.*/,""))

      if numberLatestChangeForDatabase - numberLatestChangeForCurrentIndexDocs > 10000
        console.log "Large number of changes, so just resetting since this is more efficient that reviewing every change."
        return @reset()

    unless latestChangeForCurrentIndexDocs
      console.log "No recorded change for current index docs, so resetting"
      @reset()
    else
      #console.log "Getting changes since #{latestChangeForCurrentSummaryDataDocs.replace(/-.*/, "")}"
      # Get list of cases changed since latestChangeForCurrentSummaryDataDocs
      Coconut.database.changes
        since: latestChangeForCurrentIndexDocs
        include_docs: true
        filter: "_view"
        view: "cases/cases"
      .then (result) =>
        return if result.results.length is 0
        #console.log "Found changes, now plucking case ids"
        changedCases = _(result.results).chain().map (change) ->
          change.doc.MalariaCaseID if change.doc.MalariaCaseID? and change.doc.question?
        .compact().uniq().value()
        #console.log "Changed cases: #{_(changedCases).length}"

        await @updateIndexForCases
          caseIDs: changedCases
        console.log "Updated: #{changedCases.length} cases"

        @database.upsert "IndexData", (doc) =>
          doc.lastChangeSequenceProcessed = latestChangeForZanzibarDatabase
          doc
        .catch (error) => console.error error
        .then =>
          console.log "Index #{@name} Data updated through sequence: #{latestChangeForZanzibarDatabase}"


  updateIndexForCases: (options) =>

    new Promise (resolve, reject) =>

      return resolve() if options.caseIDs.length is 0

      numberOfCasesToProcess = options.caseIDs.length
      numberOfCasesProcessed = 0
      numberOfCasesToProcessPerIteration = 100

      while options.caseIDs.length > 0
        caseIDs = options.caseIDs.splice(0,numberOfCasesToProcessPerIteration) # remove 100 caseids

        cases = await Case.getCases
          caseIDs: caseIDs

        docsToSave = []
        for malariaCase in cases
          for indexDoc in await @indexDocsForCase(malariaCase)
            docsToSave.push indexDoc

        try
          await @database.bulkDocs(docsToSave)
        catch
          console.error "ERROR SAVING #{docsToSave.length} case summaries: #{caseIDs.join ","}"
          console.error error

        numberOfCasesProcessed += caseIDs.length
        console.log "#{numberOfCasesProcessed}/#{numberOfCasesToProcess} #{Math.floor(numberOfCasesProcessed/numberOfCasesToProcess*100)}% (last ID: #{caseIDs.pop()})"

      resolve()

  ###      
  updateIndexForCases: (options) =>

    new Promise (resolve, reject) =>

      docsToSave = []
      return resolve() if options.caseIDs.length is 0

      for caseID, counter in options.caseIDs
        console.log "#{caseID}: (#{counter+1}/#{options.caseIDs.length} #{Math.floor(((counter+1) / options.caseIDs.length) * 100)}%)"

        # See app/models/Reports.coffee for a way to load multiple cases at once, instead of one query per case

        malariaCase = new Case
          caseID: caseID
        try
          await malariaCase.fetch()
        catch
          console.error "ERROR fetching case: #{caseID}"
          console.error error

        for indexDoc in @indexDocsForCase(malariaCase)
          docsToSave.push indexDoc

        if docsToSave.length > 500
          try
            await @database.bulkDocs(docsToSave)
          catch
            console.error "ERROR SAVING #{docsToSave.length} case summaries: #{caseIDs.join ","}"
            console.error error
          docsToSave.length = 0 # Clear the array: https://stackoverflow.com/questions/1232040/how-do-i-empty-an-array-in-javascript

      try
        await @database.bulkDocs(docsToSave)
        console.log "Updated #{docsToSave.length} positive individuals for #{options.caseIDs.length} cases"
        resolve()
      catch error
        console.error "ERROR SAVING #{docsToSave.length} case summaries: #{caseIDs.join ","}"
        console.error error
  ###

  indexDocsForCase: (malariaCase) =>
    indexDocs = []
    
    individuals = malariaCase.positiveAndNegativeIndividualObjects()
    caseID = malariaCase.caseID

    if individuals.length is 0
      console.log "No individuals for case: #{caseID}"

    for individual, index in individuals

      docId = "ind_#{caseID}_#{index}"

      currentIndividualIndexDoc = null
      try 
         currentIndividualIndexDoc = await @database.get(docId)
      catch
        # Ignore if there is no document

      try
        updatedIndividualIndexDoc = individual.summaryCollection()
      catch error
        console.error error

      updatedIndividualIndexDoc["_id"] = docId
      updatedIndividualIndexDoc._rev = currentIndividualIndexDoc._rev if currentIndividualIndexDoc?
      updatedIndividualIndexDoc.indexUpdatedAt = timestamp('YYYY-MM-DD HH:mm:ss') 

      indexDocs.push updatedIndividualIndexDoc

    return indexDocs

module.exports = TertiaryIndex
