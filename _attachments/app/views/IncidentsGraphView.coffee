_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

DataTables = require( 'datatables.net' )()
Reports = require '../models/Reports'
moment = require 'moment'
Rickshaw = require 'rickshaw'

class IncidentsGraphView extends Backbone.View
  el: "#content"

  render: =>
    options = Coconut.router.reportViewOptions
    @$el.html "
       <style>
       #chart_container {
         position: relative;
         font-family: Arial, Helvetica, sans-serif;
         margin-top: 50px;
       }
       #chart {
         position: relative;
         left: 40px;
       }
       #y_axis {
         position: absolute;
         top: 0;
         bottom: 0;
         width: 40px;
       }
       </style>
       <div id='dateSelector'></div>
        
       <div id='chart_container'>
         <div id='y_axis'></div>
         <div id='chart'></div>
       </div>
    "
    $('#analysis-spinner').show()
     
    startDate = moment(options.startDate, 'YYYY-MM-DD')
    Coconut.database.query "#{Coconut.config.design_doc_name}/positiveCases",
      startkey: startDate.year()
      include_docs: false
    .catch (error) ->
      console.error error
    .then (result) =>
      casesPerAggregationPeriod = {}
      _.each result.rows, (row) ->
        date = moment(row.key.substr(0,10), 'DD-MM-YYYY')
        if row.key.substr(0,2) is "20" and date.isValid() and date.isBetween(startDate, new moment())
          aggregationKey = date.clone().endOf("isoweek").unix()
          casesPerAggregationPeriod[aggregationKey] = 0 unless casesPerAggregationPeriod[aggregationKey]
          casesPerAggregationPeriod[aggregationKey] += 1

      dataForGraph = _.map casesPerAggregationPeriod, (numberOfCases, date) ->
        x: parseInt(date)
        y: numberOfCases
      if dataForGraph.length == 0
         $('div#chart_container').html('<h6>No Records found for date range</h6>')
      else
        graph = new Rickshaw.Graph
          element: document.querySelector("#chart")
          width: 580
          height: 350
          series: [
              color: 'steelblue'
              data: dataForGraph
          ]
        
        x_axis = new Rickshaw.Graph.Axis.Time
          graph: graph

        y_axis = new Rickshaw.Graph.Axis.Y
          graph: graph
          orientation: 'left'
          tickFormat: Rickshaw.Fixtures.Number.formatKMBT
          element: document.getElementById('y_axis')

        graph.render()
            
      $('#analysis-spinner').hide()
       
module.exports = IncidentsGraphView
