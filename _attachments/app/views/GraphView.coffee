_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
camelize = require "underscore.string/camelize"

Graphs = require '../models/Graphs'

class GraphView extends Backbone.View

  el: "#content"

  render: (options) =>
    graphName = Graphs.getGraphName(options.type)
    graph = Graphs.definitions[graphName]

    HTMLHelpers.ChangeTitle("Graphs: " + graphName)
    @$el.html "
      <div class='chart-title'>#{graphName}</div>
        <canvas id='#{camelize(graphName)}'></canvas>
      </div>
      <div>
        #{graph.description}
      </div>
    "

    unless options.startDate? and not _(options.startDate).isEmpty()
      options.startDate = moment().subtract(4, 'weeks').startOf("isoWeek")
    unless options.endDate? and not _(options.endDate).isEmpty()
      options.endDate = moment()

    unless document.location.hash.match(/#graphs\/.*\//) # has a date
      Coconut.router.navigate("graphs/#{camelize(graphName)}/#{options.startDate.format("YYYY-MM-DD")}/#{options.endDate.format("YYYY-MM-DD")}")

    data =  await graph.dataQuery(options)
    Graphs.render(graphName, data)


module.exports = GraphView
