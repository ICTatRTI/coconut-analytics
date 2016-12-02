_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
moment = require 'moment'
PouchDB = require 'pouchdb'
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

    @$el.html "
        <style>
          .mdl-data-table { table-layout: auto}
          .alert {padding: 0; margin-bottom: 5px }
        </style>
        <div class='clearfix'></div>
        <div id='dateSelector'></div>
        <div id='epi-key'>
           <table id='thresholdKey' class='mdl-data-table mdl-js-data-table mdl-shadow--2dp'>
              <thead> 
                 <tr> 
                    <th class='mdl-data-table__cell--non-numeric'>Status</th>
                    <th class='threshold'>Your Alerts & Alarms</th>
                    <th class='threshold'>Alerts & Alarms</th>
                    <th class='threshold'>Facility</th> 
                    <th class='threshold'>Shehia</th> 
                    <th class='threshold'>Village</th> 
                    <th class='threshold'>District</th>
                 </tr> 
              </thead> 
              <tbody> 
                 <tr> 
                    <td style='background:#eee'>
                      Alert <i class='mdl-button mdl-js-button mdl-button--icon mdl-button--accent material-icons'>notifications_none</i>
                    </td> 
                    <td class='threshold'>
                      <button class='mdl-card__media btn_th'>
                        <div class='one'>
                          <i class='material-icons assigned'>person_pin</i>
                          <i class='material-icons alert'>notifications_none</i>
                        </div>
                        <div class='two'>
                          <span class='alert-badge mdl-badge' style='position: relative' id='myAlerts'>0</span> Cases
                        </div>
                        <div class='clearfix'></div>
                      </button>
                    </td>
                    <td class='threshold'>
                      <button class='mdl-card__media btn_th'>
                        <div class='one'>
                          <i class='material-icons visited'>priority_high</i>
                          <i class='material-icons alert'>notifications_none</i>
                        </div>
                        <div class='two'>
                          <span class='alert-badge mdl-badge' style='position: relative' id='numAlerts'>0</span> Cases
                        </div>
                        <div class='clearfix'></div>
                      </button>
                    </td>
                    <td class='threshold'>5 or more under 5 cases or 10 or more total cases within 7 days</td>
                    <td class='threshold'>5 or more under 5 cases or 10 or more total cases within 7 days</td> 
                    <td class='threshold'>5 or more total cases within 7 days</td> 
                    <td class='threshold' rowspan='2'>Specific for each district and week, based on 5 years of previous data</td> 
                 </tr> 
                 <tr> 
                    <td style='background:#eee'>
                      <span>Alarm</span> <i class='mdl-button mdl-js-button mdl-button--icon mdl-button--accent material-icons'>notifications_active</i>
                    </td> 
                    <td class='threshold'>
                      <button class='mdl-card__media btn_th'>
                        <div class='one'>
                          <i class='material-icons assigned'>person_pin</i>
                          <i class='material-icons alarm'>notifications_active</i>
                        </div>
                        <div class='two'>
                          <span class='alarm-badge mdl-badge' id='myAlarms'>0 Cases</span>
                        </div>
                        <div class='clearfix'></div>
                      </button>
                      </td>
                      <td class='threshold'>
                        <button class='mdl-card__media btn_th'>
                          <div class='one'>
                            <i class='material-icons visited'>priority_high</i>
                            <i class='material-icons alert'>notifications_active</i>
                          </div>
                          <div class='two'>
                            <span class='alarm-badge mdl-badge' id='numAlarms'>0 Cases</span>
                          </div>
                          <div class='clearfix'></div>
                        </button>
                      </td>
                    <td class='threshold'>10 or more under 5 cases or 20 or more total cases within 14 days</td>
                    <td class='threshold'>10 or more under 5 cases or 20 or more total cases within 14 days</td>  
                    <td class='threshold'>10 or more total cases within 14 days</td> 
                    
                 </tr>
                 
              </tbody>
           </table>
           <p>(Note that cases counted for district thresholds don't include household and neighbor cases)</p>
        </div>
        <!--<button class='btn' style='margin-top: 10px; float: right;'>Reset Table</button>-->
        <div class='epi-summary'>
            <div id='district' class='mdl-card--expand'>
              <h5>DISTRICTS:</h5>
              <i class='material-icons alert'>notifications_none</i><span id='districtAlert'>0</span>
              <i class='material-icons alarm'>notifications_active</i><span id='districtAlarm'>0</span>
            </div>
            <div id='facility' class='mdl-card--expand'>
              <h5>FACILITIES:</h5>
              <i class='material-icons alert'>notifications_none</i><span id='facilityAlert'>0</span>
              <i class='material-icons alarm'>notifications_active</i><span id='facilityAlarm'>0</span>
            </div>
            
            <div id='shehia' class='mdl-card--expand'>
              <h5>SHEHIAS:</h5>
              <i class='material-icons alert'>notifications_none</i><span id='shehiasAlert'>0</span>
              <i class='material-icons alarm'>notifications_active</i><span id='shehiasAlarm'>0</span>
            </div>
            <div id='village' class='mdl-card--expand'>
              <h5>VILLAGES:</h5>
              <i class='material-icons alert'>notifications_none</i><span id='villageAlert'>0</span>
              <i class='material-icons alarm'>notifications_active</i><span id='villageAlarm'>0</span>
            </div>
        </div> 
        <div class='clearfix'></div>
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
                  <th>District</th>
                  #{
                    _(weekRange).map (week) ->
                      "<th>#{week}</th>"
                    .join("")
                  }
                </tr>
              </thead>
              <tbody>
                #{
                  _(GeoHierarchy.allDistricts()).map (district) ->
                    "
                      <tr>
                        <td>#{district}</td>
                        #{
                          _(weekRange).map (week) ->
                            "
                            <td>
                              #{
                                _(thresholdsByDistrictAndWeek[district]?[week]).map (threshold) ->
                                  if threshold.ThresholdType is 'Alarm'
                                    notifyIcon = "<i class='material-icons alert'>notifications_active</i>"
                                    numAlarms += 1 
                                    myAlarms += 1 if threshold['Assigned To']?.substring(5) is Coconut.currentlogin
                                    districtAlarms += 1 if threshold['LocationType'] is 'district'
                                    facilityAlarms += 1 if threshold['LocationType'] is 'facility'
                                    shehiasAlarms += 1 if threshold['LocationType'] is 'shehia'
                                    villageAlarms += 1 if threshold['LocationType'] is 'village'
                                  else if threshold.ThresholdType is 'Alert'
                                    notifyIcon = "<i class='material-icons alert'>notifications_none</i>"
                                    numAlerts += 1 
                                    myAlerts += 1 if threshold['Assigned To']?.substring(5) is Coconut.currentlogin
                                    districtAlerts += 1 if threshold['LocationType'] is 'district'
                                    facilityAlerts += 1 if threshold['LocationType'] is 'facility'
                                    shehiasAlerts += 1 if threshold['LocationType'] is 'shehia'
                                    villageAlerts += 1 if threshold['LocationType'] is 'village'
                                  else notifyIcon = ""
                                  
                                  if threshold['Assigned To']?.substring(5) is Coconut.currentlogin
                                    priorityIcon = "<i class='material-icons assigned'>person_pin</i>"
                                  else
                                    priorityIcon = "<i class='material-icons visited''>priority_high</i>"
                                  
                                  tileTitle = threshold.Description.split(',')[0].toUpperCase()
                                  "
                                  <button class='mdl-card__media btn_th'>
                                   <a href='#show/issue/#{threshold._id}' title='#{tileTitle}'>
                                    <div class='one'>
                                      #{priorityIcon}
                                      #{notifyIcon}
                                    </div>
                                    <div class='two'>
                                      <span class='alarm-badge mdl-badge'>Cases: #{threshold.Cases?.length || 0}</span>
                                    </div>
                                    <div class='clearfix'></div>
                                    <div class='three'>
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
      $('#myAlerts').html(myAlerts)
      $('#myAlarms').html(myAlarms + " Cases")
      $('#numAlerts').html(numAlerts)
      $('#numAlarms').html(numAlarms + " Cases")
      $('#districtAlert').html(districtAlerts)
      $('#districtAlarm').html(districtAlarms)
      $('#facilityAlert').html(facilityAlerts)
      $('#facilityAlarm').html(facilityAlarms)
      $('#shehiasAlert').html(shehiasAlerts)
      $('#shehiasAlarm').html(shehiasAlarms)
      $('#villageAlert').html(villageAlerts)
      $('#villageAlarm').html
      
      $('#analysis-spinner').hide()
      
      # $("#thresholdTable").dataTable
      #   aaSorting: [[0,"asc"]]
      #   iDisplayLength: 50
      #   dom: 'T<"clear">lfrtip'
      #   tableTools:
      #     sSwfPath: "js-libraries/copy_csv_xls.swf"
      #     aButtons: ["csv"]

module.exports = EpidemicThresholdView
