_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

DataTables = require( 'datatables.net' )()
Reports = require '../models/Reports'
UserCollection = require '../models/UserCollection'

class UsersReportView extends Backbone.View
  el: "#content"

  events:
    "click .userReports": "showDropDown"

  showDropDown: (e) =>
    $target =  $(e.target).closest('.userReports')
    $target.next(".user-report").slideToggle()
    if ($target.find("i").text()== "play_arrow")
       iconStatus = "details"	
    else
       iconStatus = "play_arrow"
    $target.find("i").text(iconStatus)
	
  render: =>
    @$el.html "
       <div id='dateSelector'></div>
       <h4>How fast are followups occuring?</h4> 
    "
    $('#analysis-spinner').show()
    Users = new UserCollection()
    Users.fetch
      error: (error) -> console.error error
      success: () ->
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
            $('#content').append "
              <div id='users'> 
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
                    <table class='tablesorter mdl-data-table mdl-js-data-table mdl-shadow--2dp' style='' id='usersReport'>
                      <thead>
                        <th class='mdl-data-table__cell--non-numeric'>Name</th>
                        <th class='mdl-data-table__cell--non-numeric'>District</th>
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
            _(userAnalysis.total).each (value,key) ->
              if key is "caseIds"
                ""
              else
                $("tr##{key}").append "<td class= 'a-r'>#{if _(value).isString() then value else _(value).size()}</td>"

            _(userAnalysis.dataByUser).each (userData,user) ->

              $("tr##{userData.userId}").append "
                <td data-type='num' data-sort='#{_(userData.cases).size()}' class='number'><button type='button' onClick='$(this).parent().children(\"div\").toggle()'>#{_(userData.cases).size()}</button>
                  <div style='display:none'>
                  #{
                     cases = _(userData.cases).keys()
                     _(cases).map (caseId) ->
                       "<button type='button'><a href='#show/case/#{caseId}'>#{caseId}</a></button>"
                     .join(" ")
                  }
                  </div>
                </td>

                <td class='number' data-sort='#{_(userData.casesWithoutCompleteFacilityAfter24Hours).size()}'}>
                  <button onClick='$(this).parent().children(\"div\").toggle()' type='button'>#{_(userData.casesWithoutCompleteFacilityAfter24Hours).size() or "-"}</button>
                   <div style='display:none'>
                  #{
                    cases = _(userData.casesWithoutCompleteFacilityAfter24Hours).keys()
                    _(cases).map (caseId) ->
                      "<button type='button'><a href='#show/case/#{caseId}'>#{caseId}</a></button>"
                    .join(" ")
                  }
                  </div>
                </td>


                <td class='number' data-sort='#{_(userData.casesWithoutCompleteFacility).size()}'}>
                  <button onClick='$(this).parent().children(\"div\").toggle()' type='button'>#{_(userData.casesWithoutCompleteFacility).size() or "-"}</button>
                  <div style='display:none'>
                  #{
                    cases = _(userData.casesWithoutCompleteFacility).keys()
                    _(cases).map (caseId) ->
                      "<button type='button'><a href='#show/case/#{caseId}'>#{caseId}</a></button>"
                    .join(" ")
                  }
                  </div>
                </td>

                <td class='number' data-sort='#{_(userData.casesWithoutCompleteHouseholdAfter48Hours).size()}'}>
                  <button onClick='$(this).parent().children(\"div\").toggle()' type='button'>#{_(userData.casesWithoutCompleteHouseholdAfter48Hours).size() or "-"}</button>
                  <div style='display:none'>
                  #{
                    cases = _(userData.casesWithoutCompleteHouseholdAfter48Hours).keys()
                    _(cases).map (caseId) ->
                      "<button type='button'><a href='#show/case/#{caseId}'>#{caseId}</a></button>"
                    .join(" ")
                  }
                  </div>
                </td>

                <td class='number' data-sort='#{_(userData.casesWithoutCompleteHousehold).size()}'}>
                  <button onClick='$(this).parent().children(\"div\").toggle()' type='button'>#{_(userData.casesWithoutCompleteHousehold).size() or "-"}</button>
                  <div style='display:none'>
                  #{
                    cases = _(userData.casesWithoutCompleteHousehold).keys()
                    _(cases).map (caseId) ->
                      "<button type='button'><a href='#show/case/#{caseId}'>#{caseId}</a></button>"
                    .join(" ")
                  }
                  </div>
                </td>


                #{
                  _([
                    "TimeFromSMSToCaseNotification",
                    "TimeFromCaseNotificationToCompleteFacility",
                    "TimeFromFacilityToCompleteHousehold",
                    "TimeFromSMSToCompleteHousehold"
                  ]).map (property) ->
                    propertySeconds = "median#{property}Seconds"
                    "
                      <td data-sort='#{userData[propertySeconds]}' class='number'>
                        #{userData["median#{property}"] or "-"}
                        (#{userData["quartile1#{property}"] or "-"},#{userData["quartile3#{property}"] or "-"})
                      </td>
                    "
                }
                "
            $("#usersReport").dataTable
              aoColumnDefs: [
                "sType": "humanduration"
                "aTargets": [5,6,7,8]
              ]
              aaSorting: [[3,"desc"],[2,"desc"]]
              iDisplayLength: 50
              dom: 'T<"clear">lfrtip'
              tableTools:
                sSwfPath: "js-libraries/copy_csv_xls_pdf.swf"

            $('#analysis-spinner').hide()

module.exports = UsersReportView
