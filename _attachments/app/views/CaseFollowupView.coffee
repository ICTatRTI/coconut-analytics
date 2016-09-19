_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

global.jQuery = require 'jquery'
moment = require 'moment'
Reports = require '../models/Reports'
Case = require '../models/Case'
DataTables = require( 'datatables.net' )()

class CaseFollowupView extends Backbone.View
  events:
    "click .rpt-suboptions": "showDropDown"
    "click button.caseBtn": "showCaseDialog"
    "click button.caseBtnLg": "showCaseDialog"
    "click button#closeDialog": "closeDialog"

  showDropDown: (e) =>
    id = '#'+ e.currentTarget.id + '-section'
    $("#{id}").slideToggle()

  getCases: (options) =>
    reports = new Reports()
    reports.getCases
      startDate: @startDate
      endDate: @endDate
      success: (result) -> 
        options.success(result)
      mostSpecificLocation: Reports.mostSpecificLocationSelected()

  showCaseDialog: (e) ->
    caseID = $(e.target).parent().attr('id') || $(e.target).attr('id')
    scrollTargetID = $(e.target).parent().attr('data-anchor')
    Case.showCaseDialog
      caseID: caseID
      success: ->
          $('html, body').animate({ scrollTop: $("##{scrollTargetID}").position()?.top }, 'slow') if scrollTargetID?
    return false
      

  closeDialog: () ->
    caseDialog.close() if caseDialog.open
    
  render: =>
    @reportOptions = $.extend({},Coconut.router.reportViewOptions)
    district = @reportOptions.district || "ALL"

    @startDate = @reportOptions.startDate || moment(new Date).subtract(7,'days').format("YYYY-MM-DD")
    @endDate = @reportOptions.endDate || moment(new Date).format("YYYY-MM-DD")

    $('#analysis-spinner').show()

    @$el.html "
      <style>
        td.CaseID.mdl-data-table__cell--non-numeric { padding-top: 6px !important;}
        td.legend_gap {width: 10%}
      </style>
      <dialog id='caseDialog'></dialog>
      <div id='dateSelector'></div>
      <div id='summary-dropdown'>
        <div id='unhide-icons'>
		  <!--
		  <span id='cases-drop' class='drop-pointer rpt-suboptions'>
		 	<button class='mdl-button mdl-js-button mdl-button--icon'> 
		 	   <i class='material-icons'>functions</i> 
		     </button>Summary
		  </span>
          -->	  
          <span id='legend-drop' class='drop-pointer rpt-suboptions'>
            <button class='mdl-button mdl-js-button mdl-button--icon'> 
              <i class='material-icons'>dashboard</i> 
            </button>
              Legend
          </span>
        </div>
      </div>	
      <div id='dropdown-container' style='clear: both'>
           <div id='legend-drop-section'>
             <h6>Click button for more details about the case.</h6>
             <table id='followUp'>
               <tbody>
                 <tr>
                    <td>
                      <button class='btn btn-small mdl-button--primary caseid'>caseid</button>&nbsp;
                    </td>
                    <td>Case not followed up after 48 hours.</td>
                    <td class='legend_gap'> </td>
                    <td>
                       <button class='mdl-button mdl-js-button mdl-button--icon mdl-button--primary'>
                          <i class='mdi mdi-home'></i>
                          <div class='overlay'>&nbsp;</div>
                      </button>
                    </td>
                    <td>Household incomplete.</td>
                 </tr>
                 <tr>
                   <td><span style='color:#3F51B5;font-weight:bold'>SHEHIA</span></td>
                   <td>a shehia classified as high risk based on previous data.</td>
                   <td class='legend_gap'> </td>
                   <td>
                     <button class='mdl-button mdl-js-button mdl-button--icon mdl-button--primary'>
                       <i class='mdi mdi-home'></i>
                     </button>
                   </td>
                   <td>Household complete.</td>
                 </tr>
                 <tr>
                   <td>
                     <button class='mdl-button mdl-js-button mdl-button--icon mdl-button--primary'> 
                       <i class='mdi mdi-upload'></i>
                     </button>
                   </td>
                   <td>Notification has been sent.</td>
                   <td class='legend_gap'> </td>
                   <td>
                     <button class='mdl-button mdl-js-button mdl-button--icon mdl-button--accent'>
                       <i class='mdi mdi-home'></i>
                     </button>
                   </td>
                   <td>Index case had no travel history (probable local transmission).</td>
                 </tr>
                 <tr>
                   <td>
                     <button class='mdl-button mdl-js-button mdl-button--icon mdl-button--primary'>
                       <i class='mdi mdi-wifi'></i>
                       <div class='overlay'>&nbsp;</div>
                     </button>
                   </td>
                   <td>Case notification is incomplete.</td>
                   <td class='legend_gap'> </td>
                   <td>
                    <button class='mdl-button mdl-js-button mdl-button--icon mdl-button--primary'>
                       <i class='mdi mdi-account'></i>
                       <div class='overlay'>&nbsp;</div>
                     </button>
                   </td>
                   <td>Household Members incomplete</td>
                 </tr>
                 <tr>
                   <td>
                     <button class='mdl-button mdl-js-button mdl-button--icon mdl-button--primary'>
                       <i class='mdi mdi-wifi'></i>
                     </button>
                   </td>
                   <td>Case notification complete.</td>
                   <td class='legend_gap'> </td>
                   <td>
                      <button class='mdl-button mdl-js-button mdl-button--icon mdl-button--primary'>
                        <i class='mdi mdi-account'></i>
                      </button>
                    </td>
                    <td>Negative malaria result found at household</td>
                 </tr>
                 <tr>
                   <td>
                     <button class='mdl-button mdl-js-button mdl-button--icon mdl-button--primary'>
                       <i class='mdi mdi-hospital'></i>
                       <div class='overlay'>&nbsp;</div>
                     </button>
                   </td>
                   <td>Facility followed up incomplete..</td>
                   <td class='legend_gap'> </td>
                   <td>
                      <button class='mdl-button mdl-js-button mdl-button--icon mdl-button--accent'>
                        <i class='mdi mdi-account'></i>
                      </button>
                    </td>
                    <td>Positive malaria result found at household</td>
                 </tr>
                 <tr>
                   <td>
                     <button class='mdl-button mdl-js-button mdl-button--icon mdl-button mdl-button--primary'>
                       <i class='mdi mdi-hospital'></i>
                     </button>
                   </td>
                   <td>Case followed up to facility.</td>
                   <td class='legend_gap'> </td>
                    <td>
                     <button class='mdl-button mdl-js-button mdl-button--icon mdl-button--accent''>
                       <i class='mdi mdi-account-star'></i>
                     </button>
                   </td>
                    <td>Positive malaria result found at household with no travel history (probable local transmission).</td>  
                 </tr>
                 <tr>
                   <td>
                     <button class='mdl-button mdl-js-button mdl-button--icon mdl-button--accent'>
                       <i class='mdi mdi-hospital'></i>
                     </button>
                   </td>
                   <td>Case not followed up to facility after 24 hours.</td>
                   <td class='legend_gap'> </td>
                   <td></td>
                 </tr>
               </tbody>
             </table>
          </div>
      </div>
      <div id='results' class='result'>
        <table class='summary mdl-data-table mdl-js-data-table mdl-shadow--2dp' id='casefollowup' width='100%'>
          <thead><tr></tr></thead>
          <tbody>
          </tbody>
        </table>
      </div>	
    "
    tableColumns = ["Case ID","Diagnosis Date","Health Facility District","Shehia","USSD Notification"]
    tableColumns = tableColumns.concat Coconut.questions.pluck("_id").sort()
    _.each tableColumns, (text) ->
      #Hack to replace title to differ from Questions title
      if ['USSD Notification','Case Notification'].indexOf(text) >= 0
        colTitle = if(text == 'USSD Notification') then "Case Notification Sent" else "Case Notification Received"
      else
        colTitle = text
       
      $("table.summary thead tr").append "<th class='mdl-data-table__cell--non-numeric'>#{colTitle} <span id='th-#{text.replace(/\s+/g,"")}-count'></span></th>"

    @getCases
      success: (cases) =>
        $('#analysis-spinner').hide()
        if(cases.length > 0)
          _.each cases, (malariaCase) =>
            if (malariaCase.complete())
              if (malariaCase.indexCaseHasTravelHistory())
                householdClass = ''
              else 
                householdClass = 'travel-history-false'
            else
               householdClass = 'incomplete'
               
            if (malariaCase.Facility?)
              if (malariaCase.hasCompleteFacility())
                facilityClass = 'complete'
              else
                if (malariaCase.notCompleteFacilityAfter24Hours())
                  facilityClass = 'not-complete-facility-after-24-hours-true'
                else
                  facilityClass = 'incomplete'
            else
              facilityClass = ''
            console.log(malariaCase.caseID, malariaCase.hasCompleteFacility(), facilityClass)
               
            $("table.summary tbody").append ").
              <tr id='case-#{malariaCase.caseID}'>
                <td class='CaseID mdl-data-table__cell--non-numeric'>
                    <button id= '#{malariaCase.caseID}' class='btn btn-small caseBtn #{if malariaCase.notFollowedUpAfter48Hours() then "mdl-button--primary" } caseid'>#{malariaCase.caseID}</button>
                </td>
                <td class='IndexCaseDiagnosisDate mdl-data-table__cell--non-numeric'>
                  #{malariaCase.indexCaseDiagnosisDate()}
                </td>
                <td class='HealthFacilityDistrict mdl-data-table__cell--non-numeric'>
                  #{
                    if malariaCase["USSD Notification"]?
                      FacilityHierarchy.getDistrict(malariaCase["USSD Notification"].hf)
                    else
                      ""
                  }
                </td>
                <td class='mdl-data-table__cell--non-numeric HealthFacilityDistrict #{if malariaCase.highRiskShehia() then "high-risk-shehia" else ""}'>
                  #{
                    malariaCase.shehia()
                  }
                </td>
                <td class='USSDNotification mdl-data-table__cell--non-numeric'>
                  #{HTMLHelpers.createDashboardLinkForResult(malariaCase,"USSD Notification", "mdi-upload")}
                </td>
                <td class='CaseNotification mdl-data-table__cell--non-numeric'>
                  #{HTMLHelpers.createDashboardLinkForResult(malariaCase,"Case Notification","mdi-wifi")}
                </td>
                <td class='Facility mdl-data-table__cell--non-numeric'>
                  #{HTMLHelpers.createDashboardLinkForResult(malariaCase,"Facility", "mdi-hospital","",facilityClass)}
                </td>
                <td class='Household mdl-data-table__cell--non-numeric'>
                  #{HTMLHelpers.createDashboardLinkForResult(malariaCase,"Household", "mdi-home" , "" ,householdClass)}
                </td>
                <td class='HouseholdMembers mdl-data-table__cell--non-numeric'>
                  #{
                    _.map(malariaCase["Household Members"], (householdMember) =>
                      malariaPositive = householdMember.MalariaTestResult? and (householdMember.MalariaTestResult is "PF" or householdMember.MalariaTestResult is "Mixed")
                      noTravelPositive = householdMember.OvernightTravelinpastmonth isnt "Yes outside Zanzibar" and malariaPositive
                      iconText = "mdi-account"
                      if malariaPositive and noTravelPositive
                        iconText = 'mdi-account-star'
                        buttonClass = "no-travel-malaria-positive"
                      else if malariaPositive
                        iconText ='mdi-account'
                        buttonClass = 'malaria-positive'
                      else
                        buttonClass = ''
                      unless householdMember.complete?
                        unless householdMember.complete
                           buttonClass = "mdl-button--accent"
  #                        buttonText = buttonText.replace(".png","Incomplete.png")
                      HTMLHelpers.createCaseLink
                        caseID: malariaCase.caseID
                        docId: householdMember._id
                        iconOnly: true
                        iconText: iconText
                        buttonClass: buttonClass
                        buttonText: ""
                    ).join("")
                  }
                </td>
              </tr>
            "

          _.each tableColumns, (text) ->
            if (["Diagnosis Date","Health Facility District","Shehia"].indexOf(text) < 0)
              columnId = text.replace(/\s+/g,"")
              $("#th-#{columnId}-count").html('('+ $("td.#{columnId} button").length + ')')

          $("#Cases-Reported-at-Facility").html $("td.CaseID button").length
          $("#Additional-People-Tested").html $("td.HouseholdMembers button").length
          $("#Additional-People-Tested-Positive").html $("td.HouseholdMembers button.malaria-positive").length

          if $("table.summary tr").length > 1
            $("table.summary").tablesorter
              widgets: ['zebra']
              sortList: [[1,1]]

          districtsWithFollowup = {}
          _.each $("table.summary tr"), (row) ->
              row = $(row)
              if row.find("td.USSDNotification button").length > 0
                if row.find("td.CaseNotification button").length is 0
                  if moment().diff(row.find("td.IndexCaseDiagnosisDate").html(),"days") > 2
                    districtsWithFollowup[row.find("td.HealthFacilityDistrict").html()] = 0 unless districtsWithFollowup[row.find("td.HealthFacilityDistrict").html()]?
                    districtsWithFollowup[row.find("td.HealthFacilityDistrict").html()] += 1
          $("#alerts").append "
          <style>
            #alerts,table.alerts{
              font-size: 80% 
            }

          </style>
          The following districts have USSD Notifications that have not been followed up after two days. Recommendation call the DMSO:
            <table class='alerts'>
              <thead>
                <tr>
                  <th>District</th><th>Number of cases</th>
                </tr>
              </thead>
              <tbody>
                #{
                  _.map(districtsWithFollowup, (numberOfCases,district) -> "
                    <tr>
                      <td>#{district}</td>
                      <td>#{numberOfCases}</td>
                    </tr>
                  ").join("")
                }
              </tbody>
            </table>
          "
        
        casefollowuptable = $("#casefollowup").DataTable
          'order': [[1,"desc"]]
          "pagingType": "full_numbers"
          "dom": '<"top"fl>rt<"bottom"ip><"clear">'
          "lengthMenu": [[10, 25, 50, 100, -1], [10, 25, 50, 100, "All"]]
          "iDisplayLength": 50
          "retrieve": true
          "buttons": [
            "csv",'excel','pdf'
            ]
                  
module.exports = CaseFollowupView
