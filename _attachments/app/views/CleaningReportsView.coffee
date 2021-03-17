_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

DataTables = require( 'datatables.net' )()
Reports = require '../models/Reports'
HTMLHelpers = require '../HTMLHelpers'
CaseView = require './CaseView'

class CleaningReportsView extends Backbone.View
  el: "#content"
    
  events:
    "click button#closeDialog": "closeDialog"

  render: =>
    @$el.html("<h1>Missing Ids</h1>")
    Coconut.database.query "cases",
      startkey: "120000"
      endkey: "150000"
    .then (result) =>
      ids = {}
      first = null
      last = null
      for row in result.rows
        if row.key.match(/^\d\d\d\d\d\d$/)
          idAsInt = parseInt(row.key)
          ids[idAsInt] = true
          first = idAsInt unless first
          last = idAsInt

      missingIds = []
      for index in[first..last]
        unless ids[index]
          missingIds.push index

      console.log missingIds.length

      inRange = false
      for id, index in missingIds
        if missingIds[index-1] is id-1
          inRange = true
          console.log "in range"
        else if inRange
          inRange = false
          @$el.append "-#{missingIds[index-1]}<br/>"
          @$el.append "#{id}"
        else
          @$el.append "<br/>#{id}"
        
module.exports = CleaningReportsView
