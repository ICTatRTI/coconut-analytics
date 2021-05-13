_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

moment = require 'moment'
global.Graphs = require '../models/Graphs'
DateSelectorView = require './DateSelectorView'
AdministrativeAreaSelectorView = require './AdministrativeAreaSelectorView'
TabulatorView = require './TabulatorView'

class EntomologySpecimensView extends Backbone.View
  render: =>
    @options.startDate or= Coconut.router.defaultStartDate()
    @options.endDate or= Coconut.router.defaultEndDate()
    HTMLHelpers.ChangeTitle("Entomology Specimens")

    @$el.html "
      <div style='margin-bottom:10px'>
        Entomology Specimens
      </div>
      <div id='dateSelector' style='display:inline-block'></div>
      <div id='dateDescription' style='display:inline-block;vertical-align:top;margin-top:10px'></div>
      <div id='administrativeAreaSelector' style='display:inline-block;vertical-align:top;' />
      <div class='shortcuts' style='display:inline;vertical-align:top'></div>
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
      @tabulatorView.tabulator.replaceData([])
      @tabulatorView.data = await @getDataForTabulator()
      @tabulatorView.tabulator.replaceData(@tabulatorView.data)
      Coconut.router.navigate "entomology_specimens/startDate/#{@options.startDate}/endDate/#{@options.endDate}"
    @dateSelectorView.render()


    @administrativeAreaSelectorView = new AdministrativeAreaSelectorView()
    @administrativeAreaSelectorView.setElement "#administrativeAreaSelector"
    @administrativeAreaSelectorView.onChange = (administrativeName, administrativeLevel) => 
      administrativeLevel = titleize(administrativeLevel.toLowerCase().replace(/ies$/,"y").replace(/s$/,""))
      unless @tabulatorView.tabulator.setHeaderFilterValue(administrativeLevel,administrativeName) is undefined
        if _(@tabulatorView.availableFields).contains administrativeLevel
          #Add it
          @tabulatorView.selector.setValue([{
            label: administrativeLevel
            value: administrativeLevel
          }])
          @tabulatorView.renderTabulator()
          @tabulatorView.tabulator.setHeaderFilterValue(administrativeLevel,administrativeName)
        else
          alert "#{administrativeLevel} is not an available field in the data"
    @administrativeAreaSelectorView.render()

    @renderData()

  renderData: =>
    Coconut.router.navigate "entomology_specimens/startDate/#{@options.startDate}/endDate/#{@options.endDate}"
    @renderTabulator()

  getDataForTabulator: => 
    Coconut.entomologyDatabase.query "specimensByDate",
      startkey: @dateSelectorView.startDate
      endkey: @dateSelectorView.endDate
    .then (result) =>
      Promise.resolve _(result.rows).pluck "value"


  renderTabulator: =>
    @tabulatorView = new TabulatorView()
    @tabulatorView.tabulatorFields = [
      "date-of-collection"
      "district"
      "shehia"
      "pcr-result-species"
    ]
    @tabulatorView.excludeFields = [
      "_id"
      "_rev"
    ]
    @tabulatorView.data = await @getDataForTabulator()

    @tabulatorView.setElement("#tabulatorView")
    @tabulatorView.render()
    _.delay =>
      @tabulatorView.updateColumnCount("pcr-result-species")
    , 2000

module.exports = EntomologySpecimensView
