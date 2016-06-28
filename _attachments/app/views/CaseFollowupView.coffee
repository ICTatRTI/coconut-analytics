_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

global.jQuery = require 'jquery'
require 'tablesorter'
moment = require 'moment'
Reports = require '../models/Reports'
Case = require '../models/Case'

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
    Coconut.case = new Case
      caseID: caseID
    Coconut.case.fetch
      success: ->
        Case.createCaseView
          case: Coconut.case
          success: ->
            $('#caseDialog').html(Coconut.caseview)            
            if (Env.is_chrome)
               caseDialog.showModal()
            else
               caseDialog.show()
               
            $('html, body').animate({ scrollTop: $("h4##{scrollTargetID}").position().top }, 'slow') if scrollTargetID?
  
  closeDialog: () ->
    caseDialog.close()
    
  render: =>
    @reportOptions = $.extend({},Coconut.router.reportViewOptions)
    district = @reportOptions.district || "ALL"

    @startDate = @reportOptions.startDate || moment(new Date).subtract(7,'days').format("YYYY-MM-DD")
    @endDate = @reportOptions.endDate || moment(new Date).format("YYYY-MM-DD")

    $('#analysis-spinner').show()

    @$el.html "
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
      <div id='dropdown-container'>
           <div id='legend-drop-section'>
             <h4>Legends</h4>	
             <h6>Click on a button for more details about the case.</h6>
             <button class='mdl-button mdl-js-button mdl-button--icon mdl-button--accent'><i class='material-icons'>account_circle</i></button> - Positive malaria result found at household<br />
             <button class='mdl-button mdl-js-button mdl-button--icon'><i class='material-icons  c_orange'>account_circle</i></button> - Positive malaria result found at household with no travel history (probable local transmission). <br />
             <button class='mdl-button mdl-js-button mdl-button--icon mdl-button--primary'><i class='material-icons'>home</i></button> - Index case had travel history.<br />
             <button class='mdl-button mdl-js-button mdl-button--icon'><i class='material-icons  travel-history-false'>home</i></button> - Index case had no travel history (probable local transmission).<br />
             <button class='mdl-button mdl-js-button mdl-button--icon mdl-button--accent'><i class='material-icons'>home</i></button> - Household incomplete.<br />
             <button class='mdl-button mdl-js-button mdl-button--icon mdl-button--accent'><i class='material-icons'>error_outline</i></button> - Case not followed up to facility after 24 hours. <br />
             <button class='mdl-button mdl-js-button mdl-button--icon mdl-button--accent'><i class='material-icons'>tap_and_play</i></button> - Case notification incomplete.<br />
             <span style='font-size:75%;color:#3F51B5;font-weight:bold'>SHEHIA</span> - is a shehia classified as high risk based on previous data. <br />
             <button class='btn btn-small  mdl-button--primary'>caseid</button> - Case not followed up after 48 hours. <br />
          </div>
      </div>
      <div id='results' class='result'>
        <table class='summary tablesorter mdl-data-table mdl-js-data-table mdl-shadow--2dp'>
          <thead><tr></tr></thead>
          <tbody>
          </tbody>
        </table>
      </div>	
    "
    tableColumns = ["Case ID","Diagnosis Date","Health Facility District","Shehia","USSD Notification"]

    Coconut.database.query "zanzibar/byCollection",
      key: "question"
    .catch (error) -> console.error error
    .then (result) ->
      tableColumns = tableColumns.concat _(result.rows).pluck("id")
      
      _.each tableColumns, (text) -> 
        $("table.summary thead tr").append "<th class='mdl-data-table__cell--non-numeric'>#{if text == "USSD Notification" then "Notification" else text} <span id='th-#{text.replace(/\s+/g,"")}-count'></span></th>"

    @getCases
      success: (cases) =>
        $('#analysis-spinner').hide()
        if(cases.length > 0)
          _.each cases, (malariaCase) =>

            $("table.summary tbody").append "
              <tr id='case-#{malariaCase.caseID}'>
                <td class='CaseID mdl-data-table__cell--non-numeric'>
                    <button id= '#{malariaCase.caseID}' class='caseBtnLg btn btn-small not-followed-up-after-48-hours-#{malariaCase.notFollowedUpAfter48Hours()}'>#{malariaCase.caseID}</button>
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
                  #{HTMLHelpers.createDashboardLinkForResult(malariaCase,"USSD Notification", "open_in_browser")}
                </td>
                <td class='CaseNotification mdl-data-table__cell--non-numeric'>
                  #{HTMLHelpers.createDashboardLinkForResult(malariaCase,"Case Notification","tap_and_play")}
                </td>
                <td class='Facility mdl-data-table__cell--non-numeric'>
                  #{HTMLHelpers.createDashboardLinkForResult(malariaCase,"Facility", "error_outline","not-complete-facility-after-24-hours-#{malariaCase.notCompleteFacilityAfter24Hours()}")}
                </td>
                <td class='Household mdl-data-table__cell--non-numeric'>
                  #{HTMLHelpers.createDashboardLinkForResult(malariaCase,"Household", "home","travel-history-#{malariaCase.indexCaseHasTravelHistory()}")}
                </td>
                <td class='HouseholdMembers mdl-data-table__cell--non-numeric'>
                  #{
                    _.map(malariaCase["Household Members"], (householdMember) =>
                      malariaPositive = householdMember.MalariaTestResult? and (householdMember.MalariaTestResult is "PF" or householdMember.MalariaTestResult is "Mixed")
                      noTravelPositive = householdMember.OvernightTravelinpastmonth isnt "Yes outside Zanzibar" and malariaPositive
                      buttonText = "account_circle"
                      unless householdMember.complete?
                        unless householdMember.complete
                           buttonClass = "mdl-button--accent"
  #                        buttonText = buttonText.replace(".png","Incomplete.png")
                      HTMLHelpers.createCaseLink
                        caseID: malariaCase.caseID
                        docId: householdMember._id
                        iconOnly: true
                        buttonClass: if malariaPositive and noTravelPositive
                         "no-travel-malaria-positive"
                        else if malariaPositive
                         "malaria-positive"
                        else ""
                        buttonText: buttonText
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
        else
          @$el.append "<div><center>No result found...</center></div><hr />"
          
module.exports = CaseFollowupView
