$ = require 'jquery'

Backbone = require 'backbone'
Backbone.$  = $

Tabulator = require 'tabulator-tables'
Choices = require 'choices.js'

class TabulatorView extends Backbone.View

  events:
    "click #download": "csv"

  csv: => @tabulator.download "csv", "CoconutTableExport.csv"

  # Support passing direct result of query or array of docs
  normalizeData: =>
    if @data.rows? and @data.total_rows?
      @data = @data.rows
    if @data[0].id? and @data[0].key? and @data[0].value? and @data[0].doc?
      @data = _(@data).pluck "doc" 

  render: =>
    @$el.html "
      <button id='download'>CSV ↓</button> <small>Add more fields by clicking the box below</small>
      <div id='tabulatorSelector'>
        <select id='availableFields' multiple></select>
      </div>
      <div id='selector'>
      </div>
      <div id='tabulatorForTabulatorView'></div>
    "

    unless @availableFields?
      # Take a sample of all of the possible fields to keep things fast and hopefully not miss any important ones
      @availableFields = {}
      @normalizeData()
      for doc in _(@data).sample(1000)
        for key in _(doc).keys()
          @availableFields[key] = true

      @availableFields = _(@availableFields).keys()

    @tabulatorFields or= [
      "Malaria Case ID" # default if no other defined
    ]

    choicesData = for field in @availableFields
      value: field
      selected: if _(@tabulatorFields).contains field then true else false

    @selector = new Choices "#availableFields",
      choices: choicesData
      shouldSort: false
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

    @normalizeData()

    if @tabulator
      @tabulator.setColumns(columns)
      @tabulator.setData @data
    else
      @tabulator = new Tabulator "#tabulatorForTabulatorView",
        height: 500
        columns: columns
        data: @data

TabulatorView.showCasesDialog = (options) =>
  unless casesTabulatorDialog?
    $("body").append "
      <style>
        dialog{
          width: 80%;
          height: 80%;
        }
      </style>
      <dialog id='casesTabulatorDialog'>
        <div 
          style='float:right; font-size: 2em; cursor:pointer;' 
          onclick='document.getElementById(\"casesTabulatorDialog\").close()'
        >×</div>
        <div id='casesTabulator'></div>
      </dialog>
    "
  tabulatorView = new TabulatorView()
  tabulatorView.data = await Coconut.reportingDatabase.allDocs
      keys: for malariaCase in options.cases
        "case_summary_#{malariaCase}"
      include_docs: true
    .then (result) =>
      Promise.resolve result.rows
  tabulatorView.tabulatorFields = options.fields or ["Malaria Case ID"]
  tabulatorView.setElement($("#casesTabulator"))
  tabulatorView.render()
  if (Env.is_chrome)
     casesTabulatorDialog.showModal() if !casesTabulatorDialog.open
  else
     casesTabulatorDialog.show() if !casesTabulatorDialog.open

module.exports = TabulatorView
