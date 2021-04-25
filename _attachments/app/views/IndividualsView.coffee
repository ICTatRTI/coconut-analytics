DateSelectorView = require './DateSelectorView'
AdministrativeAreaSelectorView = require './AdministrativeAreaSelectorView'
TabulatorView = require './TabulatorView'
titleize = require 'underscore.string/titleize'
TertiaryIndex = require '../models/TertiaryIndex'

class IndividualsView extends Backbone.View

  el: "#content"

  events:
    "click .shortcut": "shortcut"
    "click #updateIndex": "updateIndex"

  updateIndex: =>
    @updateIndividualIndexForAllSelectedRows()

  shortcut: (event) =>
    columnName = $(event.target).attr("data-columnName")
    value = $(event.target).attr("data-value")
    if columnName is "Age In Years"
      if value is "All"
        @tabulatorView.tabulator.removeFilter(columnName, "<", 5 )
        @tabulatorView.tabulator.removeFilter(columnName, ">=", 5 )
      else if value is "<5"
        @tabulatorView.tabulator.setFilter(columnName, "<", 5 )
      else if value is ">=5"
        @tabulatorView.tabulator.setFilter(columnName, ">=", 5 )
    else
      value = "" if value is "All"
      @tabulatorView.tabulator.setHeaderFilterValue(columnName,value)

  render: =>
    @options.startDate or= Coconut.router.defaultStartDate()
    @options.endDate or= Coconut.router.defaultEndDate()
    HTMLHelpers.ChangeTitle("Tested Individuals Data")

    @$el.html "
      <div style='margin-bottom:10px'>
        Each row represents an individual that test positive at a facility or someone that tests positive or negative during investigation/followup activities at households.
      </div>
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
      <div class='shortcuts' style='margin-left:10px;display:inline-block;vertical-align:top'>
        Age:<br/> #{
          (for value in ["All","<5",">=5"]
            "<button class='shortcut' data-columnName='Age In Years' data-value='#{value}'>#{value}</button>"
          ).join("")
        }
      </div>
      <div style='margin-top:20px'>
        #{
          if Coconut.currentUser.isAdmin()
            "<button style='float:right' id='updateIndex'>Update Individual Index for Selected Rows</button>"
          else
            ""
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
      @tabulatorView.tabulator.replaceData([])
      data = await @getDataForTabulator()
      @tabulatorView.data = data
      @tabulatorView.tabulator.replaceData(data)
      Coconut.router.navigate "individuals/startDate/#{@options.startDate}/endDate/#{@options.endDate}"
    @dateSelectorView.render()


    @administrativeAreaSelectorView = new AdministrativeAreaSelectorView()
    @administrativeAreaSelectorView.setElement "#administrativeAreaSelector"
    @administrativeAreaSelectorView.onChange = (administrativeName, administrativeLevel) => 

      unless @tabulatorView.selector.getValue(true).includes("Administrative Levels")
        @tabulatorView.selector.setValue([{
          label: "Administrative Levels"
          value: "Administrative Levels"
        }])
        @tabulatorView.renderTabulator()

      administrativeLevelsFilterText = @administrativeAreaSelectorView.ancestors.reverse().join(",") + ",#{@administrativeAreaSelectorView.administrativeName}"
      @tabulatorView.tabulator.setHeaderFilterValue("Administrative Levels",administrativeLevelsFilterText)
    @administrativeAreaSelectorView.render()

    @renderData()

  renderData: =>
    Coconut.router.navigate "individuals/startDate/#{@options.startDate}/endDate/#{@options.endDate}"
    @renderTabulator()

  getDataForTabulator: =>
    await Coconut.individualIndexDatabase.query "individualsByDiagnosisDate",
      startkey: @options.startDate
      endkey: @options.endDate
      include_docs: true
    .then (result) =>
      Promise.resolve _(result.rows).pluck "doc"

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
    @tabulatorView.pivotFields = ["Household District", "Classification"]
    @tabulatorView.data = await @getDataForTabulator()
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

  selectedCaseIds: =>
    malariaCaseIds = {}
    for rowData in @tabulatorView.tabulator.getData("active")
      malariaCaseIds[rowData["Malaria Case ID"]] = true

    Object.keys(malariaCaseIds)

  updateIndividualIndexForAllSelectedRows: =>
    caseIDs = @selectedCaseIds()
    if confirm("Are you sure you want to update the individal index for #{caseIDs.length} cases? Cases changed by DMSOs automatically get updated, but if the GeoHierarchy or something else has changed from a data cleaning exercise, then this process is a good way to updates the values in this table. This process uses a lot of data and bandwidth (100 cases required about 1 minute on a fast connection/computer")
      @tertiaryIndex or= new TertiaryIndex
        name: "Individual"
      await @tertiaryIndex.updateIndexForCases({caseIDs:caseIDs})
      if confirm("Update complete, would you like to reload this page?")
        @render()


module.exports = IndividualsView
