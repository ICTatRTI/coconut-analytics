###
#
# This file is meant to be run on node.js not on the browser
# It allows you to update the "tertiary" index of cases
# These are just documents that follow the  naming convention: case_summary_CASE_ID
# It makes it easy to run queries against cases with this index available
#
# It can be run by typing
# > coffee UpdateCaseSummaryDocs.coffee
#
# A document in the database keeps track of which documents have already been processed
# When a new document appears in the database this script will check it to see if it effects
# the tertiary index and update it accordingly.
#
# Running this file checks for any new documents in the database and updates things accordingly.
# It then listens to the couchdb _changes feed FOREVER and continues to update the index as soon
# as any change is made.
#
#
###







# Make these global so that they can be used from the javascript console
global.Backbone = require 'backbone'
PouchDB = require 'pouchdb'
BackbonePouch = require 'backbone-pouch'
_ = require 'underscore'

global.Coconut =
  database: new PouchDB(process?.argv[2] or "http://localhost:5984/zanzibar")

# This is a PouchDB - Backbone connector - we only use it for a few things like getting the list of questions
Backbone.sync = BackbonePouch.sync
  db: Coconut.database
  fetch: 'query'

QuestionCollection = require './models/QuestionCollection'
DhisOrganisationUnits = require './models/DhisOrganisationUnits'
GeoHierarchyClass = require './models/GeoHierarchy'
dhisOrganisationUnits = new DhisOrganisationUnits()
dhisOrganisationUnits.loadExtendExport
  dhisDocumentName: "dhis2" # This is the document that was exported from DHIS2
  error: (error) -> console.error error
  success: (result) ->
    global.GeoHierarchy = new GeoHierarchyClass(result)
    global.FacilityHierarchy = GeoHierarchy # These have been combined
    Coconut.questions = new QuestionCollection()
    Coconut.questions.fetch
      error: (error) -> console.error error
      success: ->

        Case = require './models/Case'

        throttledUpdateCaseSummaryDocs = _.throttle (options) ->
          Case.updateCaseSummaryDocs(options)
        , 1000

        try
          #Case.resetAllCaseSummaryDocs()
          #
          #
          #Coconut.database.get "CaseSummaryData"
          #.then (result) ->
          #  result.lastChangeSequenceProcessed = 1000000
          #  Coconut.database.put result
          #  .then ->
              Case.updateCaseSummaryDocs
                maximumNumberChangesToProcess: 3000
                error: (error) ->
                  console.error "ERROR"
                  console.error error
                success: (result) ->
                  console.log "DONE"
                  Coconut.database.changes
                    live: true
                    since: "now"
                    filter: (doc) ->
                      doc._id isnt "CaseSummaryData"
                  .on "change", ->
                    throttledUpdateCaseSummaryDocs
                      error: (error) -> console.error error
                      success: (result) -> console.log "DONE"
        catch error
          console.log error
