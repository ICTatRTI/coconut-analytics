_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

DataTables = require( 'datatables.net' )()
Reports = require '../models/Reports'
FacilityHierarchy = require '../models/FacilityHierarchy'

class CompareWeeklyView extends Backbone.View
  el: "#content"

  events:
    "click #csv": "toggleCSVMode"
    "change select.aggregatedBy": "updateAggregatedBy"

  updateAggregatedBy: (e) =>
    Coconut.router.reportViewOptions['aggregationPeriod'] = $("#aggregationPeriod").val()
    Coconut.router.reportViewOptions['aggregationArea'] = $("#aggregationArea").val()
    Coconut.router.reportViewOptions['facilityType'] = $("#facilityType").val()
    @render()
    Coconut.dateSelectorView.setElement "#dateSelector"
    Coconut.dateSelectorView.render()
    
  toggleCSVMode: () =>
    if @csvMode then @csvMode = false else @csvMode = true
    @renderFacilityTimeliness()
    
  renderFacilityTimeliness: =>
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
                      <td>
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
                      <td>#{numberReportsSubmitted = data["Reports submitted for period"] or 0}</td>
                      <td>
                        #{
                          if Number.isNaN(numberReportsSubmitted) or Number.isNaN(expectedNumberOfReports) or expectedNumberOfReports is 0
                            '-'
                          else
                            Math.round(numberReportsSubmitted/expectedNumberOfReports * 1000)/10 + "%"
                        }
                      </td>
                      <td>#{data["Report submitted within 1 day"] or 0}</td>
                      <td>#{data["Report submitted within 1-3 days"] or 0}</td>
                      <td>#{data["Report submitted within 3-5 days"] or 0}</td>
                      <td>#{data["Report submitted 5+ days"] or 0}</td>
                      <td>
                        <!-- Total Tested -->
                        #{
                          totalTested = data["Mal POS < 5"]+data["Mal POS >= 5"]+data["Mal NEG < 5"]+data["Mal NEG >= 5"]
                          if Number.isNaN(totalTested) then '-' else totalTested
                        }

                      </td>
                      <td class='total-positive'>
                        #{
                          totalPositive = data["Mal POS < 5"]+data["Mal POS >= 5"]
                          if Number.isNaN(totalPositive) then '-' else totalPositive
                        }
                        (#{
                          if Number.isNaN(totalTested) or Number.isNaN(totalPositive) or totalTested is 0
                            '-'
                          else
                            Math.round(totalPositive/totalTested * 1000)/10 + "%"
                        })
                      </td>
                      #{
                        _(["casesNotified","hasCompleteFacility","followedUpWithin48Hours"]).map (property) =>
                          "
                            <td class='#{property}'>
                              #{
                                if @csvMode
                                  data[property]?.length or "-"
                                else
                                  if data[property] then HTMLHelpers.createDisaggregatableCaseGroup data[property] else '-'
                              }
                            </td>
                          "
                        .join ""
                      }
                      
                      <td>#{getMedianAndQuartilesElement data["daysBetweenPositiveResultAndNotification"]}</td>
                      <td>#{getMedianAndQuartilesElement data["daysFromCaseNotificationToCompleteFacility"]}</td>
                      <td>
                      #{
                        if data["casesNotified"] and data["casesNotified"].length isnt 0 and data["Facility Followed-Up Positive Cases"]
                          Math.round(data["Facility Followed-Up Positive Cases"].length / data["casesNotified"].length * 1000)/10 + "%"
                        else
                          "-"
                      }
                      </td>
                      <td>#{getMedianAndQuartilesElement data["daysFromSMSToCompleteHousehold"]}</td>
                      <td>
                      #{
                        if data["casesNotified"] and data["casesNotified"].length isnt 0 and data["householdFollowedUp"]
                          Math.round(data["householdFollowedUp"] / data["casesNotified"].length * 1000)/10 + "%"
                        else
                          "-"
                      }
                      </td>
                      <td>
                        #{data["numberHouseholdOrNeighborMembers"] || "-"}
                      </td>
                      <td>
                        #{getNumberAndPercent(data["numberHouseholdOrNeighborMembersTested"],data["numberHouseholdOrNeighborMembers"])}
                      </td>
                      <td>
                        #{getNumberAndPercent(data["numberPositiveCasesAtIndexHouseholdAndNeighborHouseholds"],data["numberHouseholdOrNeighborMembersTested"])}
                      </td>
                    </tr>
                  "
                .join("")
              .join("")
            }
    "

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
	  
  render: =>
    @options = $.extend({},Coconut.router.reportViewOptions)
    @aggregationPeriod = @options.aggregationPeriod or "Month"
    @aggregationArea = @options.aggregationArea or "Zone"
    @facilityType = @options.facilityType or "All"
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
        </style>
        <div id='dateSelector'></div>
        <h5>Compare Weekly Reports and Coconut cases aggregated by 
        <select style='height:50px;font-size:90%' id='aggregationPeriod' class='aggregatedBy'>
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
        <select style='height:50px;font-size:90%' id='aggregationArea' class='aggregatedBy'>
          #{
            _("Zone,District,Facility".split(",")).map (aggregationArea) =>
              "
                <option #{if aggregationArea is @aggregationArea then "selected='true'" else ''}>
                  #{aggregationArea}
                </option>"
            .join ""
          }
        </select>

        for <select style='height:50px;font-size:90%' id='facilityType' class='aggregatedBy'>
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
        <button style='float:right' id='csv'>#{if @csvMode then "Table Mode" else "CSV Mode"}</button></div>
        <br/><br/>
        <table class='tablesorter mdl-data-table mdl-js-data-table mdl-shadow--2dp' id='facilityTimeliness' style='#{if @csvMode then "display:none" else ""}'>
          <thead>
            <th>#{@aggregationPeriod}</th>
            <th>Zone</th>
            #{if @aggregationArea is "District" or @aggregationArea is "Facility" then "<th>District</th>" else ""}
            #{if @aggregationArea is "Facility" then "<th>Facility</th>"  else ""}
            <th>Reports expected for period</th>
            <th>Reports submitted for period</th>
            <th>Percent submitted for period</th>
            <th>Reports submitted within 1 day of period end (Monday)</th>
            <th>Reports submitted within 1-3 days of period end (by Wednesday)</th>
            <th>Reports submitted within 3-5 days of period end (by Friday)</th>
            <th>Reports submitted 7 or more days after period end</th>
            <th>Total Tested</th>
            <th>Total Positive (%)</th>
            <th>Number of cases notified</th>
            <th>Facility Followed-Up Positive Cases</th>
            <th>Cases Followed-Up within 48 Hours</th>
            <th>Median Days from Positive Test Result to Facility Notification (IQR)</th>
            <th>Median Days from Facility Notification to Complete Facility (IQR)</th>
            <th>% of Notified Cases with Complete Facility Followup</th>
            <th>Median Days from Facility Notification to Complete Household (IQR)</th>
            <th>% of Notified Cases with Complete Household Followup</th>
            <th>Number of Household or Neighbor Members</th>
            <th>Number of Household or Neighbor Members Tested (%)</th>
            <th>Number of Household or Neighbor Members Tested Positive (%)</th>
          </thead>
          <tbody> </tbody>
        </table>
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
        $('#analysis-spinner').hide()
        @renderFacilityTimeliness()
      
module.exports = CompareWeeklyView
