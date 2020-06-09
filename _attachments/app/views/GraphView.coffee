_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
camelize = require "underscore.string/camelize"

Graphs = require '../models/Graphs'
CasesTabulatorView = require './CasesTabulatorView'
DateSelectorView = require './DateSelectorView'
AdministrativeAreaSelectorView = require './AdministrativeAreaSelectorView'

class GraphView extends Backbone.View

  el: "#content"

  render: =>

    @options.startDate or= Coconut.router.defaultStartDate()
    @options.endDate or= Coconut.router.defaultEndDate()
    @options.administrativeLevel or= "NATIONAL"
    @options.administrativeName or= "ZANZIBAR"


    @graphName = Graphs.getGraphName(@options.type)
    @graph = Graphs.definitions[@graphName]

    HTMLHelpers.ChangeTitle("Graphs: " + @graphName)
    @$el.html "
      <div id='dateSelector' style='display:inline-block'></div>
      <div id='dateDescription' style='display:inline-block;vertical-align:top;margin-top:10px'></div>
      <div id='administrativeAreaSelector'/>
      <div class='chart-title'>
        #{@graphName}
      </div>
      <div id='canvas'>
        <canvas id='#{camelize(@graphName)}'></canvas>
      </div>
      </div>
      <div>
        #{@graph.description}
      </div>
      <h2>Details</h2>
      <div id='tabulatorView'>
      </div>
    "

    @dateSelectorView = new DateSelectorView()
    @dateSelectorView.setElement "#dateSelector"
    @dateSelectorView.startDate = @options.startDate
    @dateSelectorView.endDate = @options.endDate
    @dateSelectorView.onChange = (startDate, endDate) =>
      @options.startDate = startDate.format("YYYY-MM-DD")
      @options.endDate = endDate.format("YYYY-MM-DD")
      @renderData()
    @dateSelectorView.render()

    @administrativeAreaSelectorView = new AdministrativeAreaSelectorView()
    @administrativeAreaSelectorView.setElement "#administrativeAreaSelector"
    @administrativeAreaSelectorView.administrativeLevel = @options.administrativeLevel
    @administrativeAreaSelectorView.administrativeName = @options.administrativeName
    @administrativeAreaSelectorView.onChange = (administrativeName, administrativeLevel) => 
      @options.administrativeName = administrativeName
      @options.administrativeLevel = administrativeLevel
      @renderData()
    @administrativeAreaSelectorView.render()

    @renderData()

  renderData: =>
    # Clear the canvas during the load
    @$("#canvas").html "
      <canvas id='#{camelize(@graphName)}'></canvas>
    "
    Coconut.router.navigate "graph/type/#{@options.type}/startDate/#{@options.startDate}/endDate/#{@options.endDate}/administrativeLevel/#{@options.administrativeLevel}/administrativeName/#{@options.administrativeName}"
    @renderGraph()
    @renderTabulator()

  renderGraph: =>
    Graphs.render(@graphName, await @graph.dataQuery(@options))

  renderTabulator: =>
    if @graph.detailedDataQuery
      global.casesTabulatorView = new CasesTabulatorView()
      casesTabulatorView.data = await @graph.detailedDataQuery(@options)
      casesTabulatorView.tabulatorFields = @graph.tabulatorFields
      casesTabulatorView.setElement("#tabulatorView")
      casesTabulatorView.render()

module.exports = GraphView
