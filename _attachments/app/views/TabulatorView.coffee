$ = require 'jquery'
require 'jquery-ui-browserify'

Backbone = require 'backbone'
Backbone.$  = $

Tabulator = require 'tabulator-tables'
Choices = require 'choices.js'

distinctColors = (require 'distinct-colors').default
Chart = require 'chart.js'
ChartDataLabels = require 'chartjs-plugin-datalabels'

Chart = require 'chart.js'
require 'jquery-ui-browserify'
PivotTable = require 'pivottable'


class TabulatorView extends Backbone.View

  events:
    "click #download": "csv"
    "click #downloadItemCount": "itemCountCSV"
    "change select#columnToCount": "updateColumnCount"
    "click #pivotButton": "loadPivotTable"

  csv: => @tabulator.download "csv", "CoconutTableExport.csv"

  itemCountCSV: => @itemCountTabulator.download "csv", "CoconutTableExport.csv"

  # Support passing direct result of query or array of docs
  normalizeData: =>
    if @data.rows? and @data.total_rows?
      @data = @data.rows
    if @data[0]?.id? and @data[0].key? and @data[0].value? and @data[0].doc?
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
      <h4>Additional Analysis</h4>
      <div>
        To count and graph unique values in a particular column, select the column here: <select id='columnToCount'>
        </select>
        <div id='itemCount'>
          <div style='width: 200px; display:inline-block' id='itemCountTabulator'></div>
          <button style='vertical-align:top' id='downloadItemCount'>CSV ↓</button>
          <div style='width: 600px; display:inline-block; vertical-align:top' id='itemCountChart'>
            <canvas id='itemCountChartCanvas'></canvas>
          </div>
        </div>
      </div>
      <hr/>
      <div id='pivotTableDiv'>
        For more complicated groupings and comparisons you can create a <button id='pivotButton'>Pivot Table</button>. The pivot table can also output CSV data that can be copy and pasted into a spreadsheet.
        <div id='pivotTable'></div>
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

  updateColumnCount: (columnFieldName) =>
    columnFieldName or= @$("#columnToCount option:selected").text()
    counts = {}

    if columnFieldName is ""
      @$("#itemCount").hide()
      return

    return unless @tabulator?

    @$("#itemCount").show()

    for rowData in @tabulator.getData("active")
      counts[rowData[columnFieldName]] or= 0
      counts[rowData[columnFieldName]] += 1

    countData = for fieldName, amount of counts
      {
        "#{columnFieldName}": fieldName
        Count: amount
      }

    countData = _(countData).sortBy("Count").reverse()

    return unless countData.length > 0

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




  loadPivotTable: =>
    data = for rowData in @tabulator.getData("active")
      _(rowData).pick @selector.getValue(true)

    #@$("#pivotTable").pivot data,
    #  rows: ["Classification"]
    #  cols: ["Household District"]
    @pivotFields or= @tabulatorFields[0..1]

    @$("#pivotTable").pivotUI data,
      rows: [@pivotFields[0]]
      cols: [@pivotFields[1]]
      rendererName: "Heatmap"
      renderers: _($.pivotUtilities.renderers).extend "CSV Export": (pivotData, opts) ->
        defaults = localeStrings: {}

        opts = $.extend(true, {}, defaults, opts)

        rowKeys = pivotData.getRowKeys()
        rowKeys.push [] if rowKeys.length == 0
        colKeys = pivotData.getColKeys()
        colKeys.push [] if colKeys.length == 0
        rowAttrs = pivotData.rowAttrs
        colAttrs = pivotData.colAttrs

        result = []

        row = []
        for rowAttr in rowAttrs
            row.push rowAttr
        if colKeys.length == 1 and colKeys[0].length == 0
            row.push pivotData.aggregatorName
        else
            for colKey in colKeys
                row.push colKey.join("-")

        result.push row

        for rowKey in rowKeys
            row = []
            for r in rowKey
                row.push r

            for colKey in colKeys
                agg = pivotData.getAggregator(rowKey, colKey)
                if agg.value()?
                    row.push agg.value()
                else
                    row.push ""
            result.push row
        text = ""
        for r in result
            text += r.join(",")+"\n"

        return $("<textarea>").text(text).css(
                width: ($(window).width() / 2) + "px",
                height: ($(window).height() / 2) + "px")










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
