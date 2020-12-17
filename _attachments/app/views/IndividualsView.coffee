DateSelectorView = require './DateSelectorView'
AdministrativeAreaSelectorView = require './AdministrativeAreaSelectorView'
TabulatorView = require './TabulatorView'
titleize = require 'underscore.string/titleize'

class IndividualsView extends Backbone.View

  el: "#content"

  events:
    "click .shortcut": "shortcut"

  shortcut: (event) =>
    columnName = $(event.target).attr("data-columnName")
    value = $(event.target).attr("data-value")
    value = "" if value is "All"
    @tabulatorView.tabulator.setHeaderFilterValue(columnName,value)

  render: =>
    @options.startDate or= Coconut.router.defaultStartDate()
    @options.endDate or= Coconut.router.defaultEndDate()

    @$el.html "
      <div id='dateSelector' style='display:inline-block'></div>
      <div id='dateDescription' style='display:inline-block;vertical-align:top;margin-top:10px'></div>
      <div id='administrativeAreaSelector' style='display:inline-block;vertical-align:top;' />
      <div class='shortcuts' style='margin-left:10px;display:inline-block;vertical-align:top'>
        Malaria Positive:<br/> #{
          (for value in ["All","true","false"]
            "<button class='shortcut' data-columnName='Malaria Positive' data-value='#{value}'>#{value}</button>"
          ).join("")
        }
      </div>
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
    Coconut.router.navigate "individuals/startDate/#{@options.startDate}/endDate/#{@options.endDate}"
    @renderTabulator()

  renderTabulator: =>
    @tabulatorView = new TabulatorView()
    @tabulatorView.tabulatorFields = [
      "Household Island"
      "Household District"
      "Malaria Case ID"
      "Date Of Malaria Results"
      "Malaria Positive"
      "Classification"
    ]
    @tabulatorView.data = await Coconut.individualIndexDatabase.query "individualsByDiagnosisDate",
      startkey: @options.startDate
      endkey: @options.endDate
      include_docs: true
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
