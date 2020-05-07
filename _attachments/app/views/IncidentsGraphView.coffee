_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

Graphs = require '../models/Graphs'
moment = require 'moment'
dc = require 'dc'
d3 = require 'd3'

class IncidentsGraphView extends Backbone.View
  el: "#content"

  render: =>
    options = $.extend({},Coconut.router.reportViewOptions)
    title = "Positive Individuals By Week: Current vs Last Year"
    HTMLHelpers.ChangeTitle("Graphs: " + title)
    @$el.html "
       <style>
         .y-axis-label { margin-right: 20px}
       </style>
       <div class='chart-title'>#{title}</div>
       <canvas id='epiCurve'></canvas>
    "

    Graphs.incidents @$("#epiCurve")

module.exports = IncidentsGraphView
