_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

DataTables = require 'datatables'
Reports = require '../models/Reports'

class PeriodsummaryView extends Backbone.View
  el: "#content"

  events:
    "click button#dateFilter": "showForm"
  
  showForm: (e) =>
    e.preventDefault
    $("div#filters-section").slideToggle()

  render: =>

    @$el.html "
        <div id='dateSelector'></div>
    "
    options = Coconut.router.reportViewOptions

module.exports = PeriodsummaryView
