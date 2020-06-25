_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

DataTables = require( 'datatables.net' )()
Reports = require '../models/Reports'
#FacilityHierarchy = require '../models/FacilityHierarchy'

class CompareWeeklyView extends Backbone.View
  el: "#content"

  events:
    "click #csv": "toggleCSVMode"
    "change select.aggregatedBy": "updateAggregatedBy"
    "click #toggleDetails": "toggleDetails"

  toggleDetails: =>
    console.log "ZZ"
    @$(".details").toggle()

  updateAggregatedBy: (e) =>
    Coconut.router.reportViewOptions['aggregationPeriod'] = $("#aggregationPeriod").val()
    Coconut.router.reportViewOptions['aggregationArea'] = $("#aggregationArea").val()
    Coconut.router.reportViewOptions['facilityType'] = $("#facilityType").val()
    @render()
    Coconut.dateSelectorView.setElement "#dateSelector"
    Coconut.dateSelectorView.render()

  toggleCSVMode: () =>
    @csvMode = !@csvMode
    $('button#csv').text(if @csvMode then 'Table Mode' else 'CSV Mode')

    if @csvMode
      $('table#facilityTimeliness').css("display","none")
    else
      $('table#facilityTimeliness').css("display","block")
    @renderFacilityTimeliness()

  renderFacilityTimeliness: =>
    $('#analysis-spinner').show()
    $('table#facilityTimeliness tbody').html "
      #{
        quartilesAndMedian = (values)->
          [median,h1Values,h2Values] = getMedianWithHalves(values)
          [
            getMedian(h1Values)
            median
            getMedian(h2Values)
          ]

        getMedianWithHalves = (values) ->

          return [ values[0], [values[0]], [values[0]] ] if values.length is 1

          values.sort  (a,b)=> return a - b
          half = Math.floor values.length/2
          if values.length % 2 #odd
            median = values[half]
            return [median,values[0..half],values[half...]]
          else # even
            median = (values[half-1] + values[half]) / 2.0
            return [median, values[0..half],values[half+1...]]


        getMedian = (values)->
          getMedianWithHalves(values)[0]

        getMedianOrEmptyFormatted = (values)->
          return "-" unless values?
          Math.round(getMedian(values)*10)/10

        getMedianAndQuartilesElement = (values)->
          return "-" unless values?
          [q1,median,q3] = _(quartilesAndMedian(values)).map (value) ->
            Math.round(value*10)/10
          "#{median} (#{q1}-#{q3})"

        getNumberAndPercent = (numerator,denominator) ->
          return "-" unless numerator? and denominator?
          "#{numerator} (#{Math.round(numerator/denominator*100)}%)"

        allPrivateFacilities = FacilityHierarchy.allPrivateFacilities()

        _(@results.data).map (aggregationAreas, aggregationPeriod) =>
          _(aggregationAreas).map (data,aggregationArea) =>

            # TODO fix this - we shouldn't skip unknowns
            return if aggregationArea is "Unknown"
            "
              <tr>
                <td>#{aggregationPeriod}</td>
                #{
                  if @aggregationArea is "Facility"
                    "
                    <td>#{FacilityHierarchy.getZone(aggregationArea)}</td>
                    <td>#{FacilityHierarchy.getDistrict(aggregationArea)}</td>
                    "
                  else if @aggregationArea is "District"
                    "
                    <td>#{GeoHierarchy.getZoneForDistrict(aggregationArea)}</td>
                    "
                  else ""
                }
                <td>
                  #{aggregationArea}
                  #{if @aggregationArea is "Facility" and _(allPrivateFacilities).contains(aggregationArea) then "(private)" else ""}
                </td>
                <td class='details'>
                  #{
                    numberOfFaciltiesMultiplier = if @aggregationArea is "Zone"
                      FacilityHierarchy.facilitiesForZone(aggregationArea).length
                    else if @aggregationArea is "District"
                      FacilityHierarchy.facilitiesForDistrict(aggregationArea).length
                    else
                      1

                    expectedNumberOfReports = switch @aggregationPeriod
                      when "Year" then 52
                      when "Month" then "4"
                      when "Quarter" then "13"
                      when "Week" then "1"
                    expectedNumberOfReports = expectedNumberOfReports * numberOfFaciltiesMultiplier
                  }
                </td>
                <td class='details'>#{numberReportsSubmitted = data["Reports submitted for period"] or 0}</td>
                <td class='details'>
                  #{
                    if Number.isNaN(numberReportsSubmitted) or Number.isNaN(expectedNumberOfReports) or expectedNumberOfReports is 0
                      '-'
                    else
                      Math.round(numberReportsSubmitted/expectedNumberOfReports * 1000)/10 + "%"
                  }
                </td>
                <td class='details'>#{data["Report submitted within 1 day"] or 0}</td>
                <td class='details'>#{data["Report submitted within 1-3 days"] or 0}</td>
                <td class='details'>#{data["Report submitted within 3-5 days"] or 0}</td>
                <td class='details'>#{data["Report submitted 5+ days"] or 0}</td>
                <td class='details'>
                  <!-- Total Tested -->
                  #{
                    totalTested = data["Mal POS < 5"]+data["Mal POS >= 5"]+data["Mal NEG < 5"]+data["Mal NEG >= 5"]
                    if Number.isNaN(totalTested) then '-' else HTMLHelpers.numberWithCommas(totalTested)
                  }

                </td>
                <td class='total-positive'>
                  #{
                    totalPositive = data["Mal POS < 5"]+data["Mal POS >= 5"]
                    if Number.isNaN(totalPositive) then '-' else totalPositive
                  }
                <td class='percent-positive details'>
                  #{
                    if Number.isNaN(totalTested) or Number.isNaN(totalPositive) or totalTested is 0
                      '-'
                    else
                      Math.round(totalPositive/totalTested * 100) + "%"
                  }
                </td>
                #{
                  _(["casesNotified","hasCompleteFacility","followedUpWithin48Hours"]).map (property) =>
                    "
                      <td class='#{property} #{if property is "casesNotified" then "" else "details"}'>
                        #{
                          if @csvMode
                            data[property]?.length or "-"
                          else
                            if data[property] then HTMLHelpers.createDisaggregatableCaseGroup data[property] else '0'
                        }
                      </td>
                    "
                  .join ""
                }

                <td>#{
                  totalPositive = data["Mal POS < 5"]+data["Mal POS >= 5"]
                  totalPositive - data['casesNotified']?.length or '-'
                }
                </td>

                <td class='details'>#{getMedianAndQuartilesElement data["daysBetweenPositiveResultAndNotificationFromFacility"]}</td>
                <td class='details'>#{getMedianAndQuartilesElement data["daysFromCaseNotificationToCompleteFacility"]}</td>
                <td class='details'>
                #{
                  if data["casesNotified"] and data["casesNotified"].length isnt 0 and data["Facility Followed-Up Positive Cases"]
                    Math.round(data["Facility Followed-Up Positive Cases"].length / data["casesNotified"].length * 1000)/10 + "%"
                  else
                    "-"
                }
                </td>
                <td class='details'>#{getMedianAndQuartilesElement data["daysFromSMSToCompleteHousehold"]}</td>
                <td class='details'>
                #{
                  if data["casesNotified"] and data["casesNotified"].length isnt 0 and data["householdFollowedUp"]
                    Math.round(data["householdFollowedUp"] / data["casesNotified"].length * 100) + "%"
                  else
                    "-"
                }
                </td>
              </tr>
            "
          .join("")
        .join("")
      }
    "
    if !( $.fn.dataTable.isDataTable( '#facilityTimeliness' ))
      $("#facilityTimeliness").dataTable
        aaSorting: [[0,"desc"]]
        iDisplayLength: 50
        dom: 'T<"clear">lfrtip'
        scrollX: true
        tableTools:
          sSwfPath: "js-libraries/copy_csv_xls.swf"
          aButtons: [
            "csv",
          ]
        fnDrawCallback: ->
          # Check for mismatched cases
          _($("tr")).each (tr) ->
            totalPositiveElement = $(tr).find("td.total-positive")

            if totalPositiveElement? and totalPositiveElement.text() isnt ""
              totalPositive = totalPositiveElement.text().match(/[0-9|-]+ /)[0]

            casesNotified = $(tr).find("td.casesNotified button.sort-value").text() or 0

            if parseInt(totalPositive) isnt parseInt(casesNotified)
              totalPositiveElement.addClass("mismatch")
              $(tr).find("td.casesNotified button.sort-value").addClass("mismatch")
              $(tr).find("td.casesNotified").addClass("mismatch")

      if @csvMode
        $(".dataTables_filter").hide()
        $(".dataTables_paginate").hide()
        $(".dataTables_length").hide()
        $(".dataTables_info").hide()
      else
        $(".DTTT_container").hide()
    $('#analysis-spinner').hide()

  render: =>
    @options = $.extend({},Coconut.router.reportViewOptions)
    @aggregationPeriod = @options.aggregationPeriod or "Month"
    @aggregationArea = @options.aggregationArea or "Zone"
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
            _("Year,Quarter,Month,Week".split(",")).map (aggregationPeriod) =>
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
        </h5>
        <div>If the total positive cases from the weekly reports don't match the number of cases notified, the <span class='mismatch'>mismatched values are colored</span>.
        <button id='toggleDetails'>Toggle Details</button>
        <button class='mdl-button mdl-js-button mdl-button--raised' id='csv'>#{if @csvMode then "Table Mode" else "CSV Mode"}</button></div>
        <br/><br/>
        <div class='scroll-div'>
          <table class='tablesorter mdl-data-table mdl-js-data-table mdl-shadow--2dp' id='facilityTimeliness' style='#{if @csvMode then "display:none" else ""}'>
            <thead>
              <th>#{@aggregationPeriod}</th>
              <th>Zone</th>
              #{if @aggregationArea is "District" or @aggregationArea is "Facility" then "<th>District</th>" else ""}
              #{if @aggregationArea is "Facility" then "<th>Facility</th>"  else ""}
              <th class='details'>Weekly Facility Reports Expected (assumes months expect 4 reports, not always true)</th>
              <th class='details'># submitted</th>
              <th class='details'>% submitted</th>
              <th class='details'>Reports submitted within 1 day of period end (Monday)</th>
              <th class='details'>Reports submitted within 1-3 days of period end (by Wednesday)</th>
              <th class='details'>Reports submitted within 3-5 days of period end (by Friday)</th>
              <th class='details'>Reports submitted 5 or more days after period end</th>
              <th class='details'>Total Tested</th>
              <th>Total Positive From Facility Weekly Report</th>
              <th class='details'>Percent Positive</th>
              <th>Number of cases notified</th>
              <th class='details'>Facility Followed-Up Positive Cases</th>
              <th class='details'>Cases Followed-Up within 48 Hours</th>
              <th>Difference between weekly reports and notifications</th>
              <th class='details'>Median Days from Positive Test Result to Facility Notification (IQR)</th>
              <th class='details'>Median Days from Facility Notification to Complete Facility (IQR)</th>
              <th class='details'>% of Notified Cases with Complete Facility Follow-up</th>
              <th class='details'>Median Days from Facility Notification to Complete Household (IQR)</th>
              <th class='details'>% of Notified with Complete Followup</th>
            </thead>
            <tbody> </tbody>
          </table>
        </div>
    "
    $('#analysis-spinner').show()

    Reports.aggregateWeeklyReportsAndFacilityTimeliness
      startDate: @options.startDate
      endDate: @options.endDate
      aggregationArea: @aggregationArea
      aggregationPeriod: @aggregationPeriod
      facilityType: @facilityType

      error: (error) ->
        console.error error
      success: (results) =>
        @results = results
        @renderFacilityTimeliness()

module.exports = CompareWeeklyView
