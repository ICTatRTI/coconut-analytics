argv = require('minimist')(process.argv.slice(2))
_ = require 'underscore'

PouchDB = require 'pouchdb-core'
PouchDB.plugin(require('pouchdb-upsert'))
PouchDB.plugin(require('pouchdb-adapter-http'))
PouchDB.plugin(require('pouchdb-mapreduce'))


moment = require 'moment'
GeoHierarchyClass = require './models/GeoHierarchy'


updateShehiaMetadata = (shehiaName, date, classification,shehiaMetadata) =>
  #Active => (With ongoing transmission – reported indigenous case within this reporting calendar year)
  #Residual Active => (Transmission interrupted recently - The last indigenous case(s) was detected in the previous calendar year or up to 3 years earlier)
  #Cleared => (No indigenous case(s) for more than 3 years, could be reporting only imported or/and relapsing or or/and induced cases may occur in the recrudescent cases current calendar year.
  # For determining whether a case was indigenous or not we use the case classification when we have it, otherwise we assume that the case was indigenous.
  # Please note: THE YEAR IS CONSIDERED CALENDAR YEAR NOT PREVIOUS 12 MONTHS.

  year = date.trim()[0..3]
  currentYear = "#{moment().year()}"
  threeYearsAgo = currentYear-2 # e.g. if now is 2019 then we are interested in 2017,2018,2019 hence 2019-2 = 2017

  console.log "#{year}: #{currentYear}: #{classification}"

  shehiaMetadata[shehiaName] or= {}
  shehiaMetadata[shehiaName]["Focus Classification"] or= "Cleared"

  if classification is "Indigenous"
    if year >= threeYearsAgo
      shehiaMetadata[shehiaName]["Focus Classification"] = "Residual Active"
    if year is currentYear
      shehiaMetadata[shehiaName]["Focus Classification"] = "Active"
      console.log "ACTIVE"

analyzeCases = =>
  new Promise (resolve, reject) =>
    console.log "Getting 3 years of cases"
    Coconut.reportingDatabase.query "caseIDsByDate",
      startkey: moment().subtract(3,"years").format("YYYY-MM-DD")
      include_docs: true
    .catch (error) => console.error error
    .then (result) =>
      console.log "Cases loaded"

      shehiaMetadata = (await Coconut.reportingDatabase.get("shehia metadata")).Shehias

      for row, index in result.rows
        malariaCase = row.doc
        shehiaName = malariaCase["Shehia"]?.toUpperCase()

        if shehiaName
          if malariaCase["Classifications By Diagnosis Date"] isnt ""

            for dateAndClassification in malariaCase["Classifications By Diagnosis Date"].split(",")

              [date,classification] = dateAndClassification.split(": ")
              updateShehiaMetadata(shehiaName,date,classification,shehiaMetadata)
          else
            updateShehiaMetadata(shehiaName,malariaCase["Index Case Diagnosis Date"],"Indigenous",shehiaMetadata)

      console.log "Cases analyzed"

      console.log "Setting missing shehias to 'Cleared'"
      validShehiaNames = _(GeoHierarchy.findAllForLevel("Shehia")).pluck "name"
      for shehia in validShehiaNames
        unless shehiaMetadata[shehia.name]
          console.log "Missing #{shehia.name}"
          shehiaMetadata[shehia.name] =
            "Focus Classifications": "Cleared"

      console.log "Making sure all shehia names are upper case and valid"
      for shehiaName, data of shehiaMetadata
        if shehiaName isnt shehiaName.toUpperCase()
          shehiaMetadata[shehiaName.toUpperCase()] = shehiaMetadata[shehiaName]
          delete shehiaMetadata[shehiaName]

        unless _(validShehiaNames).includes shehiaName.toUpperCase()
          console.log "#{shehiaName} is not valid"
          delete shehiaMetadata[shehiaName]

      resolve(shehiaMetadata)

updateDatabaseDocument = (shehiaMetadata) =>
  Coconut.reportingDatabase.upsert "shehia metadata", (doc) =>
    doc.Shehias = shehiaMetadata
    doc

( =>
  global.Coconut =
    database: new PouchDB argv.database
    reportingDatabase: new PouchDB "#{argv.database}-reporting",

  global.GeoHierarchy = new GeoHierarchyClass()
  await GeoHierarchy.load()
  console.log "GeoHierarchy loaded"

  shehiaMetadata = await analyzeCases()

  console.log shehiaMetadata

  console.log "Updating shehia metadata"
  await updateDatabaseDocument(shehiaMetadata)
  console.log "Process complete"
)()
