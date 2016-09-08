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
                          <span class='alert-badge mdl-badge' style='position: relative'>2 Cases</span>
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
                          <span class='alert-badge mdl-badge' style='position: relative'>22 Cases</span>
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
                          <span class='alarm-badge mdl-badge'>5 Cases</span>
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
                            <span class='alarm-badge mdl-badge'>Cases: 12</span>
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
           <p>
           (Note that cases counted for district thresholds don't include household and neighbor cases)</p>

         </div>
        <!--<button class='btn' style='margin-top: 10px; float: right;'>Reset Table</button>-->
      <div class='epi-summary'>
            
            <div id='district' class='mdl-card--expand'>
              <h5>DISTRICTS:</h5>
              <i class='material-icons alert'>notifications_none</i><span>5 Alerts</span>
              <i class='material-icons alarm'>notifications_active</i><span>5 Alarms</span>         
            </div>
            <div id='facility' class='mdl-card--expand'>
              <h5>FACILITIES:</h5>
              <i class='material-icons alert'>notifications_none</i><span>8 Alerts</span>
              <i class='material-icons alarm'>notifications_active</i><span>1 Alarms</span>     
            </div>
            
            <div id='shehia' class='mdl-card--expand'>
              <h5>SHEHIAS:</h5>
              <i class='material-icons alert'>notifications_none</i><span>7 Alerts</span>
              <i class='material-icons alarm'>notifications_active</i><span>1 Alarms</span>     
            </div>
            <div id='village' class='mdl-card--expand'>
              <h5>VILLAGES:</h5>
              <i class='material-icons alert'>notifications_none</i><span>4 Alerts</span>
              <i class='material-icons alarm'>notifications_active</i><span>2 Alarms</span>     
            </div>
            

         </div>
         
         <div class='clearfix'></div>
         
         <div class='outer-div'>

         <table class='mdl-data-table mdl-js-data-table mdl-shadow--2dp' id='thresholdTable'> 
            <thead> 
              <tr>
                <th>District</th>
                <th>2016-05</th>
                <th>2016-06</th>
                <th>2016-07</th>
                <th>2016-08</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td>WETE</td>
                <td>
                  <button class='mdl-card__media btn_th'>
                    <div class='one'>
                        <i class='material-icons visited'>priority_high</i>
                        <i class='material-icons alert'>notifications_active</i>
                    </div>
                    <div class='two'>
                      <span class='alarm-badge mdl-badge'>Cases: 12</span>
                    </div>
                    <div class='clearfix'></div>
                    <div class='three'>
                       <a href='#show/issue/threshold-2016-01-25--2016-02-01-Alert-7-days-facility-total.WETE'>VILLAGE: KIJICHAME</a>
                    </div>
                  </button>
                </td>
                <td>
                  <button class='mdl-card__media btn_th'>
                    <div class='one'>
                      <i class='material-icons visited'>priority_high</i>
                      <i class='material-icons alert'>notifications_none</i>
                    </div>
                    <div class='two'>
                      <span class='alert-badge mdl-badge'>Cases: 14</span>
                    </div>
                    <div class='clearfix'></div>
                    <div class='three'>
                      <a href='#show/issue/threshold-2016-01-25--2016-02-01-Alert-7-days-facility-total.WETE'>FACILITY: WETE</a>
                    </div>
                  </button>
                </td>
                <td>
                  <button class='mdl-card__media btn_th'>
                    <div class='one'>
                      <i class='material-icons assigned'>person_pin</i>
                      <i class='material-icons alarm'>notifications_active</i>
                    </div>
                    <div class='two'>
                      <span class='alarm-badge mdl-badge'>Cases: 13</span>
                    </div>
                    <div class='clearfix'></div>
                    <div class='three'>
                      <a href='#show/issue/threshold-2016-01-25--2016-02-01-Alert-7-days-facility-total.WETE'>DISTRICT: MICHEWENI</a>
                    </div>
                    </button>
                </td>
                
                <td>
                  <button class='mdl-card__media btn_th'>
                    <div class='one'>
                      <i class='material-icons visited'>person_pin</i>
                      <i class='material-icons alert'>notifications_none</i>
                    </div>
                    <div class='two'>
                      <span class='alert-badge mdl-badge'>Cases: 11</span>
                    </div>
                    <div class='clearfix'></div>
                    <div class='three'>  
                        <a href='#show/issue/threshold-2016-01-25--2016-02-01-Alert-7-days-facility-total.WETE'>SHEHIA: TUMBE MASHARIKI</a>
                      </div>
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
         
         </div>
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

      
      $('#analysis-spinner').hide()
      
      # $("#thresholdTable").dataTable
      #   aaSorting: [[0,"asc"]]
      #   iDisplayLength: 50
      #   dom: 'T<"clear">lfrtip'
      #   tableTools:
      #     sSwfPath: "js-libraries/copy_csv_xls.swf"
      #     aButtons: ["csv"]
          
module.exports = EpidemicThresholdView
