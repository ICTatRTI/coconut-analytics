_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
moment = require 'moment'
require 'moment-range'
capitalize = require "underscore.string/capitalize"

DataTables = require( 'datatables.net' )()
Reports = require '../models/Reports'

class EpidemicThresholdView extends Backbone.View
  el: "#content"

  render: =>
    @startDate = Coconut.router.reportViewOptions.startDate
    @endDate = Coconut.router.reportViewOptions.endDate
    $("#row-region").hide()
    HTMLHelpers.ChangeTitle("Reports: Epidemic Thresholds")
    @$el.html "
        <style>
          .mdl-data-table { table-layout: auto}
          .alert {padding: 0; margin-bottom: 5px }
        </style>
        <div class='clearfix'></div>
        <div id='dateSelector'></div>
        <h5 onClick='$(\"#threshold-definition-descriptions\").toggle()'>Threshold Definitions ▶</h5>
        <div id='threshold-definition-descriptions' style='display:none'>
          <div>
            Every day the system checks to see if there are any places with numbers that exceed the following thresholds for the defined time period. This is an attempt to automatically identify places that might need further attention. These exceeded thresholds are organized by the week of the ending period of the threshold being checked. If the threshold is found to be exceeded more than once during a week, then that separate finding is noted in the previously found threshold.
          </div>
           <table id='thresholdKey' class='mdl-data-table mdl-js-data-table mdl-shadow--2dp'>
              <thead>
                <tr>
                  <th>Type</th>
                  <th>Range</th>
                  <th>Aggregation Area</th>
                  <th>Indicator</th>
                  <th>Threshold</th>
                </tr>
              </thead>
              <tbody>
              </tbody>
           </table>
        </div>

        <h5>
        Number of Times Thresholds Exceeded (#{moment(@startDate).format('YYYY-MM-DD')} - #{moment(@endDate).format('YYYY-MM-DD')})
        </h5>

        <table id='thresholdTotals' class='mdl-data-table mdl-js-data-table mdl-shadow--2dp'>
          <tr>
            <th></th>
            <th>
              Alert
              <i class='mdi mdi-bell-ring-outline mdi-24px alert'></i>
            </th>
            <th>
              Alarm
              <i class='mdi mdi-bell-ring mdi-24px alarm'></i>
            </th>
          </tr>
          <tbody>
            #{
              (for type in ["Facilities", "Shehias", "Total"]
                "
                <tr>
                  <td>#{type}</td>
                  <td><span id='#{type}-alert'>#{}</span></td>
                  <td><span id='#{type}-alarm'>#{}</span></td>
                </tr>
                "
              ).join("")
            }
          </tbody>
        </table>
        <div class='clearfix'></div>
        <h5>
        Thresholds By District and Week
        </h5>
    "

    thresholds = (await Coconut.reportingDatabase.get "epidemic_thresholds").data

    for range, rangeThresholds of thresholds
      for data in rangeThresholds
        @$("#thresholdKey tbody").append "
          <tr>
            <th>
              #{data.type}
              <i class='mdi mdi-bell-ring#{if data.type is "Alert" then "-outline" else ""} mdi-24px alert'></i>
            </th>
            <th>
              #{range}
            </th>
            <th>
              #{data.aggregationArea}
            </th>
            <th>
              #{data.indicator}
            </th>
            <th>
              #{data.threshold}
            </th>
          </tr>
        "
        


    startDate = moment(Coconut.router.reportViewOptions.startDate)
    endDate = moment(Coconut.router.reportViewOptions.endDate).endOf("day")
    weekRange = []
    moment.range(startDate,endDate).by 'week', (moment) ->
      weekRange.push moment.format("GGGG-WW")

    # Need to look for any that start or end within our target period - longest alert/alarm range is 14 days
    #startkeyDate = startDate.subtract(14,'days').format("YYYY-MM-DD")
    #endkeyDate = endDate.add(14,'days').format("YYYY-MM-DD")

    Coconut.database.allDocs
      startkey: "threshold-#{_(weekRange).first()}"
      endkey: "threshold-#{_(weekRange).last()}\ufff0"
      include_docs: true
    .catch (error) -> console.error error
    .then (result) =>
      thresholdsByDistrictAndWeek = {}
      _(result.rows).each (row) =>
        console.log row.doc
        district = row.doc.District
        week = row.doc.YearWeekEndDate
        thresholdsByDistrictAndWeek[district] = {} unless thresholdsByDistrictAndWeek[district]
        thresholdsByDistrictAndWeek[district][week] = [] unless thresholdsByDistrictAndWeek[district][week]
        thresholdsByDistrictAndWeek[district][week].push row.doc

      numAlarms = numAlerts = myAlarms = myAlerts = 0
      facilityAlarms = facilityAlerts = 0
      shehiasAlarms = shehiasAlerts = 0
      @$el.append "
         <div class='outer-div'>
           <table class='mdl-data-table mdl-js-data-table mdl-shadow--2dp' id='thresholdTable'>
              <thead>
                <tr>
                  <th>
                    <div style='text-align:right'>Date</div>
                    <div style='text-align:left'>District</div>
                  </th>
                  #{
                    _(weekRange).map (week) ->
                      weekMoment = moment(week, "GGGG-WW")
                      week = weekMoment.isoWeek()
                      startOfWeek = weekMoment.startOf("isoWeek").format("Do MMM")
                      endOfWeek = weekMoment.endOf("isoWeek").format("Do MMM")
                      "
                      <th>
                        Wk. #{week} &nbsp; 
                        <span style='color:grey;font-size:0.9em'>#{startOfWeek}-#{endOfWeek}</span>
                      </th>
                      "
                    .join("")
                  }
                </tr>
              </thead>
              <tbody>
                #{
                  _(GeoHierarchy.allDistricts()).map (district) ->
                    "
                      <tr>
                        <td style='text-align:left'>#{district}</td>
                        #{
                          _(weekRange).map (week) ->
                            "
                            <td>
                              #{
                                _(thresholdsByDistrictAndWeek[district]?[week]).map (threshold) ->
                                  if threshold.ThresholdType is 'Alarm'
                                    notifyIcon = "<i class='mdi mdi-bell-ring mdi-24px alert'></i>"
                                    numAlarms += 1
                                    myAlarms += 1 if threshold['Assigned To']?.substring(5) is Coconut.currentlogin
                                    facilityAlarms += 1 if threshold['LocationType'] is 'facility'
                                    shehiasAlarms += 1 if threshold['LocationType'] is 'shehia'
                                  else if threshold.ThresholdType is 'Alert'
                                    notifyIcon = "<i class='mdi mdi-bell-ring-outline mdi-24px alert'></i>"
                                    numAlerts += 1
                                    myAlerts += 1 if threshold['Assigned To']?.substring(5) is Coconut.currentlogin
                                    facilityAlerts += 1 if threshold['LocationType'] is 'facility'
                                    shehiasAlerts += 1 if threshold['LocationType'] is 'shehia'
                                  else notifyIcon = ""

                                  if threshold['Assigned To']?.substring(5) is Coconut.currentlogin
                                    priorityIcon = "<i class='mdi mdi-account-location mdi-24px assigned'></i>"
                                  else
                                    priorityIcon = "<i class='mdi mdi-alert-outline mdi-24px visited''></i>"

                                  tileTitle = threshold.Description.split(',')[0].toUpperCase()
                                  period = "Start: #{threshold.StartDate} End: #{threshold.EndDate}"
                                  #console.log threshold
                                  "
                                  <button class='mdl-card__media btn_th'>
                                   <a href='#show/issue/#{threshold._id}' title='#{period}'>
                                    <div class='one'>
                                      <!--#{priorityIcon} Removed since assigning not being used-->
                                      #{notifyIcon}
                                    </div>
                                    <div class='two'>
                                      <span class='alarm-badge mdl-badge'>Amount: #{threshold.Amount}</span>
                                    </div>
                                    <div class='clearfix'></div>
                                    <div style='overflow:hidden' class='three'>
                                         #{tileTitle}
                                    </div>
                                    </a>
                                  </button>
                                  "
                              }
                            </td>
                            "
                          .join('')
                        }
                      </tr>
                    "
                  .join('')
                }
              </tbody>
          </table>
         </div>
      "
      $('#Total-alert').html(numAlerts)
      $('#Total-alarm').html(numAlarms)
      $('#Facilities-alert').html(facilityAlerts)
      $('#Facilities-alarm').html(facilityAlarms)
      $('#Shehias-alert').html(shehiasAlerts)
      $('#Shehias-alarm').html(shehiasAlarms)

      $('#analysis-spinner').hide()

      # $("#thresholdTable").dataTable
      #   aaSorting: [[0,"asc"]]
      #   iDisplayLength: 50
      #   dom: 'T<"clear">lfrtip'
      #   tableTools:
      #     sSwfPath: "js-libraries/copy_csv_xls.swf"
      #     aButtons: ["csv"]

module.exports = EpidemicThresholdView
