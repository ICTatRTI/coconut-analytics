_ = require 'underscore'
moment = require 'moment'
Rickshaw = require 'rickshaw'
d3 = require 'd3'
Reports = require './Reports'
class Graphs

Graphs.IncidentsGraph = (options) ->
  options.couch_view = "positiveCases"
  options.renderer = 'line'
  options.names = ['Incident']
  return new Promise (resolve, reject) ->
    Graphs.retrieveData options
    .then (result) ->
      options.dataForGraph = [result]
      Graphs.createGraph options
      .then (response) ->
        resolve(response)
      .catch (err) ->
        console.log("Graph create error") 
        reject(err)
    .catch (err) ->
      console.log("Retrieval error")
      reject(err)
        
        
Graphs.PositiveCasesGraph = (options) ->
  options.renderer = 'lineplot'
  options.names = ["Age < 5","Age >= 5"]
  options.dataForGraph = []
  options.couch_view = "positiveCasesLT5"
  return new Promise (resolve, reject) ->
    Graphs.retrieveData options
    .then (result) ->
      options.dataForGraph .push(result)
      options.couch_view = "positiveCasesGT5"
      Graphs.retrieveData options
      .then (response) ->
          options.dataForGraph.push(response)
          Graphs.createGraph options
          .then (response) ->
            resolve(response)
          .catch (err) ->
            reject(err)
      .catch (err) ->
        reject(err)
    .catch (err) ->
      reject(err)

Graphs.YearlyTrends = (options, callback) ->
  #TODO: update to appropriate couchdb view name for yearly trends
  options.couch_view = "positiveCases"
  options.renderer = 'lineplot'
  options.names = ['test']
  Graphs.createGraph options, (err, response) ->
    if (err) then console.log(err) else callback(null, "Success")
        
Graphs.BarChart = (options) ->
  options.couch_view = "positiveCases"
  options.renderer = 'bar'
  options.names = ['test']
  return new Promise (resolve, reject) ->
    Graphs.retrieveData options
    .then (result) ->
      options.dataForGraph = [result]
      Graphs.createGraph options
      .then (response) ->
        resolve(response)
      .catch (err) ->
        reject(err)
    .catch (err) ->
      reject(err)
    
Graphs.ScatterPlotChart = (options) ->
  options.couch_view = "positiveCases"
  options.renderer = 'scatterplot'
  options.names = ['test']
  return new Promise (resolve, reject) ->
    Graphs.retrieveData options
    .then (result) ->
      options.dataForGraph = [result]
      Graphs.createGraph options
      .then (response) ->
        resolve(response)
      .catch (err) ->
        reject(err)
    .catch (err) ->
      console.log("Retrieval error")
      reject(err)

Graphs.retrieveData = (options) ->
  startDate = moment(options.startDate).format('YYYY-MM-DD')
  endDate = moment(options.endDate).format('YYYY-MM-DD')
  #startDate = moment.utc("2012-07-01")
  return new Promise (resolve,reject) ->
    Coconut.database.query "#{Coconut.config.design_doc_name}/#{options.couch_view}",
      startkey: startDate
      endkey: endDate
      include_docs: false
    .then (result) =>
      casesPerAggregationPeriod = {}
      data4Graph = {}
      _.each result.rows, (row) ->
        date = moment(row.key.substr(0,10), 'YYYY-MM-DD')
        if row.key.substr(0,2) is "20" and date.isValid() and date.isBetween(startDate, endDate)
          aggregationKey = date.clone().endOf("isoweek").unix()
          casesPerAggregationPeriod[aggregationKey] = 0 unless casesPerAggregationPeriod[aggregationKey]
          casesPerAggregationPeriod[aggregationKey] += 1
        
          data4Graph = _.map casesPerAggregationPeriod, (numberOfCases, date) ->
            x: parseInt(date)
            y: numberOfCases
      
      resolve(data4Graph)
    .catch (error) ->
      console.error error
      reject(error)
    
             
Graphs.createGraph = (options, callback) ->
    x_axis = options.x_axis
    y_axis = options.y_axis
    div_chart = options.chart
    container = options.container
    chart_width = 0.8 * $('.chart_container').width()
    chart_height = options.chart_height || 450
    couch_view = options.couch_view
    graph_renderer = options.renderer
    legend = options.legend || 'legend'
    return new Promise (resolve,reject) ->
      if options.dataForGraph.length == 0 or _.isEmpty(options.dataForGraph[0])
         $("div##{container}").html("<center><div style='margin-top: 5%'><h6>No records found for date range</h6></div></center>")
         reject("No record for date range")
      else
        palette = new Rickshaw.Color.Palette({scheme: Coconut.config.graphColorScheme })
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
          padding: 
            top: 0.02
            left: 0.02
            right: 0.02 
            bottom: 0.02
          
  
        hoverDetail = new Rickshaw.Graph.HoverDetail
          graph: graph
          formatter: (series,x,y) ->
            return "#{series.name} :  #{parseInt(y)}"
        
        x_axis = new Rickshaw.Graph.Axis.Time
          graph: graph
          orientation: 'bottom'
          element: document.getElementById("#{x_axis}")
          pixelsPerTick: 200
        
        y_axis = new Rickshaw.Graph.Axis.Y
          graph: graph
          orientation: 'left'
          tickFormat: Rickshaw.Fixtures.Number.formatKMBT
          element: document.getElementById("#{y_axis}")

        # x_ticks = new Rickshaw.Graph.Axis.X
        #   graph: graph
        #   orientation: 'bottom'
        #   element: document.getElementById("#{x_axis}")
        #   pixelsPerTick: 200
        #   tickFormat: Rickshaw.Fixtures.Time
   
        if options.dataForGraph.length > 1
          legend = new Rickshaw.Graph.Legend
            element: document.querySelector("##{legend}"),
            graph: graph
        
        graph.render()
        resolve("Success")

        window.addEventListener 'resize', ->
          elmnt = $("##{container}")
          graph.configure
            width: 0.8 * $(elmnt).width()
            height: 0.8 * $(elmnt).height()
          graph.render()

      
module.exports = Graphs