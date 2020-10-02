_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
Tabulator = require 'tabulator-tables'
global.copy = require('copy-text-to-clipboard')
Chart = require 'chart.js'
Html2Pdf = require 'html2pdf.js'
Capitalize = require 'underscore.string/capitalize'

Reports = require '../models/Reports'
HTMLHelpers = require '../HTMLHelpers'
CaseView = require './CaseView'
Dialog = require './Dialog'
Graphs = require '../models/Graphs'
MapView = require './MapView'


class WeeklyMeetingReportView extends Backbone.View
  el: "#content"

  classifications:
    Indigenous: 
      color: "red"
    Imported:
      color: "blue"
    Introduced:
      color: "darkgreen"
    Induced: 
      color: "purple"
    Relapsing:
      color: "orange"

  mapControls: ".mapView .leaflet-control-zoom-in, .mapView .leaflet-control-zoom-out, .mapView .zoom, .mapView .leaflet-control-attribution, .mapView .controls"
        
  render: =>
    @renderDone = false

    @tabulators = []
    options = $.extend({},Coconut.router.reportViewOptions)
    HTMLHelpers.ChangeTitle("Reports: Weekly Meeting Report")
    @startDate = moment(options.startDate).startOf('isoWeek') or moment().subtract(1,'week').startOf('isoWeek')
    @endDate = moment(options.startDate).endOf('isoWeek') or moment().subtract(1,'week').endOf('isoWeek') # Note always do this relative to the startdate - just ignore the end date passed in

    $('#analysis-spinner').show()

    @selectedYear or= @startDate.isoWeekYear()
    @selectedWeek or= @startDate.isoWeek()

    summaryTableId = "summaryTable-#{@startDate.format('YYYY-MM-DD')}_#{@endDate.format('YYYY-MM-DD')}"
    summaryTableByDistrictId = "summaryTableByDistrict-#{@startDate.format('YYYY-MM-DD')}_#{@endDate.format('YYYY-MM-DD')}"

    @generatedAtText = "#{moment().format("DD MMM YYYY HH:mm")}"

    @$el.html "
      <div class='pdf-page page1'>
      <style>
        .mapViewWrapper{
          width: 410px;
          height: 590px;
          position: relative;
          display:inline-block;
          border: 1px solid black;
          padding: 10px;
        }
        .mapView{
          width: 100%%;
          height: 100%;
          position: relative;
        }
        .mapView #mapElement{
          background-color: white;
        }
        #{@mapControls}{
          display:none;
        }
        #map-UNGUJA .legend{
          display:none;
        }
        .mapView .controls .controlBox{
          padding-top: 0px;
          padding-bottom: 0px;
          border: 1px solid black;
          display:block;
        }
        .pdf-page{
          page-break-before: always;
        }
      </style>
        <div style='float:right'>
          Generated at: #{@generatedAtText}
          <br/>
          <button class='hide-for-printing' id='createWindowDownloadPDF'>Download PDF</button>
        </div>
        <dialog style='width:80%' id='dialog'>
          <div id='dialogContent'> </div>
        </dialog>
        <h1>Weekly Summary<br/>
          <h2>
            <select class='date' id='year'>
              #{
                (for year in [2012..moment().year()]
                  "<option #{if year is @selectedYear then "selected='true'" else ""}>#{year}</option>"
                ).join("")
              }
            </select>
              Week No. 
              <select class='date' id='week'>
              #{
                (for week in [1..53]
                  "<option #{if week is @selectedWeek then "selected='true'" else ""}>#{week}</option>"
                ).join("")
              }
            </select>
            <small>
              #{@startDate.format('YYYY-MM-DD')} - #{@endDate.format('YYYY-MM-DD')}
            </small>
          </h2>
        </h1>

        <hr/>
        <div id='zoneSummary'>
          <h2>Zone Summary</h2>
        </div>
      </div>

      <div id='charts'/>
      <hr/>

      <div class='pdf-page page6' id='maps'>
        <h2>Sprayed Shehias And Cases</h2>
        <div>
          <button id='mapControls'>Map Controls</button>
        </div>
        #{
          (for zone in GeoHierarchy.allZones()
            "
              <div class='mapViewWrapper'>
                <h3 class='map-title' style='text-align:center; margin:0'>#{Capitalize zone, true}</h3>
                <div class='mapView' id='map-#{zone}'></div>
              </div>
            "
          ).join("")
        }
      </div>

      <div class='pdf-page page7' id='districtSummary'>
        <br/>
        <br/>
        <h2>District Summary</h2>
      </div>
    "

    await @summaryData()
    await @malariaTrends()
    #

    for zone in GeoHierarchy.allZones()
      mapView = new MapView()
      mapView.setElement "#map-#{zone}"
      await mapView.render().then (map) =>
        mapView.showBoundary("Shehias")
        @$(".showSprayedShehias").prop "checked", true
        mapView.showSprayedShehias()
      mapView.zoom(zone)

    $("#analysis-spinner").hide()
    @renderDone = true
    
  events:
    "change .date":"updateDate"
    "click .cases":"showCases"
    "click .downloadCSV": "downloadCSV"
    "click .toggle-details": "toggleDetails"
    "click #createWindowDownloadPDF": "createWindowDownloadPDF"
    "click #mapControls": "toggleMapControls"

  # Open a new window that is the right size for the PDF
  # Wait until it is done rendering
  # THen generate the PDF
  createWindowDownloadPDF: =>
    pdfWindow = window.open(document.location, "", "width=900, height=200")

    while (not pdfWindow.Coconut?.router?.views?.WeeklyMeetingReport?) or pdfWindow?.Coconut?.router?.views?.WeeklyMeetingReport?.renderDone is false
      pdfWindow.document.getElementById("createWindowDownloadPDF")?.style.display = 'none'
      await (new Promise( (resolve) => setTimeout(resolve, 500)))

    pdfWindow.Coconut.router.views.WeeklyMeetingReport.download()


  toggleMapControls: =>
    for mapControl in @mapControls.split(", ")
      @$(mapControl).toggle()
      @$(".map-title").toggle()

  download: =>
    $(".hide-for-printing, .downloadCSV").hide()
    $(".date").css("background-color", "white")
    $(".date").css("border", "none")
    $("#mapControls").hide()
    for mapControl in @mapControls.split(", ")
      @$(mapControl).hide()
    #$(".pdf-page").css("width", "820px")
    #await _.delay(->,2000)

    await Html2Pdf $("#content")[0],
      filename: "Weekly-#{@generatedAtText}.pdf"
      jsPDF: 
        orientation: "landscape"
        format: "a4"
    $(".hide-for-printing, .downloadCSV").show()
    $(".date").css("background-color", "")
    $(".date").css("border", "")
    $("#mapControls").hide()



  toggleDetails: (event) =>
    targetCaseId = $(event.target).attr("data-target-case")
    @$("#details-#{targetCaseId}").toggle()
    @detailTablesByCaseId[targetCaseId].redraw(true)

  downloadCSV: (event) => 
    targetTabulator = $(event.target).attr("data-target-tabulator")
    @tabulators[targetTabulator].download "csv", "#{targetTabulator}.csv"

  showCases: (event) =>
    caseIds = $(event.target).attr("data-cases").split(',')
    column = $(event.target).attr("data-column")

    Dialog.create "
      (press Esc to close)<br/>
      <button onClick='window.copy(\"#{caseIds.join("\\n")}\")'>Copy list of Case Ids</button>
      #{
        (for caseId in caseIds
          console.log caseId
          "<div>
            <div>
              <a href='#show/case/#{caseId}'>#{caseId}</a> 
              <button data-target-case='#{caseId}' class='toggle-details'>Details</button>
              <button data-target-tabulator='#{caseId}' class='downloadCSV'>Download CSV</button>
              #{
                if column is "Positive Individuals"
                  "Classifications: #{@summaryCaseDataById[caseId]["Classifications By Household Member Type"]}"
                else if column.match(/Positive Individuals/)
                  "Evidence: #{@summaryCaseDataById[caseId]["Evidence For Classifications"]}"
                else if column.match(/Cases Notified/)
                  "Complete Household Visit: #{@summaryCaseDataById[caseId]["Complete Household Visit"]}"
                else
                  ""
              }
            </div>
            <div id='details-#{caseId}' class='details' style='display:none'>
            </div>
          </div>
          "
        ).join("")
      }
    "
    
    for caseId in caseIds
      @tabulators[caseId] = new Tabulator "#details-#{caseId}",

        height: 200
        columns: [
          {title: "Property", field: "property", headerFilter: "input"}
          {title: "Value", field: "value", headerFilter: "input"}
        ]
        data: (for property, value of @summaryCaseDataById[caseId]
          property: property
          value: value
        )

  updateDate: =>
    @startDate.isoWeekYear @$("#year").val()
    @startDate.isoWeek @$("#week").val()
    @endDate.isoWeekYear @$("#year").val()
    @endDate.isoWeek @$("#week").val()
    @selectedYear = @startDate.isoWeekYear()
    @selectedWeek = @startDate.isoWeek()

    Coconut.router.reportViewOptions['startDate'] = @startDate.format("YYYY-MM-DD")
    Coconut.router.reportViewOptions['endDate'] = @endDate.format("YYYY-MM-DD")
    if @reportType is 'dashboard'
      url = "reports/#{Coconut.router.reportViewOptions['startDate']}/#{Coconut.router.reportViewOptions['endDate']}"
    else
      url = "reports/"+("#{option}/#{value}" for option,value of Coconut.router.reportViewOptions).join("/")
    Coconut.router.navigate url
    @render()


  summaryData: =>

    aggregationArea = "Zone"
    aggregationPeriod = "Week"

    aggregatedWeeklyFacilityReport = await Reports.aggregateWeeklyReports
      startDate: @startDate
      endDate: @endDate
      aggregationArea: aggregationArea
      aggregationPeriod: aggregationPeriod

    previousAggregatedWeeklyFacilityReport = await Reports.aggregateWeeklyReports
      startDate: moment(@startDate).subtract(7,"days").format("YYYY-MM-DD")
      endDate: moment(@endDate).subtract(7,"days").format("YYYY-MM-DD")
      aggregationArea: aggregationArea
      aggregationPeriod: aggregationPeriod

    @summaryCaseDataById = {}

    summaryCaseData = await Coconut.reportingDatabase.query "caseIDsByDate",
      startkey: @startDate.format("YYYY-MM-DD")
      endkey: @endDate.format("YYYY-MM-DD")
      include_docs: true
    .catch (error) -> console.error error
    .then (result) => 
      summaryData = []
      for row in result.rows
        @summaryCaseDataById[row.id.replace(/case_summary_/, "")] = row.doc
        summaryData.push row.doc
      Promise.resolve summaryData

    aggregatedCases = @aggregatedCases(summaryCaseData, aggregationArea)
    casesAggregatedByDistrict = @aggregatedCases(summaryCaseData, "District")

    @summaryDataByDistrict(casesAggregatedByDistrict)

    previousSummaryCases = await Coconut.reportingDatabase.query "caseIDsByDate",
      startkey: moment(@startDate).subtract(7,"days").format("YYYY-MM-DD")
      endkey: moment(@endDate).subtract(7,"days").format("YYYY-MM-DD")
      include_docs: true
    .catch (error) -> console.error error
    .then (result) => 
      summaryData = []
      for row in result.rows
        @summaryCaseDataById[row.id.replace(/case_summary_/,"")] = row.doc
        summaryData.push row.doc
      Promise.resolve summaryData

    previousAggregatedCases = @aggregatedCases(previousSummaryCases, aggregationArea)

    extractData = (report) ->
      values = _(report.data).values()
      if values.length > 1
        console.error report
        throw "Aggregation error ^^"
      values[0]

    aggregatedWeeklyFacilityReport = extractData(aggregatedWeeklyFacilityReport)
    previousAggregatedWeeklyFacilityReport = extractData(previousAggregatedWeeklyFacilityReport)

    data = []

    columnNames = null

    for area in GeoHierarchy.findAllForLevel(aggregationArea).concat({name:"UNKNOWN"})
      area = area.name
      # All Facilities for the current area
      numberOfFacilitiesByAggregationArea = GeoHierarchy.findAllDescendantsAtLevel(area, aggregationArea, "FACILITY")?.length or 0

      row = 
        "#{aggregationArea}": area
        "Reporting Rate Previous Week": (previousAggregatedWeeklyFacilityReport?[area]?["Reports submitted for period"] or 0)/numberOfFacilitiesByAggregationArea
        "Reporting Rate": (aggregatedWeeklyFacilityReport?[area]?["Reports submitted for period"] or 0)/numberOfFacilitiesByAggregationArea
        "Cases Notified Previous Week": previousAggregatedCases[area]["Cases Notified"]
        "Cases Notified": aggregatedCases[area]["Cases Notified"]
        "Positive Individuals": aggregatedCases[area]["Positive Individuals"]
        "Positive Individuals Classified Indigenous": 
          cases: aggregatedCases[area]["Positive Individuals Classified Indigenous"]
          denominator: aggregatedCases[area]["Positive Individuals"].length
        "Positive Individuals Classified Imported": 
          cases: aggregatedCases[area]["Positive Individuals Classified Imported"]
          denominator: aggregatedCases[area]["Positive Individuals"].length
      columnNames or= _(row).keys()
      unless area is "UNKNOWN" and previousAggregatedCases[area]["Cases Notified"]?.length is 0 and aggregatedCases[area]["Cases Notified"]?.length is 0 and aggregatedCases[area]["Positive Individuals"]?.length is 0
        data.push row

    columns = for row in columnNames
      column = 
        field: row
        formatter: @tableCellFormatter

      column.title = switch row
        when "Positive Individuals"
          "Positive Individuals Including Household Members"
        when "Reporting Rate"
          "Reporting Rate Week #{@selectedWeek}"
        when "Reporting Rate Previous Week"
          "Reporting Rate Week #{@selectedWeek-1}"
        when "Cases Notified"
          "Cases Notified Week #{@selectedWeek}"
        when "Cases Notified Previous Week"
          "Cases Notified Week #{@selectedWeek-1}"
        else
          row

      column.title = column.title.replace(/\s/g,"<br/>") # Make multi line headers so table is compact
      column


    summaryTableId = "summaryTable-#{@startDate.format('YYYY-MM-DD')}_#{@endDate.format('YYYY-MM-DD')}"

    @$("#zoneSummary").append "
      <button data-target-tabulator='#{summaryTableId}' class='downloadCSV'>Download CSV</button>
      <div id='#{summaryTableId}'/>
    "

    @tabulators[summaryTableId] = new Tabulator "##{summaryTableId}",
      data: data
      columns: columns

    Promise.resolve()

  summaryDataByDistrict: (casesAggregatedByDistrict) =>
    columnNames = [
      "Zone"
      "District"
      "Cases Notified"
      "Cases Investigated"
      "Positive Individuals Imported"
      "Positive Individuals Indigenous"
    ]


    console.log casesAggregatedByDistrict
    
    data = for district, data of casesAggregatedByDistrict
      continue if district is "UNKNOWN" and data["Cases Notified"]?.length is 0
      {
        Zone: GeoHierarchy.getZoneForDistrict(district) or "UNKNOWN"
        District: district
        "Cases Notified": data["Cases Notified"]
        "Cases Investigated": data["Cases Investigated"]
        "Positive Individuals": data["Positive Individuals"]
        "Positive Individuals Imported": 
          cases: data["Positive Individuals Classified Imported"]
          denominator: data["Positive Individuals"].length
        "Positive Individuals Indigenous":
          cases: data["Positive Individuals Classified Indigenous"]
          denominator: data["Positive Individuals"].length
      }

    columnNames = _(data[0]).keys()

    columns = for name in columnNames
      field: name
      title: name.replace(/\s/g,"<br/>")
      formatter: @tableCellFormatter

    summaryTableByDistrictId = "summaryTableByDistrict-#{@startDate.format('YYYY-MM-DD')}_#{@endDate.format('YYYY-MM-DD')}"

    @$("#districtSummary").append "
      <button data-target-tabulator='#{summaryTableByDistrictId}' class='downloadCSV'>Download CSV</button>
      <div id='#{summaryTableByDistrictId}'/>
    "

    @tabulators[summaryTableByDistrictId] = new Tabulator "##{summaryTableByDistrictId}",
      data: data
      columns: columns
      initialSort: [
        {column: "Zone", dir: "desc"}
        {column: "District", dir: "desc"}
      ]


  tableCellFormatter: (cell, formatterParams, onRendered) =>
    value = cell.getValue()
    columnField = cell._cell.column.field
    if _(value).isString()
      value
    else if _(value).isNumber()
      if isNaN(value)
        return "N/A"
      else
        percentValue = Math.round(value*100)
        cell._cell.element.style.background = "linear-gradient(-90deg, lightpink #{percentValue}%, white 0%)"
        return "#{percentValue}%"
    else if value.cases? and value.denominator?
      percentValue = (value.cases.length/value.denominator*100 or 0).toFixed()
      cell._cell.element.style.background = "linear-gradient(-90deg, lightpink #{percentValue}%, white 0%)"
      "<button class='cases' data-column='#{columnField}' data-cases='#{value.cases.join(',')}'>#{value.cases.length}</button> (#{percentValue}%)"
    else
      "<button class='cases' data-column='#{columnField}' data-cases='#{value?.join(',')}'>#{value?.length}</button>"


  aggregatedCases: (summaryCaseData, aggregationArea) =>
    aggregatedCases = {}

    for area in GeoHierarchy.findAllForLevel(aggregationArea).concat({name:"UNKNOWN"})
      aggregatedCases[area.name] =
        "Cases Notified": []
        "Cases Investigated": []
        "Positive Individuals": []
        "Positive Individuals Classified Indigenous": []
        "Positive Individuals Classified Imported": []

    for summaryCase in summaryCaseData
      caseAggregationArea = switch aggregationArea
        when "Zone"
          district = summaryCase["District"]
          if district
            GeoHierarchy.getZoneForDistrict(district)
          else
            "UNKNOWN"
        when "District"
          summaryCase["District"] or "UNKNOWN"
        when "Facility"
          summaryCase.Facility or "UNKNOWN"
      id = summaryCase["Malaria Case ID"]
      aggregatedCases[caseAggregationArea]["Cases Notified"].push id
      aggregatedCases[caseAggregationArea]["Cases Investigated"].push id if summaryCase["Complete Household Visit"]
      for typeAndClassification in summaryCase["Classifications By Household Member Type"] .split(", ")
        [householdMemberType, classification] = typeAndClassification.split(": ")
        aggregatedCases[caseAggregationArea]["Positive Individuals"].push id
        aggregatedCases[caseAggregationArea]["Positive Individuals Classified Indigenous"].push id if classification is "Indigenous"
        aggregatedCases[caseAggregationArea]["Positive Individuals Classified Imported"].push id if classification is "Imported"

    return aggregatedCases

  malariaTrends: =>
    startLastYearYearWeek = @startDate.clone().subtract(1,'year').format('YYYY')+"-01"
    endDateYearWeek = @endDate.clone().endOf("year").format('YYYY')+"-52"

    lastYear = startLastYearYearWeek[0..3]
    currentYear = endDateYearWeek[0..3]
    currentWeek = @endDate.format("WW")

    datasets = {}
    classificationDatasets = {}

    caseCountUntilCurrentWeekLastYear = {}
    caseCountUntilCurrentWeekCurrentYear = {}

    for zone in GeoHierarchy.allZones()
      @$("#charts").append "
        <div class='pdf-page'>
          <hr/>
          <h2>
            Malaria yearly trends by week in #{zone} (#{lastYear}/#{currentYear})<br/>
            <small id='case-count-#{zone}'></small>
          </h2>
          <canvas style='height:300px;width:400px;' id='yearlyTrends-#{zone}'/>
        </div>
        <div class='pdf-page'>
          <hr/>

          <h2>
            Case Classification in #{zone} for  #{currentYear}<br/>
          </h2>
          <canvas style='height:300px;width:400px;' id='caseClassification-#{zone}'/>
        </div>
      "
      caseCountUntilCurrentWeekLastYear[zone] = 0
      caseCountUntilCurrentWeekCurrentYear[zone] = 0
      datasets[zone] = [
        {
          label: "Cases Notified #{lastYear}"
          data: []
          backgroundColor: "blue"
        }
        {
          label: "Cases Notified #{currentYear}"
          data: []
          backgroundColor: "orange"
        }
        {
          label: "Cases Investigated #{currentYear}"
          data: []
          backgroundColor: "gray"
        }
      ]

      classificationDatasets[zone] = for classification, configuration of @classifications
        {
          label: classification
          sparseData: {}
          backgroundColor: configuration.color
        }
      console.log classificationDatasets

    Coconut.reportingDatabase.query "summaryCaseAggregatorWeekly",
      startkey: [startLastYearYearWeek]
      endkey: [endDateYearWeek]
      reduce: true
      group: true
      include_docs: false
    .then (result) =>

      for row in result.rows
        [yearWeek, zone, indicator] = row.key
        amount = row.value
        year = yearWeek[0..3] # "2012-12"  -> 2012
        week = parseInt(yearWeek[-2..])

        if zone is null or zone is ""
          console.warn "null zone for:"
          console.warn row
          continue

        if year is lastYear and indicator is "Has Case Notification"
          datasets[zone][0].data.push {x:week, y:amount}
          console.log parseInt(currentWeek)
          caseCountUntilCurrentWeekLastYear[zone] += amount if week <= parseInt(currentWeek)
        if year is currentYear and indicator is "Has Case Notification"
          datasets[zone][1].data.push {x:week, y:amount}
          caseCountUntilCurrentWeekCurrentYear[zone] += amount
        if year is currentYear and indicator is "Complete Household Visit"
          datasets[zone][2].data.push {x:week, y:amount}

        index = 0
        for classification of @classifications
          if year is currentYear and indicator is "Classification: #{classification}"
            console.log zone
            console.log classificationDatasets
            classificationDatasets[zone][index].sparseData[week] = amount
          index+=1

        ###
        if year is currentYear and indicator is "Classification: Indigenous"
          classificationDatasets[zone][0].sparseData[week] = amount
        if year is currentYear and indicator is "Classification: Imported"
          classificationDatasets[zone][1].sparseData[week] = amount
        ###

      for zone in GeoHierarchy.allZones()
        @$("#case-count-#{zone}").html("#{caseCountUntilCurrentWeekCurrentYear[zone]} total cases notified this year compared with #{caseCountUntilCurrentWeekLastYear[zone]} by this time the previous year.")

        new Chart @$("#yearlyTrends-#{zone}"),
          type: "bar"
          data:
            labels: [1..52]
            datasets: datasets[zone]


        # Can't use sparse data, every x point needs data
        classificationLabels = [1..moment().isoWeek()]
        for dataset in classificationDatasets[zone]
          dataset.data = for label in classificationLabels
            dataset.sparseData[label] or 0

        new Chart @$("#caseClassification-#{zone}"),
          type: "bar"
          data:
            labels: [1..moment().isoWeek()]
            datasets: classificationDatasets[zone]
          options: 
            scales:
              xAxes:[stacked:true]
              yAxes:[stacked:true]

    #.catch (error) ->
    #  console.error error
    #  $('#analysis-spinner').hide()


    #casesNotifiedYearToDateByWeek
    #casesNotifiedLastYearByWeek
    #casesInvestigatedYearToDateByWeek

module.exports = WeeklyMeetingReportView
