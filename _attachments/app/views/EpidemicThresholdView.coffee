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
        <h5>Threshold Definitions</h5>
        <div id='epi-key'>
           <table id='thresholdKey' class='mdl-data-table mdl-js-data-table mdl-shadow--2dp'>
              <thead>
                 <tr>
                    <th class='mdl-data-table__cell--non-numeric'></th>
                    <!-- Removed since assigning alerts is not being used
                    <th class='threshold'>Your Alerts & Alarms</th>
                    -->
                    <th class='threshold'>Facility or Shehia</th>
                    <th class='threshold'>Village</th>
                 </tr>
              </thead>
              <tbody>
                 <tr>
                    <td style='background:#eee'>
                      Alert <i class='mdl-button mdl-js-button mdl-button--icon mdl-button--accent mdi mdi-bell-ring-outline mdi-24px'></i>
                    </td>
                    <td class='threshold'>5 or more under 5 cases or 10 or more total cases within 7 days</td>
                    <td class='threshold'>5 or more total cases within 7 days</td>
                    <!--
                    <td class='threshold' rowspan='2'>Specific for each district and week, based on 5 years of previous data</td>
                    -->
                 </tr>
                 <tr>
                    <td style='background:#eee'>
                      <span>Alarm</span> <i class='mdl-button mdl-js-button mdl-button--icon mdl-button--accent mdi mdi-bell-ring mdi-24px'></i>
                    </td>
                    <td class='threshold'>10 or more under 5 cases or 20 or more total cases within 14 days</td>
                    <td class='threshold'>10 or more total cases within 14 days</td>

                 </tr>

              </tbody>
           </table>
           <!--
           <p>(Note that cases counted for district thresholds don't include household and neighbor cases)</p>
           -->
        </div>

        <h5>
        Number of Times Thresholds Exceeded (#{moment(@startDate).format('YYYY-MM-DD')} - #{moment(@endDate).format('YYYY-MM-DD')})
        </h5>

        <table id='thresholdTotals' class='mdl-data-table mdl-js-data-table mdl-shadow--2dp'>
          <tr>
            <th></th>
            <th>
              Alert
              <i class='mdl-button mdl-js-button mdl-button--icon mdl-button--accent mdi mdi-bell-ring-outline mdi-24px alert'></i>
            </th>
            <th>
              Alarm
              <i class='mdl-button mdl-js-button mdl-button--icon mdl-button--accent mdi mdi-bell-ring mdi-24px alarm'></i>
            </th>
          </tr>
          <tbody>
            #{
              (for type in ["Facilities", "Shehias", "Villages", "Total"]
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
    startDate = moment(Coconut.router.reportViewOptions.startDate)
    endDate = moment(Coconut.router.reportViewOptions.endDate).endOf("day")
    weekRange = []
    moment.range(startDate,endDate).by 'week', (moment) ->
      weekRange.push moment.format("GGGG-WW")

    # Need to look for any that start or end within our target period - longest alert/alarm range is 14 days
    startkeyDate = startDate.subtract(14,'days').format("YYYY-MM-DD")
    endkeyDate = endDate.add(14,'days').format("YYYY-MM-DD")

    Coconut.database.allDocs
      startkey: "threshold-#{startkeyDate}"
      endkey: "threshold-#{endkeyDate}\ufff0"
      include_docs: true
    .catch (error) -> console.error error
    .then (result) =>
      thresholdsByDistrictAndWeek = {}
      _(result.rows).each (row) =>
        # If the threshold is starts or ends during the relevant week, then include it, otherwise ignore it
        if (row.doc.StartDate >= @startDate and row.doc.StartDate <= @endDate) or (row.doc.EndDate >= @startDate and row.doc.EndDate <= @endDate)
          district = row.doc.District
          week = moment(row.doc.EndDate).format "GGGG-WW"
          thresholdsByDistrictAndWeek[district] = {} unless thresholdsByDistrictAndWeek[district]
          thresholdsByDistrictAndWeek[district][week] = [] unless thresholdsByDistrictAndWeek[district][week]
          thresholdsByDistrictAndWeek[district][week].push row.doc

      numAlarms = numAlerts = myAlarms = myAlerts = 0
      districtAlarms = districtAlerts = facilityAlarms = facilityAlerts = 0
      shehiasAlarms = shehiasAlerts = villageAlarms = villageAlerts = 0
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
                                    districtAlarms += 1 if threshold['LocationType'] is 'district'
                                    facilityAlarms += 1 if threshold['LocationType'] is 'facility'
                                    shehiasAlarms += 1 if threshold['LocationType'] is 'shehia'
                                    villageAlarms += 1 if threshold['LocationType'] is 'village'
                                  else if threshold.ThresholdType is 'Alert'
                                    notifyIcon = "<i class='mdi mdi-bell-ring-outline mdi-24px alert'></i>"
                                    numAlerts += 1
                                    myAlerts += 1 if threshold['Assigned To']?.substring(5) is Coconut.currentlogin
                                    districtAlerts += 1 if threshold['LocationType'] is 'district'
                                    facilityAlerts += 1 if threshold['LocationType'] is 'facility'
                                    shehiasAlerts += 1 if threshold['LocationType'] is 'shehia'
                                    villageAlerts += 1 if threshold['LocationType'] is 'village'
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
                                      <span class='alarm-badge mdl-badge'>Cases: #{threshold.Amount}</span>
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
      $('#Districts-alert').html(districtAlerts)
      $('#District-alarm').html(districtAlarms)
      $('#Facilities-alert').html(facilityAlerts)
      $('#Facilities-alarm').html(facilityAlarms)
      $('#Shehias-alert').html(shehiasAlerts)
      $('#Shehias-alarm').html(shehiasAlarms)
      $('#Villages-alert').html(villageAlerts)
      $('#Villages-alarm').html(villageAlarms)

      $('#analysis-spinner').hide()

      # $("#thresholdTable").dataTable
      #   aaSorting: [[0,"asc"]]
      #   iDisplayLength: 50
      #   dom: 'T<"clear">lfrtip'
      #   tableTools:
      #     sSwfPath: "js-libraries/copy_csv_xls.swf"
      #     aButtons: ["csv"]

module.exports = EpidemicThresholdView
