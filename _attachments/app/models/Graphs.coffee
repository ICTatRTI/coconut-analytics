_ = require 'underscore'
moment = require 'moment'
Rickshaw = require 'rickshaw'

class Graphs

Graphs.IncidentsGraph = (options, callback) ->
  options.couch_view = "positiveCases"
  options.renderer = 'area'
  Graphs.createGraph options, (err, response) ->
    if (err) then console.log(err) else callback(null, "Success")

Graphs.YearlyTrends = (options, callback) ->
  #TODO: update to appropriate couchdb view name for yearly trends
  options.couch_view = "positiveCases"
  options.renderer = 'line'
  Graphs.createGraph options, (err, response) ->
    if (err) then console.log(err) else callback(null, "Success")
    
Graphs.BarChart = (options, callback) ->
  #TODO: update to appropriate couchdb view name for yearly trends
  options.couch_view = "positiveCases"
  options.renderer = 'bar'
  Graphs.createGraph options, (err, response) ->
    if (err) then console.log(err) else callback(null, "Success")
    
Graphs.ScatterPlot = (options, callback) ->
  #TODO: update to appropriate couchdb view name for yearly trends
  options.couch_view = "positiveCases"
  options.renderer = 'scatterplot'
  Graphs.createGraph options, (err, response) ->
    if (err) then console.log(err) else callback(null, "Success")
         
Graphs.createGraph = (options, callback) ->
    y_axis = options.y_axis
    div_chart = options.chart
    container = options.container
    chart_width = options.chart_width || 580
    chart_height = options.chart_height || 350
    couch_view = options.couch_view
    graph_renderer = options.renderer
    
    #startDate = moment(options.startDate, 'YYYY-MM-DD')
    startDate = moment.utc("2012-07-01")
    Coconut.database.query "#{Coconut.config.design_doc_name}/#{couch_view}",
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
         $("div##{container}").html('<h6>No Records found for date range</h6>')
      else
        graph = new Rickshaw.Graph
          element: document.querySelector("##{div_chart}")
          width: chart_width
          height: chart_height
          renderer: graph_renderer
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
          element: document.getElementById("#{y_axis}")

        graph.render()
        callback(null, "Success")
      
module.exports = Graphs