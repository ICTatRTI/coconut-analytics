_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

DataTables = require( 'datatables.net' )()
Reports = require '../models/Reports'
#FacilityHierarchy = require '../models/FacilityHierarchy'
#
Tabulator = require 'tabulator-tables'

class CompareWeeklyView extends Backbone.View
  el: "#content"

  events:
    "change select.aggregatedBy": "updateAggregatedBy"
    "click #toggleDetails": "toggleDetails"
    "click #downloadCsv": "downloadCsv"

  toggleDetails: =>
    @showDetails = if @showDetails then false else true
    @renderTabulator()

  getColumns: =>

    columnNames = [
      "#{@aggregationPeriod}"
      "Zone"
    ]

    if @aggregationArea is "District" or @aggregationArea is "Facility"
      columnNames.push "District"
    if @aggregationArea is "Facility"
      columnNames.push "Facility"
    columnNames = columnNames.concat [
      "Weekly Facility Report # Positive"
      "Notified"
      "Weekly vs Notified Difference"
    ]

    @showDetails or= false

    if @showDetails
      columnNames = columnNames.concat [
        "Weekly Facility Reports Expected (assumes months expect 4 reports, not always true)"
        "Number submitted"
        "Reports submitted within 1 day of period end (Monday)"
        "Reports submitted within 1-3 days of period end (by Wednesday)"
        "Reports submitted within 3-5 days of period end (by Friday)"
        "Reports submitted 5 or more days after period end"
        "Total Tested"
        "Facility Followed-Up Positive Cases"
        "Cases Followed-Up within 48 Hours"
      ]


    columns = for name in columnNames
      columnDetails = {
        title: name
        field: name
        headerFilter: "input"
      }
      if name.match(/Facility/)
        columnDetails.width = 150
      columnDetails

    return columns


  renderTabulator: =>
    @getColumns() unless @columns?

    @tabulator = new Tabulator "#tabulator",
      height: 500
      columns: @getColumns()
      data: await @getTabulatorData()
      initialSort: [
        {
          column:"Weekly vs Notified Difference"
          dir: "desc"
        }
      ]

    @$("#messages").html "
      Total Number Positive From Facility Weekly Report: <span id='aggregatedTotalPositiveFromFacilityWeeklyReport'>
        <b>
        #{
          @aggregatedTotalPositiveFromFacilityWeeklyReport
        }
        </b>
      </span><br/>
      Total Number Cases Notified: <span id='aggregatedNumberCasesNotified'>
        <b>
        #{
          @aggregatedNumberCasesNotified
        }
        </b>
      </span>
      <br/>
      <br/>
      <div id='errors'>
        Errors: (Admins can add aliases to fix wrongly named facilities)<br/>
        #{
          message = ""
          for errorType, errors of @weeklyReports.errors
            for name, data of errors
              message += "
                #{errorType} #{name} [District-#{data.District}, Facility-#{data.Facility}]
                <div style='display:none'>
                  #{JSON.stringify(data)}
                </div>
                <br/>
              "
          message
        }
      </div>
    "
    $('#analysis-spinner').hide()

  downloadCsv: =>
    @tabulator.download "csv", "CompareWeekly.csv"

  updateAggregatedBy: (e) =>
    Coconut.router.reportViewOptions['aggregationPeriod'] = $("#aggregationPeriod").val()
    Coconut.router.reportViewOptions['aggregationArea'] = $("#aggregationArea").val()
    #Coconut.router.reportViewOptions['facilityType'] = $("#facilityType").val()
    @render()
    Coconut.dateSelectorView.setElement "#dateSelector"
    Coconut.dateSelectorView.render()

  getTabulatorData: =>
    startYearWeek = moment(@options.startDate).format("GGGG-WW")
    endYearWeek = moment(@options.endDate).format("GGGG-WW")

    @$("#messages").html "Getting Weekly Data..."
      

    @weeklyReports = await Reports.aggregateWeeklyReports
      startDate: @options.startDate
      endDate: @options.endDate
      aggregationArea: @aggregationArea
      aggregationPeriod: @aggregationPeriod
      facilityType: @facilityType
    .catch (error) => console.error error

    @$("#messages").html "Getting Weekly Data...Done!<br/>Getting Notification Data..."
    @indexCasesByAggregationArea = await Coconut.reportingDatabase.query "indexCasesByDateAndAdminLevels",
      startkey: [startYearWeek]
      endkey: [endYearWeek,{}]
      reduce: true
      group_level: switch @aggregationArea
        when "Zone" then 2
        when "District" then 4
        when "Facility" then 6
    .then (result) =>
      data = {}
      total = 0
      for row in result.rows
        yearWeek = row.key[0]
        aggregationArea = row.key.pop()
        amount = row.value
        period = switch @aggregationPeriod
          when "Year" then moment(yearWeek, "GGGG-WW").format("YYYY")
          when "Month" then moment(yearWeek, "GGGG-WW").format("YYYY-MM")
          when "Week" then yearWeek
        data[period] or= {}
        data[period][aggregationArea] or= 0
        data[period][aggregationArea] += amount
      console.log total
      Promise.resolve(data)


    console.log @indexCasesByAggregationArea

    @$("#messages").html "Getting Weekly Data...Done!<br/>Getting Notification Data...Done!<br/>"

    @aggregatedTotalPositiveFromFacilityWeeklyReport = 0
    @aggregatedNumberCasesNotified = 0

    combinedData = @weeklyReports.data
    for period, areaAmount of @indexCasesByAggregationArea
      for area, amount of areaAmount
        combinedData[period] or= {}
        combinedData[period][area] or= {}
        combinedData[period][area]["Notified Cases"] = amount

    #console.log combinedData

    tabulatorData = []
    for aggregationPeriod, aggregationAreaAndData of combinedData
      for aggregationArea, data of aggregationAreaAndData
        tabulatorRow = {}

        if aggregationArea is "Unknown"
          console.error "Unknown aggregationArea: #{data}"
        tabulatorRow[@aggregationPeriod] = aggregationPeriod
        tabulatorRow[@aggregationArea] = aggregationArea

        if @aggregationArea is "Facility"
          tabulatorRow["Zone"] = FacilityHierarchy.getZone(aggregationArea) or data["Zone"]
          tabulatorRow["District"] = FacilityHierarchy.getDistrict(aggregationArea) or data["District"]
        else if @aggregationArea is "District"
          tabulatorRow["Zone"] = GeoHierarchy.getZoneForDistrict(aggregationArea) or data["Zone"]

        numberOfFaciltiesMultiplier = if @aggregationArea is "Zone"
          GeoHierarchy.facilitiesForZone(aggregationArea).length
        else if @aggregationArea is "District"
          GeoHierarchy.facilitiesForDistrict(aggregationArea).length
        else
          1

        expectedNumberOfReports = switch @aggregationPeriod
          when "Year" then 52
          when "Month" then "4"
          when "Quarter" then "13"
          when "Week" then "1"
        tabulatorRow["Weekly Facility Reports Expected (assumes months expect 4 reports, not always true)"] = expectedNumberOfReports * numberOfFaciltiesMultiplier

        tabulatorRow["Number submitted"] = numberReportsSubmitted = data["Reports submitted for period"] or '-'
        tabulatorRow["Reports submitted within 1 day of period end (Monday)"] = data["Report submitted within 1 day"] or '-'
        tabulatorRow["Reports submitted within 1-3 days of period end (by Wednesday)"] = data["Report submitted within 1-3 days"] or '-'
        tabulatorRow["Reports submitted within 3-5 days of period end (by Friday)"] = data["Report submitted within 3-5 days"] or '-'
        tabulatorRow["Reports submitted 5 or more days after period end"] = data["Report submitted 5+ days"] or '-'

        totalTested = data["Mal POS < 5"]+data["Mal POS >= 5"]+data["Mal NEG < 5"]+data["Mal NEG >= 5"]
        tabulatorRow["Total Tested"] = totalTested

        totalPositive = (parseInt(data["Mal POS < 5"]) or 0) + (parseInt(data["Mal POS >= 5"]) or 0)
        tabulatorRow["Weekly Facility Report # Positive"] = totalPositive or '-'
      
        @aggregatedTotalPositiveFromFacilityWeeklyReport += totalPositive

        tabulatorRow["Notified"] = data["Notified Cases"] or '-'

        @aggregatedNumberCasesNotified += parseInt(tabulatorRow["Notified"]) or 0
        tabulatorRow["Facility Followed-Up Positive Cases"] = data.hasCompleteFacility?.length or '-'
        tabulatorRow["Cases Followed-Up within 48 Hours"] = data.followedUpWithin48Hours?.length or '-'

        tabulatorRow["Weekly vs Notified Difference"] = Math.abs((parseInt(tabulatorRow["Weekly Facility Report # Positive"]) or 0) - (parseInt(tabulatorRow["Notified"]) or 0)) or '-'

        tabulatorData.push tabulatorRow

    console.log tabulatorData
    return tabulatorData

  render: =>
    @options = $.extend({},Coconut.router.reportViewOptions)
    @aggregationPeriod = @options.aggregationPeriod or "Week"
    @aggregationArea = @options.aggregationArea or "Facility"
    @facilityType = @options.facilityType or "All"
    HTMLHelpers.ChangeTitle("Reports: Compare Weekly Facility Reports With Case Follow-ups")
    @$el.html "
        <style>
          td.number{
            text-align: center;
            vertical-align: middle;
          }
          table.tablesorter tbody td.mismatch, button.mismatch, span.mismatch{
            color:#FF4081
          }
          table#facilityTimeliness th {
            padding: 0 4px 12px 4px;
            font-size: 9pt;
          }
          .details{
            display:none;
          }
        </style>
        <div id='dateSelector'></div>
        <h5>Compare Weekly Reports and Coconut cases aggregated by
        <select id='aggregationPeriod' class='aggregatedBy'>
          #{
            _("Year,Month,Week".split(",")).map (aggregationPeriod) =>
            #_("Year,Quarter,Month,Week".split(",")).map (aggregationPeriod) =>
              "
                <option #{if aggregationPeriod is @aggregationPeriod then "selected='true'" else ''}>
                  #{aggregationPeriod}
                </option>"
            .join ""
          }
        </select>
        and
        <select id='aggregationArea' class='aggregatedBy'>
          #{
            _("Zone,District,Facility".split(",")).map (aggregationArea) =>
              "
                <option #{if aggregationArea is @aggregationArea then "selected='true'" else ''}>
                  #{aggregationArea}
                </option>"
            .join ""
          }
        </select>

        <!--

        for <select id='facilityType' class='aggregatedBy'>
          #{
            _("All,Private,Public".split(",")).map (facilityType) =>
              "
                <option #{if facilityType is @facilityType then "selected='true'" else ''}>
                  #{facilityType}
                </option>"
            .join ""
          }
        </select>
        facilities.
        -->
        </h5>
        <div>
          This report compares the number of weekly positive malaria cases that are counted and submitted by facilities on a weekly basis with the number of individual cases that facilities report immediately after finding a positive case. Ideally these numbers should always be the same. If they are different, then the discrepancy should be resolved with the health facility. The initial sort is based on the difference column. The weekly data submitted by facilities can be analysed <a href='#reports/type/WeeklyFacilityReports'>here</a>.
        </div>

        <button id='downloadCsv'>Download CSV</button>
        <button id='toggleDetails'>Toggle Details</button>
        <br/><br/>

        <div id='tabulator'></div>
        <div id='messages'>
        </div>
    "
    $('#analysis-spinner').show()

    @renderTabulator()
module.exports = CompareWeeklyView
