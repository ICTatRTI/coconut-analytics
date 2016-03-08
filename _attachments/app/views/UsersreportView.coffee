_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

DataTables = require 'datatables'
Reports = require '../models/Reports'

class UsersreportView extends Backbone.View
  el: "#content"

  events:
    "click button#dateFilter": "showForm"
    "click .userReports": "showDropDown"

  showForm: (e) =>
    e.preventDefault
    $("div#filters-section").slideToggle()

  showDropDown: (e) =>
    $target =  $(e.target).closest('.userReports')
    $target.next(".user-report").slideToggle()
    if ($target.find("i").text()== "play_arrow")
       iconStatus = "details"	
    else
       iconStatus = "play_arrow"
    $target.find("i").text(iconStatus)
	
  render: =>
#    $('#analysis-spinner').show()
    @$el.html "
      <div id='dateSelector'></div>
  	  <div id='users'> 
        <h4>How fast are followups occuring?</h4> 
        <div class='userReports dropDownBtn'>
           <h4><button class='mdl-button mdl-js-button mdl-button--icon'><i class='material-icons'>play_arrow</i></button>
            All Users</h4>
        </div>
        <div id='allUsers' class='user-report dropdown-section hide'>
          <table style='font-size:150%' class='tablesorter' style=' id='usersReportTotals'>
            <tbody>
              <tr style='font-weight:bold' id='medianTimeFromSMSToCompleteHousehold'><td>Median time from SMS sent to Complete Household</td></tr>
              <tr class='odd' id='cases'><td>Cases</td></tr>
              <tr id='casesWithoutCompleteFacilityAfter24Hours'><td>Cases without completed <b>facility</b> record 24 hours after facility notification</td></tr>
              <tr class='odd' id='casesWithoutCompleteHouseholdAfter48Hours'><td>Cases without complete <b>household</b> record 48 hours after facility notification</td></tr>
              <tr id='casesWithCompleteHousehold'><td>Cases with complete household record</td></tr>
              <tr class='odd' id='medianTimeFromSMSToCaseNotification'><td>Median time from SMS sent to Case Notification on tablet</td></tr>
              <tr id='medianTimeFromCaseNotificationToCompleteFacility'><td>Median time from Case Notification to Complete Facility</td></tr>
              <tr class='odd' id='medianTimeFromFacilityToCompleteHousehold'><td>Median time from Complete Facility to Complete Household</td></tr>
            </tbody>
          </table>
        </div>
        <div class='userReports dropDownBtn'>
           <h4><button class='mdl-button mdl-js-button mdl-button--icon'><i class='material-icons'>play_arrow</i></button>
            By User</h4>
        </div>
        <div id='usersReport_wrapper' class='dataTables_wrapper no-footer user-report dropdown-section hide'>
            <table class='tablesorter' style='' id='usersReport'>
              <thead>
                <th>Name</th>
                <th>District</th>
                <th>Cases</th>
                <th>Cases without complete <b>facility</b> record 24 hours after facility notification</th>
                <th>Cases without complete <b>facility</b> record</th>
                <th>Cases without complete <b>household</b> record 48 hours after facility notification</th>
                <th>Cases without complete <b>household</b> record</th>
                <th>Median time from SMS sent to Case Notification on tablet (IQR)</th>
                <th>Median time from Case Notification to Complete Facility (IQR)</th>
                <th>Median time from Complete Facility to Complete Household (IQR)</th>
                <th>Median time from SMS sent to Complete Household (IQR)</th>
              </thead>
              <tbody>
                #{
                  ###
                  Users.map (user) ->
                    if userAnalysis.dataByUser[user.username()]?
                      "
                      <tr id='#{user.username()}'>
                        <td>#{user.nameOrUsername()}</td>
                        <td>#{user.districtInEnglish() or "-"}</td>
                      </tr>
                      "
                    else ""
                  .join("")
                  ###
                }
              </tbody>
            </table>
        </div>
    "

module.exports = UsersreportView
