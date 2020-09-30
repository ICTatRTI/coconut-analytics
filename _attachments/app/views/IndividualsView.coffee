DateSelectorView = require './DateSelectorView'
AdministrativeAreaSelectorView = require './AdministrativeAreaSelectorView'
TabulatorView = require './TabulatorView'
titleize = require 'underscore.string/titleize'

class IndividualsView extends Backbone.View

  el: "#content"

  render: =>
    console.log @

    @options.startDate or= Coconut.router.defaultStartDate()
    @options.endDate or= Coconut.router.defaultEndDate()
    @options.administrativeLevel or= "NATIONAL"
    @options.administrativeName or= "ZANZIBAR"

    @$el.html "
      <div id='dateSelector' style='display:inline-block'></div>
      <div id='dateDescription' style='display:inline-block;vertical-align:top;margin-top:10px'></div>
      <div id='administrativeAreaSelector'/>
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
      administrativeLevel = titleize(administrativeLevel.toLowerCase().replace(/ies$/,"y").replace(/s$/,""))
      unless @tabulatorView.tabulator.setHeaderFilterValue(administrativeLevel,administrativeName) is undefined
        if confirm "If #{administrativeLevel} exists in the data do you want to add it?"
          #Add it
          @tabulatorView.selector.setValue([{
            label: administrativeLevel
            value: administrativeLevel
          }])
          @tabulatorView.renderTabulator()
          @tabulatorView.tabulator.setHeaderFilterValue(administrativeLevel,administrativeName)

    @administrativeAreaSelectorView.render()

    @renderData()

  renderData: =>
    Coconut.router.navigate "individuals/startDate/#{@options.startDate}/endDate/#{@options.endDate}"
    @renderTabulator()

  renderTabulator: =>
    @tabulatorView = new TabulatorView()
    @tabulatorView.tabulatorFields = [
      "Island"
      "District"
      "Malaria Case ID"
      "Date Of Malaria Results"
      "Malaria Test Result"
      "Classification"
    ]
    @tabulatorView.data = await Coconut.individualIndexDatabase.query "individualsByDiagnosisDate",
      startkey: @options.startDate
      endkey: @options.endDate
      include_docs: true
    .then (result) =>
      Promise.resolve(_(result.rows).pluck "doc")
    @tabulatorView.availableFields = await Coconut.individualIndexDatabase.query "individualFields",
      reduce: true
      group: true
    .then (result) =>
      Promise.resolve (_(result.rows).chain()
        .pluck "key"
        .difference ["_rev","_id"]
        .value()
      )

    @tabulatorView.setElement("#tabulatorView")
    @tabulatorView.render()

module.exports = IndividualsView
