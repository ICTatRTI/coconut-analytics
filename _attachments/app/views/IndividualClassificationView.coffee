_ = require 'underscore'
$ = require 'jquery'
require('jquery-ui')
Backbone = require 'backbone'
Backbone.$  = $

global.jQuery = require 'jquery'
require 'tablesorter'

Reports = require '../models/Reports'
CaseView = require './CaseView'
UserCollection = require '../models/UserCollection'

class IndividualClassificationView extends Backbone.View
  el: "#content"

  events:
    "click div.classification.dropDownBtn": "showDropDown"
    "click #switch-details": "toggleDetails"
    "click button.caseBtn": "showCaseDialog"
    "click button#closeDialog": "closeDialog"

  toggleDetails: (e) =>
    @$(".details").toggle()

  showDropDown: (e) =>
    target =  @$(e.target).closest('.classification')
    target.next(".classification-report").slideToggle()
    target.find("i").toggleClass("mdi-play mdi-menu-down-outline")

  showCaseDialog: (e) =>
    caseID = @$(e.target).parent().attr('id') || $(e.target).attr('id')
    CaseView.showCaseDialog
      caseID: caseID
      success: ->
    return false

  closeDialog: () ->
    caseDialog.close() if caseDialog.open

  render: =>
    @options = $.extend({},Coconut.router.reportViewOptions)
    @categories = [
      "Indigenous"
      "Imported"
      "Introduced"
      "Induced"
      "Relapsing"
    ]

    $('#classification-spinner').show()
    HTMLHelpers.ChangeTitle("Reports: Individual Classification")
    @$el.html "
      <style>
        td button.same-cell-disaggregatable{ float:right;}
        .mdl-data-table th { padding: 0 6px}
        #classification th.mdl-data-table__cell--non-numeric.mdl-data-table__cell--non-numeric { text-align: right }
      </style>
      <dialog id='caseDialog'></dialog>
      <div id='dateSelector'></div>
      <div id='classification'>
      </div>
      <div id='messages'>
      </div>

    "
    @addTables()

  addTables: =>
    Coconut.database.query "positiveIndividualsByDiagnosisDate",
      startkey: @options.startDate
      endkey: @options.endDate
    .then (result) =>
      @positiveIndividualsByDiagnosisDate = result.rows

      @all()

      @loadCaseSummaryData().then =>

        @district()
        #@zone()
        @officer()

        @$('.dropdown-section').hide()

  dropDownButton: (name) =>
    @$("#classification").append "
      <div class='classification dropDownBtn'>
        <div class='report-subtitle'>
          <button class='mdl-button mdl-js-button mdl-button--icon'>
            <i class='mdi mdi-play mdi-24px'></i>
          </button>
          #{name}
        </div>
      </div>
    "

  all: =>

    $("#classification-spinner").hide()

    aggregated = {}

    for category in @categories
      aggregated[category] = []

    for row in @positiveIndividualsByDiagnosisDate
      aggregated[row.value[1]].push row.value[0]

    @dropDownButton("All")

    @$("#classification").append @createTable @categories, "
      <tr>
      #{
        (for category in @categories
          "
            <td class='mdl-data-table__cell--non-numeric'>#{HTMLHelpers.createDisaggregatableCaseGroup(aggregated[category])}</td>
          "
        ).join("")
      }
      </tr>
    ", "all-table"

    # This is for MDL switch
    componentHandler.upgradeAllRegistered()

  loadCaseSummaryData: =>
    caseIds = _(@positiveIndividualsByDiagnosisDate).map (row) =>  row.value[0]
    caseDocIdsInReportingDatabase = _(caseIds).map (caseId) => "case_summary_#{caseId}"
    @districtForCase = {}
    @zoneForCase = {}
    @officerForCase = {}

    Coconut.reportingDatabase.allDocs
      keys: caseDocIdsInReportingDatabase
      include_docs: true
    .then (result) =>
      missingSummaries = [] # Not sure why this happens, as summaries should be created automatically by the cron job, but this will detect them and regenerate them
      for row in result.rows
        if row.doc
          malariaCase = row.doc
          #console.log row
          district = malariaCase["District"]
          @districtForCase[malariaCase["Malaria Case ID"]] = district

          #@zoneForCase[malariaCase["Malaria Case ID"]] = GeoHierarchy.getZoneForDistrict(district)

          @officerForCase[malariaCase["Malaria Case ID"]] = Coconut.nameByUsername[(malariaCase["Household: User"])]
        else
          missingSummaries.push row.key.replace(/case_summary_/,"")

      if missingSummaries.length > 0
        console.log missingSummaries
        await Case.updateSummaryForCases({caseIDs: missingSummaries})
        return @loadCaseSummaryData()



  district: => 

      aggregated = {}

      for category in @categories
        aggregated[category] = {}
        for district in GeoHierarchy.allDistricts()
          aggregated[category][district] = []

      for row in @positiveIndividualsByDiagnosisDate
        category = row.value[1]
        district = @districtForCase[row.value[0]]

        console.log row.value[0]
        console.log district

        unless district
          @$("#messages").append "Can't find district for <a href='#show/case/#{row.value[0]}'>#{row.value[0]}</a><br/>"
          continue

        aggregated[category][district].push row.value[0]

      @dropDownButton("District")

      @$("#classification").append @createTable ["District"].concat(@categories), "
        #{
          (for district in GeoHierarchy.allDistricts()
            "
            <tr>
							<td class='mdl-data-table__cell--non-numeric'>#{district}</td>
	
            #{
              (for category in @categories
                "
                  <td class='mdl-data-table__cell--non-numeric'>#{HTMLHelpers.createDisaggregatableCaseGroup(aggregated[category][district])}</td>
                "
              ).join("")
            }
            </tr>
            "
          ).join("")
        }
      ", "district-table"

      # This is for MDL switch
      componentHandler.upgradeAllRegistered()

 
  zone: =>
    aggregated = {}

    for category in @categories
      aggregated[category] = {}
      for zone in ["Unguja", "Pemba"]
        aggregated[category][zone] = []

    for row in @positiveIndividualsByDiagnosisDate
      category = row.value[1]
      zone = @zoneForCase[row.value[0]]

      console.log @zoneForCase
      console.log row.value[0]

      aggregated[category][zone].push row.value[0]

    @dropDownButton("Zone")

    @$("#classification").append @createTable ["Zone"].concat(@categories), "
      #{
        (for zone in ["Unguja","Pemba"]
          "
          <tr>
            <td class='mdl-data-table__cell--non-numeric'>#{zone}</td>

          #{
            (for category in @categories
              "
                <td class='mdl-data-table__cell--non-numeric'>#{HTMLHelpers.createDisaggregatableCaseGroup(aggregated[category][zone])}</td>
              "
            ).join("")
          }
          </tr>
          "
        ).join("")
      }
    ", "zone-table"

    # This is for MDL switch
    componentHandler.upgradeAllRegistered()

  officer: => 
    aggregated = {}
    officers = []

    for category in @categories
      aggregated[category] = {}
      for caseId, officer of @officerForCase
        officers.push officer
        aggregated[category][officer] = []

    officers = _(officers).unique()

    for row in @positiveIndividualsByDiagnosisDate
      category = row.value[1]
      officer = @officerForCase[row.value[0]]

      aggregated[category][officer].push row.value[0]

    @dropDownButton("Officer")

    @$("#classification").append @createTable ["Officer"].concat(@categories), "
      #{
        (for officer in officers
          "
          <tr>
            <td class='mdl-data-table__cell--non-numeric'>#{officer}</td>

          #{
            (for category in @categories
              "
                <td class='mdl-data-table__cell--non-numeric'>#{HTMLHelpers.createDisaggregatableCaseGroup(aggregated[category][officer])}</td>
              "
            ).join("")
          }
          </tr>
          "
        ).join("")
      }
    ", "officer-table"

    # This is for MDL switch
    componentHandler.upgradeAllRegistered()

  createDashboardLinkForResult: (malariaCase,resultType,buttonText, buttonClass = "") ->
    if malariaCase[resultType]?
      unless malariaCase[resultType].complete?
        unless malariaCase[resultType].complete
          buttonText = buttonText.replace(".png","Incomplete.png") unless resultType is "USSD Notification"
      HTMLHelpers.createCaseLink
        caseID: malariaCase.caseID
        docId: malariaCase[resultType]._id
        buttonClass: buttonClass
        buttonText: buttonText
    else ""

  createTable: (headerValues, rows, id, colspan = 1) ->
   "
      <div id='#{id}' class='classification-report dropdown-section'>
      <div class='scroll-div'>
       <div style='font-style:italic; padding-right: 30px'>Click on a column heading to sort. <span class='toggle-btn f-right'></span> </div>
        <table #{if id? then "id=#{id}" else ""} class='tablesorter mdl-data-table mdl-js-data-table mdl-shadow--2dp'>
          <thead>
            <tr>
            #{
              _.map(headerValues, (header) ->
                "<th class='header mdl-data-table__cell--non-numeric' colspan='#{colspan}'>#{header}</th>"
              ).join("")
            }
            </tr>
          </thead>
          <tbody>
            #{rows}
          </tbody>
        </table>
       </div>
      </div>
    "

module.exports = IndividualClassificationView
