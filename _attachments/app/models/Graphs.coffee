_ = require 'underscore'
moment = require 'moment'
Rickshaw = require 'rickshaw'
d3 = require 'd3'
Reports = require './Reports'
class Graphs

Graphs.IncidentsGraph = (options, callback) ->
  options.couch_view = "positiveCases"
  options.renderer = 'area'
  options.names = ['Incident']
  Graphs.retrieveData options, (err, result) ->
    if (err)
      console.log(err)
    else
      options.dataForGraph = [result]
      Graphs.createGraph options, (err, response) ->
        if (err) then console.log(err) else callback(null, "Success")
    
Graphs.PositiveCasesGraph = (options, callback) ->
  options.couch_view = "positiveCasesLT5"
  options.renderer = 'lineplot'
  options.names = ["Age < 5","Age > 5"]
  options.dataForGraph = []
  Graphs.retrieveData options, (err, response) ->
    if (err)
      console.log(err)
    else
      options.dataForGraph .push(response)
      options.couch_view = "positiveCasesGT5"
      Graphs.retrieveData options, (err, response) ->
        if (err)
          console.log(err)
        else
          options.dataForGraph.push(response)
          Graphs.createGraph options, (err, response) ->
            if (err) then console.log(err) else callback(null, "Success")
    

Graphs.YearlyTrends = (options, callback) ->
  #TODO: update to appropriate couchdb view name for yearly trends
  options.couch_view = "positiveCases"
  options.renderer = 'lineplot'
  options.name = 'test'
  Graphs.createGraph options, (err, response) ->
    if (err) then console.log(err) else callback(null, "Success")

Graphs.AreaChart = (options, callback) ->
  #TODO: update to appropriate couchdb view name for yearly trends
  options.couch_view = "positiveCases"
  options.renderer = 'area'
  options.name = 'test'
  Graphs.createGraph options, (err, response) ->
    if (err) then console.log(err) else callback(null, "Success")
        
Graphs.BarChart = (options, callback) ->
  #TODO: update to appropriate couchdb view name for yearly trends
  options.couch_view = "positiveCases"
  options.renderer = 'bar'
  options.name = 'test'
  Graphs.createGraph options, (err, response) ->
    if (err) then console.log(err) else callback(null, "Success")
    
Graphs.ScatterPlot = (options, callback) ->
  #TODO: update to appropriate couchdb view name for yearly trends
  options.couch_view = "positiveCases"
  options.renderer = 'scatterplot'
  options.name = 'test'
  Graphs.createGraph options, (err, response) ->
    if (err) then console.log(err) else callback(null, "Success")

Graphs.retrieveData = (options,callback) ->
  #startDate = moment(options.startDate, 'YYYY-MM-DD')
  startDate = moment.utc("2012-07-01")
  Coconut.database.query "#{Coconut.config.design_doc_name}/#{options.couch_view}",
    startkey: startDate.year()
    include_docs: false
  .then (result) =>
    casesPerAggregationPeriod = {}
    data4Graph = {}
    _.each result.rows, (row) ->
      date = moment(row.key.substr(0,10), 'DD-MM-YYYY')
      if row.key.substr(0,2) is "20" and date.isValid() and date.isBetween(startDate, new moment())
        aggregationKey = date.clone().endOf("isoweek").unix()
        casesPerAggregationPeriod[aggregationKey] = 0 unless casesPerAggregationPeriod[aggregationKey]
        casesPerAggregationPeriod[aggregationKey] += 1
        
        data4Graph = _.map casesPerAggregationPeriod, (numberOfCases, date) ->
          x: parseInt(date)
          y: numberOfCases
        
    callback(null, data4Graph)
  .catch (error) ->
    console.error error
    callback(error)
    
             
Graphs.createGraph = (options, callback) ->
    y_axis = options.y_axis
    div_chart = options.chart
    container = options.container
    chart_width = options.chart_width || 580
    chart_height = options.chart_height || 350
    couch_view = options.couch_view
    graph_renderer = options.renderer
    
    #startDate = moment(options.startDate, 'YYYY-MM-DD')
    # startDate = moment.utc("2012-07-01")
 #    Coconut.database.query "#{Coconut.config.design_doc_name}/#{couch_view}",
 #      startkey: startDate.year()
 #      include_docs: false
 #    .then (result) =>
 #      casesPerAggregationPeriod = {}
 #      _.each result.rows, (row) ->
 #        date = moment(row.key.substr(0,10), 'DD-MM-YYYY')
 #        if row.key.substr(0,2) is "20" and date.isValid() and date.isBetween(startDate, new moment())
 #          aggregationKey = date.clone().endOf("isoweek").unix()
 #          casesPerAggregationPeriod[aggregationKey] = 0 unless casesPerAggregationPeriod[aggregationKey]
 #          casesPerAggregationPeriod[aggregationKey] += 1
 #
 #      dataForGraph = _.map casesPerAggregationPeriod, (numberOfCases, date) ->
 #        x: parseInt(date)
 #        y: numberOfCases

    if options.dataForGraph.length == 0
       $("div##{container}").html('<h6>No Records found for date range</h6>')
    else
      palette = new Rickshaw.Color.Palette()
      graphSeries =[]
      i = 0
      _.each options.dataForGraph, (series_data) ->
        graphSeries.push 
          name: options.names[i],
          color: palette.color()
          data: series_data
        i += 1
        
      graph = new Rickshaw.Graph
        element: document.querySelector("##{div_chart}")
        width: chart_width
        height: chart_height
        renderer: graph_renderer
        series: graphSeries
  
      hoverDetail = new Rickshaw.Graph.HoverDetail
        graph: graph
        
      x_axis = new Rickshaw.Graph.Axis.Time
        graph: graph

      y_axis = new Rickshaw.Graph.Axis.Y
        graph: graph
        orientation: 'left'
        tickFormat: Rickshaw.Fixtures.Number.formatKMBT
        element: document.getElementById("#{y_axis}")

      legend = new Rickshaw.Graph.Legend
              element: document.querySelector('#legend'),
              graph: graph
      
      graph.render()
      callback(null, "Success")
  # .catch (error) ->
  #   console.error error
      
module.exports = Graphs