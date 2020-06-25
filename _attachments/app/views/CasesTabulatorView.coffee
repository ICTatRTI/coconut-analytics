$ = require 'jquery'

Backbone = require 'backbone'
Backbone.$  = $

Tabulator = require 'tabulator-tables'
Choices = require 'choices.js'

class CasesTabulatorView extends Backbone.View

  events:
    "click #download": "csv"

  csv: => @tabulator.download "csv", "CoconutTableExport.csv"

  fetchDataForCases: (caseids) =>

    Coconut.reportingDatabase.allDocs
      keys: for id in caseids
        "case_summary_#{id}"
      include_docs: true
    .then (result) => 
      @data = result.rows
      Promise.resolve @data

  render: =>
    @$el.html "
      <button id='download'>CSV ↓</button> <small>Add more fields by clicking the box below</small>
      <div id='tabulatorSelector'>
        <select id='availableFields' multiple></select>
      </div>
      <div id='selector'>
      </div>
      <div id='tabulator'></div>
    "

    # Take a sample of all of the possible fields to keep things fast and hopefully not miss any important ones
    availableFields = {}
    for doc in _(@data).chain().sample(50).pluck("doc").value()
      for key in _(doc).keys()
        availableFields[key] = true

    availableFields = _(availableFields).keys()

    #availableFields = _(@data[0].doc).keys()


    @tabulatorFields or= [
      "Malaria Case ID"
    ]

    data = for field in availableFields
      value: field
      selected: if _(@tabulatorFields).contains field then true else false

    @selector = new Choices "#availableFields",
      choices: data
      removeItemButton: true

    @$("#availableFields")[0].addEventListener 'change', (event) =>
      @renderTabulator()

    @renderTabulator()

  renderTabulator: =>
    columns = for field in @selector.getValue(true)
      result = {
        title: field
        field: field
        headerFilter: "input"
      }
      if field is "Malaria Case ID"
        result["formatterParams"] = urlPrefix: "#show/case/"
        result["formatter"] = "link"
      result

    if @tabulator
      @tabulator.setColumns(columns)
    else
      @tabulator = new Tabulator "#tabulator",
        height: 400
        columns: columns
        data: _(@data).pluck "doc"

module.exports = CasesTabulatorView
