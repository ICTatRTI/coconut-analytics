$ = require 'jquery'

Backbone = require 'backbone'
Backbone.$  = $

Tabulator = require 'tabulator-tables'
Choices = require 'choices.js'

distinctColors = (require 'distinct-colors').default
Chart = require 'chart.js'
ChartDataLabels = require 'chartjs-plugin-datalabels'

Chart = require 'chart.js'


class TabulatorView extends Backbone.View

  events:
    "click #download": "csv"
    "click #downloadItemCount": "itemCountCSV"
    "change select#columnToCount": "updateColumnCount"

  csv: => @tabulator.download "csv", "CoconutTableExport.csv"

  itemCountCSV: => @itemCountTabulator.download "csv", "CoconutTableExport.csv"

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
      <div>
        Number of Rows: 
        <span id='numberRows'></span>
      </div>
      <br/>
      <div>
        Count items in column
        <select id='columnToCount'>
        </select>
        <div id='itemCount'>
          <button id='downloadItemCount'>CSV ↓</button>
          <div style='width: 200px; display:inline-block' id='itemCountTabulator'></div>
          <div style='width: 600px; display:inline-block; vertical-align:top' id='itemCountChart'>
            <canvas id='itemCountChartCanvas'></canvas>
          </div>
        </div>
      </div>
    "

    unless @availableFields?
      # Take a sample of all of the possible fields to keep things fast and hopefully not miss any important ones
      @availableFields = {}
      @normalizeData()
      for doc in _(@data).sample(1000)
        for key in _(doc).keys()
          @availableFields[key] = true

      @availableFields = _(@availableFields).keys()

    if @excludeFields
      @availableFields = @availableFields.filter (field) => 
        not @excludeFields.includes(field)

    @tabulatorFields or= [
      "Malaria Case ID" # default if no other defined
    ]

    #console.log @tabulatorFields

    choicesData = for field in _(@tabulatorFields.concat(_(@availableFields).sort())).uniq() # This preserves order of tabulatorFields and alphabetizes the rest
      value: field
      selected: if _(@tabulatorFields).contains field then true else false

    @selector = new Choices "#availableFields",
      choices: choicesData
      shouldSort: false
      removeItemButton: true

    @$("#availableFields")[0].addEventListener 'change', (event) =>
      @renderTabulator()

    @renderTabulator()


  updateColumnCountOptions: =>
    @$("#columnToCount").html "<option></option>" + (for column in @selector.getValue(true)
        "<option>#{column}</option>"
      ).join("")

  updateColumnCount: =>
    columnFieldName = @$("#columnToCount option:selected").text()
    counts = {}

    if columnFieldName is ""
      @$("#itemCount").hide()
      return

    return unless @tabulator?

    @$("#itemCount").show()

    for rowData in @tabulator.getData("active")
      if rowData[columnFieldName] is undefined
        console.log rowData
      counts[rowData[columnFieldName]] or= 0
      counts[rowData[columnFieldName]] += 1

    countData = for fieldName, amount of counts
      {
        "#{columnFieldName}": fieldName
        Count: amount
      }

    countData = _(countData).sortBy("Count").reverse()

    @itemCountTabulator = new Tabulator "#itemCountTabulator",
      height: 400
      columns: [
        {field: columnFieldName, name: columnFieldName}
        {field: "Count", name: "Count"}
      ]
      initialSort:[
        {column:"Count", dir:"desc"}
      ]
      data: countData

    colors = distinctColors(
      count: Object.values(counts).length
      hueMin: 0
      hueMax: 360
      chromaMin: 40
      chromaMax: 70
      lightMin: 15
      lightMax: 85
    )

    ctx = @$("#itemCountChartCanvas")

    data = []
    labels = []


    if @chart?
      @chart.destroy()
    @chart = new Chart(ctx, {
      type: 'doughnut',
      data: 
        datasets: [
          {
            data: _(countData).pluck "Count"
            backgroundColor:  for distinctColor in colors
              color = distinctColor.rgb()
              "rgba(#{color.join(",")},0.5)"
          }
        ]
        labels: _(countData).pluck columnFieldName
      options:
        legend:
          position: 'right'

    })



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
        dataFiltered: (filters, rows) =>
          @$("#numberRows").html(rows.length)
          _.delay =>
            @updateColumnCount()
          , 500
        dataLoaded: (data) =>
          @$("#numberRows").html(data.length)
          _.delay =>
            @updateColumnCount()
          , 500

    @updateColumnCountOptions()

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
