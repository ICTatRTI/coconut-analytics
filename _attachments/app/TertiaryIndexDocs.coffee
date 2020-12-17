###
#
# This file is meant to be run on node.js not on the browser
# It allows you to update the "tertiary" index of cases
# These are just documents that follow the  naming convention: case_summary_CASE_ID
# It makes it easy to run queries against cases with this index available
#
# It can be run by typing
# > coffee CaseSummaryDocs.coffee --database http://admin:password@localhost:5984/coconut-surveillance-zanzibar -update
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

argv = require('minimist')(process.argv.slice(2));

# Make these global so that they can be used from the javascript console
global.Backbone = require 'backbone'
global.PouchDB = require 'pouchdb-core'
PouchDB.plugin(require('pouchdb-upsert'))
PouchDB.plugin(require('pouchdb-adapter-http'))
PouchDB.plugin(require('pouchdb-mapreduce'))

BackbonePouch = require 'backbone-pouch'
_ = require 'underscore'
moment = require 'moment'

TertiaryIndex = require './models/TertiaryIndex'

global.Coconut =
  databaseURL: argv.database
  database: new PouchDB "#{argv.database}/zanzibar",
    ajax:
      timeout: 1000 * 60 * 10

# This is a PouchDB - Backbone connector - we only use it for a few things like getting the list of questions
Backbone.sync = BackbonePouch.sync
  db: Coconut.database
  fetch: 'query'

console.log "Getting config"

Coconut.database.get "coconut.config"
.catch (error) -> 
  console.error error
.then (doc) ->
  Coconut.config = doc
  Coconut.config.role_types = if Coconut.config.role_types then Coconut.config.role_types.split(",") else ["admin", "reports"]

  console.log "Getting users"

  await Coconut.database.allDocs
    startkey: "user"
    endkey: "user\uf000"
    include_docs: true
  .then (result) =>
    Coconut.nameByUsername = {}
    for row in result.rows
      Coconut.nameByUsername[row.id.replace(/user./,"")] = row.doc.name
    Promise.resolve()

  QuestionCollection = require './models/QuestionCollection'
  GeoHierarchyClass = require './models/GeoHierarchy'
  global.GeoHierarchy = new GeoHierarchyClass()
  await GeoHierarchy.load()
  global.FacilityHierarchy = GeoHierarchy # These have been combined
  Coconut.questions = new QuestionCollection()
  Coconut.questions.fetch
    error: (error) -> console.error error
    success: ->
      try
        console.log "Loading classes"
      catch error
        console.error error

      tertiaryIndex = new TertiaryIndex(
        name: "Individual"
        docsToSaveOnReset: []
      )

      if argv.update
        process.stdout.write "Update: #{moment().format("YYYY-MM-DD hh:mm")} "

        tertiaryIndex.updateIndexDocs()
          .catch (error) ->
            console.error "ERROR"
            console.error error
          .then (result) ->
            console.log " done."

      else if argv.reset
        console.log "Resetting"

        tertiaryIndex.reset()
        .catch (error) => 
          console.error "ERROR"
          console.error error
        .then =>
          console.log " done."

      else
        console.log "No action, try --update"



.catch (error) ->
  console.error error
