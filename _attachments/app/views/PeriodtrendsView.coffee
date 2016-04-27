_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
PouchDB = require 'pouchdb'
moment = require 'moment'
require 'moment-range'

DataTables = require 'datatables'
Reports = require '../models/Reports'

class PeriodtrendsView extends Backbone.View
  el: "#content"

  events:
    "click button.toggle-trend-data": "toggleTrendData"
    "click .toggleDisaggregation": "toggleDisaggregation"
    "click .same-cell-disaggregatable": "toggleDisaggregationSameCell"

  toggleTrendData: (e) ->
    if $(".toggle-trend-data").html() is "Show trend data"
      $(".data").show()
      $(".toggle-trend-data").html "Hide trend data"
    else
      $(".data").hide()
      $(".period-0.data").show()
      $(".toggle-trend-data").html "Show trend data"

  toggleDisaggregation: (event) ->
    $(event.target).parents("td").siblings(".cases").toggle()

  toggleDisaggregationSameCell: (event) ->
    $(event.target).siblings(".cases").toggle()

  render: =>
    @reportOptions = Coconut.router.reportViewOptions
    district = @reportOptions.district || "ALL"

    @reportOptions.startDate = @reportOptions.startDate || moment(new Date).subtract(7,'days').format("YYYY-MM-DD")
    @reportOptions.endDate = @reportOptions.endDate || moment(new Date).format("YYYY-MM-DD")

    $('#analysis-spinner').show()

    @$el.html "
        <div id='dateSelector'></div>
        <div id='messages'></div>
    "

    Coconut.database.query "zanzibar/byCollection",
      # Note that these seem reversed due to descending order
      key: "help"
      include_docs: true
    .catch (error) ->
      console.log error
    .then (result) =>
      messages = _(result.rows).chain().map( (data) =>
        return unless moment(@reportOptions.startDate).isBefore(data.value.date) and moment(@reportOptions.endDate).isAfter(data.value.date)
        "#{data.value.date}: #{data.value.text}<br/>"
      ).compact().value().join("")
      if messages isnt "" then $("#messages").html "
        <h2>Help Messages</h2>
        #{messages}
      "

    if @reportOptions.optionsArray
      optionsArray = options.optionsArray
    else
      amountOfTime = moment(@reportOptions.endDate).diff(moment(@reportOptions.startDate))

      previousOptions = _.clone @reportOptions
      previousOptions.startDate = moment(@reportOptions.startDate).subtract(amountOfTime,"milliseconds").format(Coconut.config.dateFormat)
      previousOptions.endDate = @reportOptions.startDate

      previousPreviousOptions= _.clone @reportOptions
      previousPreviousOptions.startDate = moment(previousOptions.startDate).subtract(amountOfTime, "milliseconds").format(Coconut.config.dateFormat)
      previousPreviousOptions.endDate = previousOptions.startDate

      previousPreviousPreviousOptions= _.clone @reportOptions
      previousPreviousPreviousOptions.startDate = moment(previousPreviousOptions.startDate).subtract(amountOfTime, "milliseconds").format(Coconut.config.dateFormat)
      previousPreviousPreviousOptions.endDate = previousPreviousOptions.startDate
      optionsArray = [previousPreviousPreviousOptions, previousPreviousOptions, previousOptions, @reportOptions]

    results = []

    dataValue = (data) =>
      if data.disaggregated?
        data.disaggregated.length
      else if data.percent?
        Reports.formattedPercent(data.percent)
      else if data.text?
        data.text

    renderDataElement = (data) =>
      if data.disaggregated?
        output = Reports.createDisaggregatableCaseGroup(data.disaggregated)
        if data.appendPercent?
          output += " (#{Reports.formattedPercent(data.appendPercent)})"
        output
      else if data.percent?
        Reports.formattedPercent(data.percent)
      else if data.text?
        data.text

    renderTable = _.after optionsArray.length, =>
      $("#analysis-spinner").hide()
      $("#content").append "
        <h3>Data Summary</h3>
        <table id='alertsTable' class='tablesorter'>
          <tbody>
            #{
              index = 0
              _(results[0]).map( (firstResult) =>
                "
                <tr class='#{if index%2 is 0 then "odd" else "even"}'>
                  <td>#{firstResult.title}</td>
                  #{
                    period = results.length
                    sum = 0
                    dataPoints = 0
                    element = _.map results, (result) ->
                      # dont include the final period in average
                      unless (dataPoints+1) is results.length 
                        dataPoints += 1
                        sum += parseInt(dataValue(result[index]))
                      "
                        <td class='period-#{period-=1} trend'></td>
                        <td class='period-#{period} data'>#{renderDataElement(result[index])}</td>
                        #{
                          if period is 0
                            "<td class='average-for-previous-periods'>#{Math.round(sum/dataPoints)}</td>"
                          else  ""
                        }
                      "
                    .join("")
                    index+=1
                    element
                  }
                </tr>
                "
              ).join("")
            }
          </tbody>
        </table> 
        <button class='toggle-trend-data mdl-button mdl-js-button mdl-button--raised mdl-button--colored'>Show trend data</button>
      "

      extractNumber = (element) ->
        result = parseInt(element.text())
        if isNaN(result)
          parseInt(element.find("button").text())
        else
          result

      # Analyze the trends
      _(results.length-1).times (period) ->
        _.each $(".period-#{period}.data"), (dataElement) ->
          dataElement = $(dataElement)
          current = extractNumber(dataElement)
          previous = extractNumber(dataElement.prev().prev())
          dataElement.prev().html if current is previous then "-" else if current > previous then "<span class='up-arrow'><i class='material-icons'>arrow_upward</i></span>" else "<span class='down-arrow'><i class='material-icons'>arrow_downward</i></span>"
          
      _.each $(".period-0.trend"), (period0Trend) ->
        period0Trend = $(period0Trend)
        if period0Trend.prev().prev().find("span").attr("class") is period0Trend.find("span").attr("class")
          period0Trend.find("span").attr "style", "color:red"

      #
      #Clean up the table
      # 
      $(".period-0.data").show()
      $(".period-#{results.length-1}.trend").hide()
      $(".period-1.trend").attr "style", "font-size:75%"
      $(".trend")
      $("td:contains(Period)").siblings(".trend").find("i").hide()
      $(".period-0.data").show()
      $($(".average-for-previous-periods")[0]).html "Average for previous #{results.length-1} periods"

      swapColumns =  (table, colIndex1, colIndex2) ->
        if !colIndex1 < colIndex2
          t = colIndex1
          colIndex1 = colIndex2
          colIndex2 = t
        
        if table && table.rows && table.insertBefore && colIndex1 != colIndex2
          for row in table.rows
            cell1 = row.cells[colIndex1]
            cell2 = row.cells[colIndex2]
            siblingCell1 = row.cells[Number(colIndex1) + 1]
            row.insertBefore(cell1, cell2)
            row.insertBefore(cell2, siblingCell1)

      swapColumns($("#alertsTable")[0], 8, 9)

      #
      #End of clean up the table
      # 


    reportIndex = 0
    _.each optionsArray, (options) =>
      # This is an ugly hack to use local scope to ensure the result order is correct
      anotherIndex = reportIndex
      reportIndex++

      #reports = new Reports()
      Reports.casesAggregatedForAnalysis
        aggregationLevel: "District"
        startDate: options.startDate
        endDate: options.endDate
        mostSpecificLocation: Reports.mostSpecificLocationSelected()
        success: (data) =>
          anyTravelOutsideZanzibar = _.union(data.travel[district]["Yes outside Zanzibar"], data.travel[district]["Yes within and outside Zanzibar"])

          results[anotherIndex] = [
            title         : "Period"
            text          :  "#{moment(options.startDate).format("YYYY-MM-DD")} -> #{moment(options.endDate).format("YYYY-MM-DD")}"
          ,
            title         : "<b>No. of cases reported at health facilities<b/>"
            disaggregated : data.followups[district].allCases
          ,
            title         : "No. of cases reported at health facilities with <b>complete household visits</b>"
            disaggregated : data.followups[district].casesWithCompleteHouseholdVisit
            appendPercent : data.followups[district].casesWithCompleteHouseholdVisit.length/data.followups[district].allCases.length
          ,
            title         : "Total No. of cases (including cases not reported by facilities) with complete household visits"
            disaggregated : data.followups[district].casesWithCompleteHouseholdVisit
          ,
            title         : "No. of additional <b>household members tested<b/>"
            disaggregated : data.passiveCases[district].indexCaseHouseholdMembers
          ,
            title         : "No. of additional <b>household members tested positive</b>"
            disaggregated : data.passiveCases[district].positiveCasesAtIndexHousehold
            appendPercent : data.passiveCases[district].positiveCasesAtIndexHousehold.length / data.passiveCases[district].indexCaseHouseholdMembers.length
          ,
            title         : "% <b>increase in cases found</b> using MCN"
            percent       : data.passiveCases[district].positiveCasesAtIndexHousehold.length / data.passiveCases[district].indexCases.length
          ,
            title         : "No. of positive cases (index & household) in persons <b>under 5</b>"
            disaggregated : data.ages[district].underFive
            appendPercent : data.ages[district].underFive.length / data.totalPositiveCases[district].length
          ,
            title         : "Positive Cases (index & household) with at least a <b>facility followup</b>"
            disaggregated : data.totalPositiveCases[district]
          ,
            title         : "Positive Cases (index & household) that <b>slept under a net</b> night before diagnosis"
            disaggregated : data.netsAndIRS[district].sleptUnderNet
            appendPercent : data.netsAndIRS[district].sleptUnderNet.length / data.totalPositiveCases[district].length
          ,
            title         : "Positive Cases from a household that <b>has been sprayed</b> within last #{Coconut.IRSThresholdInMonths} months"
            disaggregated : data.netsAndIRS[district].recentIRS
            appendPercent : data.netsAndIRS[district].recentIRS.length / data.totalPositiveCases[district].length
          ,
            title         : "Positive Cases (index & household) that <b>did not travel</b>"
            disaggregated : data.travel[district]["No"]
            appendPercent : data.travel[district]["No"].length / data.totalPositiveCases[district].length
          ,
            title         : "Positive Cases (index & household) that <b>traveled but only within Zanzibar<b/> last month"
            disaggregated : data.travel[district]["Yes within Zanzibar"]
            appendPercent : data.travel[district]["Yes within Zanzibar"].length / data.totalPositiveCases[district].length
          ,
            title         : "Positive Cases (index & household) that <b>traveled outside Zanzibar </b>last month"
            disaggregated : anyTravelOutsideZanzibar
            appendPercent : anyTravelOutsideZanzibar.length / data.totalPositiveCases[district].length
          ]
          renderTable()
		  
module.exports = PeriodtrendsView
