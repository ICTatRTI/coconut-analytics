_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

DataTables = require( 'datatables.net' )()
Reports = require '../models/Reports'
global.UserCollection = require '../models/UserCollection'
CaseView = require './CaseView'

class UsersReportView extends Backbone.View
  el: "#content"

  events:
    "click .userReports": "showDropDown"
    "click button.caseBtn": "showCaseDialog"
    "click button#closeDialog": "closeDialog"
    "click button#toggleDetails": "toggleDetails"

  hideDetails: =>
    @$(".iqr").hide()
    @$(".details").hide()

  toggleDetails: =>
    @$(".iqr").toggle()
    @$(".details").toggle()

  showDropDown: (e) =>
    $target =  $(e.target).closest('.userReports')
    $target.next(".user-report").slideToggle()
    if ($target.find("i").text()== "play_arrow")
       iconStatus = "details"
    else
       iconStatus = "play_arrow"
    $target.find("i").text(iconStatus)

  showCaseDialog: (e) ->
    caseID = $(e.target).parent().attr('id') || $(e.target).attr('id')
    CaseView.showCaseDialog
      caseID: caseID
      success: ->
    return false

  closeDialog: ->
    caseDialog.close() if caseDialog.open

  indicators: [
    [
      "What is the average time required to investigate a case?"
      "Median time from Case Notification Sent to Complete Household"
      "TimeFromSMSToCompleteHousehold"
      "Average time to investigate"
    ]
    [
      "What is the average time required to begin the investigations?"
      "Median time from Case Notification Sent to Case Notification Received on mobile device"
      "TimeFromSMSToCaseNotification"
      "Average time to begin"
    ]
    [
      "What is the average time required to complete the facility visits?"
      "Median time from Case Notification Received to Complete Facility"
      "TimeFromCaseNotificationToCompleteFacility"
      "Average time to complete facilty"
    ]
    [
      "What is the average time required to complete household visits after finishing at the facility?"
      "Median time from Complete Facility to Complete Household"
      "TimeFromFacilityToCompleteHousehold"
      "Average time to complete household"
    ]
  ]


  render: =>
    HTMLHelpers.ChangeTitle("Reports: Users Report - How Long Do Investigations Take?")
    @$el.html "
      <style>
        .explanation{
          font-size: 0.5em;

        }
        .caseBtn {
          display: block;
          width: 100px;
        }
      </style>
        <dialog id='caseDialog'></dialog>
        <div id='dateSelector'></div>
        <h4>How long do investigations take?</h4>
        <div id='users'>
        <div class='userReports dropDownBtn'>
          <h4><button class='mdl-button mdl-js-button mdl-button--icon'><i class='mdi mdi-play mdi-24px'></i></button>
           All Users</h4>
        </div>
        <div id='allUsers' class='user-report dropdown-section'>
         <table style='font-size:150%' class='tablesorter' style=' id='usersReportTotals'>
           <tbody>
            #{
              (for indicator in @indicators
                "
                <tr id='median#{indicator[2]}'>
                  <td>
                    #{indicator[0]}
                    <div class='explanation'>#{indicator[1]}</div>
                  </td>
                </tr>
                "
              ).join("")
            }
             <tr class='odd' id='cases'><td>Cases</td></tr>
             <tr id='casesWithoutCompleteFacilityAfter24Hours'><td>Cases missing <b>facility</b> record 24 hours after notification</td></tr>
             <tr class='odd' id='casesWithoutCompleteHouseholdAfter48Hours'><td>Cases without complete <b>household</b> record 48 hours after notification</td></tr>
             <tr id='casesWithCompleteHousehold'><td>Cases with complete household record</td></tr>
           </tbody>
         </table>
        </div>
    "
    $('#analysis-spinner').show()
    Users = new UserCollection()
    Users.fetch()
    .catch (error) -> console.error error
    .then =>
      @startDate = Coconut.router.reportViewOptions.startDate
      @endDate = Coconut.router.reportViewOptions.endDate
      Reports.userAnalysisForUsers
        # Pass list of usernames
        usernames:  Users.map (user) -> user.username()
        startDate: @startDate
        endDate: @endDate
        error: (error) ->
          console.error error
        success: (userAnalysis) =>
          console.log userAnalysis
          $('#content').append "

              <div class='userReports dropDownBtn'>
                 <h4><button class='mdl-button mdl-js-button mdl-button--icon'><i class='mdi mdi-play mdi-24px'></i></button>
                  By User</h4>
              </div>
              <div id='usersReport_wrapper' class='dataTables_wrapper no-footer user-report dropdown-section'>
                <button id='toggleDetails'>Toggle Details</button>
                <table class='tablesorter mdl-data-table mdl-js-data-table mdl-shadow--2dp' style='' id='usersReport'>
                  <thead>
                    <th class='mdl-data-table__cell--non-numeric'>Name</th>
                    <th class='mdl-data-table__cell--non-numeric'>District</th>
                    #{
                      (for indicator in @indicators
                        "
                        <th id='header#{indicator[2]}' class='#{if indicator[3] is "Average time to investigate" then "" else "details"}'>
                          #{indicator[3]}
                        </th>
                        "
                      ).join("")
                    }
                    <th id='header-cases'>Cases</th>
                    <th class='details'>Cases without complete <b>facility</b> record 24 hours after facility notification</th>
                    <th class='details'>Cases without complete <b>facility</b> record</th>
                    <th class='details'>Cases without complete <b>household</b> record 48 hours after facility notification</th>
                    <th class='details'>Cases without complete <b>household</b> record</th>
                  </thead>
                  <tbody>
                    #{
                      Users.map (user) ->
                        if userAnalysis.dataByUser[user.username()]?
                          "
                          <tr id='#{user.username()}'>
                            <td class='mdl-data-table__cell--non-numeric'>#{user.nameOrUsername()}</td>
                            <td class='mdl-data-table__cell--non-numeric'>#{user.districtInEnglish() or "-"}</td>
                          </tr>
                          "
                        else ""
                      .join("")
                    }
                  </tbody>
                </table>
              </div>
          "
          console.log userAnalysis
          _(userAnalysis.total).each (value,key) =>
            if key is "caseIds"
              ""
            else
              indicator = if _(value).isString()
                value 
              else 
                HTMLHelpers.createDisaggregatableCaseGroupWithLength(value)

              $("tr##{key}").append "<td class= 'a-r'>#{indicator}</td>"

          _(userAnalysis.dataByUser).each (userData,user) =>

            $("tr##{userData.userId}").append "


            #{
              (for indicator in @indicators
                propertySeconds = "median#{indicator[2]}Seconds"
                "
                  <td class='#{if indicator[3] is "Average time to investigate" then "" else "details"}' data-order='#{userData[propertySeconds] or 0}' class='number'>
                    #{userData["median#{indicator[2]}"] or "-"}
                    <span class='iqr'>(#{userData["quartile1#{indicator[2]}"] or "-"},#{userData["quartile3#{indicator[2]}"] or "-"})</span>
                  </td>
                "
              ).join("")
            }


              <td data-type='num' data-order='#{_(userData.cases).size()}' class='number'><button type='button' onClick='$(this).parent().children(\"div\").toggle()'>#{_(userData.cases).size()}</button>
                <div style='display:none'>
                #{
                  cases = _(userData.cases).keys()
                  _(cases).map (caseId) ->
                    timeToComplete = if timeInMilliseconds = userAnalysis.dataByCase[caseId]?.timesFromSMSToCompleteHousehold
                      moment.duration(timeInMilliseconds).humanize()
                    else
                      "Not complete"
                    "
                      <button id='#{caseId}' class='caseBtn' type='button'>
                        #{caseId} - #{timeToComplete}
                      </button><br/>
                    "
                  .join(" ")
                }
                </div>
              </td>

              <td class='number details' data-order='#{_(userData.casesWithoutCompleteFacilityAfter24Hours).size()}'}>
                <button onClick='$(this).parent().children(\"div\").toggle()' type='button'>#{_(userData.casesWithoutCompleteFacilityAfter24Hours).size() or "-"}</button>
                 <div style='display:none'>
                #{
                  cases = _(userData.casesWithoutCompleteFacilityAfter24Hours).keys()
                  _(cases).map (caseId) ->
                    "<button id='#{caseId}' class='mdl-button mdl-js-button mdl-button--icon mdl-button--primary caseBtn' type='button'>#{caseId}</button>"
                  .join(" ")
                }
                </div>
              </td>


              <td class='number details' data-order='#{_(userData.casesWithoutCompleteFacility).size()}'}>
                <button onClick='$(this).parent().children(\"div\").toggle()' type='button'>#{_(userData.casesWithoutCompleteFacility).size() or "-"}</button>
                <div style='display:none'>
                #{
                  cases = _(userData.casesWithoutCompleteFacility).keys()
                  _(cases).map (caseId) ->
                    "<button id='#{caseId}' class='mdl-button mdl-js-button mdl-button--icon mdl-button--primary caseBtn' type='button'>#{caseId}</button>"
                  .join(" ")
                }
                </div>
              </td>

              <td class='number details' data-order='#{_(userData.casesWithoutCompleteHouseholdAfter48Hours).size()}'}>
                <button onClick='$(this).parent().children(\"div\").toggle()' type='button'>#{_(userData.casesWithoutCompleteHouseholdAfter48Hours).size() or "-"}</button>
                <div style='display:none'>
                #{
                  cases = _(userData.casesWithoutCompleteHouseholdAfter48Hours).keys()
                  _(cases).map (caseId) ->
                    "<button id='#{caseId}' class='mdl-button mdl-js-button mdl-button--icon mdl-button--primary caseBtn' type='button'>#{caseId}</button>"
                  .join(" ")
                }
                </div>
              </td>

              <td class='number details' data-order='#{_(userData.casesWithoutCompleteHousehold).size()}'}>
                <button onClick='$(this).parent().children(\"div\").toggle()' type='button'>#{_(userData.casesWithoutCompleteHousehold).size() or "-"}</button>
                <div style='display:none'>
                #{
                  cases = _(userData.casesWithoutCompleteHousehold).keys()
                  _(cases).map (caseId) ->
                    "<button id='#{caseId}' class='mdl-button mdl-js-button mdl-button--icon mdl-button--primary caseBtn' type='button'>#{caseId}</button>"
                  .join(" ")
                }
                </div>
              </td>

              "
          @$("#usersReport").DataTable
            iDisplayLength: 50

          @$("#usersReport_length").hide()
          @$("#header-cases").click()
          @$("#header-cases").click()
          @hideDetails()

          $('#analysis-spinner').hide()

module.exports = UsersReportView
