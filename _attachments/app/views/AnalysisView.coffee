_ = require 'underscore'
$ = require 'jquery'
require('jquery-ui')
Backbone = require 'backbone'
Backbone.$  = $

global.jQuery = require 'jquery'
require 'tablesorter'

Reports = require '../models/Reports'
Case = require '../models/Case'

class AnalysisView extends Backbone.View
  el: "#content"

  events:
    "click div.analysis.dropDownBtn": "showDropDown"
    "click #switch-details": "toggleDetails"
    "click #switch-unknown": "toggleGenderUnknown"
    "click button.caseBtn": "showCaseDialog"
    "click button#closeDialog": "closeDialog"
    "change [name=aggregationType]": "updateAnalysis"

  toggleDetails: (e)->
    $(".details").toggle()

  toggleGenderUnknown: (e)->
    $('.gender-unknown').toggle()

  showDropDown: (e) =>
    $target =  $(e.target).closest('.analysis')
    $target.next(".analysis-report").slideToggle()
    if ($target.find("i").hasClass('mdi-play'))
       $target.find("i").switchClass('mdi-play','mdi-menu-down-outline')
    else
       $target.find("i").switchClass('mdi-menu-down-outline','mdi-play')

  showCaseDialog: (e) ->
    caseID = $(e.target).parent().attr('id') || $(e.target).attr('id')
    Case.showCaseDialog
      caseID: caseID
      success: ->
    return false

  closeDialog: () ->
    caseDialog.close() if caseDialog.open

  updateAnalysis: (e) ->
    Coconut.router.reportViewOptions.aggregationLevel = $("[name=aggregationType]:checked").val()
    @render()

  render: =>
    $('#analysis-spinner').show()
    HTMLHelpers.ChangeTitle("Reports: Analysis")
    @$el.html "
      <style>
        td button.same-cell-disaggregatable{ float:right;}
        .mdl-data-table th { padding: 0 6px}
      </style>
      <dialog id='caseDialog'></dialog>
      <div id='dateSelector'></div>
      <div id='analysis'>
      <hr/>
      Aggregation Type:
      <input name='aggregationType' type='radio' #{if Coconut.router.reportViewOptions.aggregationLevel is "District" then "checked='true'" else ""} value='District'>&nbsp; District</input>
      <input name='aggregationType' type='radio' #{if Coconut.router.reportViewOptions.aggregationLevel is "Shehia" then "checked='true'" else ""}  value='Shehia'>&nbsp; Shehia</input>
      <div style='font-style:italic; margin-top: 10px'>Click on arrow button/title to show table.</div>
      <hr/>
      </div>
    "

    options = $.extend({},Coconut.router.reportViewOptions)

    Reports.casesAggregatedForAnalysis
      aggregationLevel:     options.aggregationLevel
      startDate:            options.startDate
      endDate:              options.endDate
      mostSpecificLocation: options.mostSpecificLocation
      error: (error) -> console.error error
      success: (data) =>
        $("#analysis-spinner").hide()
        headings = [
          options.aggregationLevel
          "Cases"
          "Complete household visit"
          "%"
          "Missing Sent Case Notification"
          "Missing Received Case Notification"
          "Complete facility visit"
          "Without complete facility visit (but with case notification)"
          "%"
          "Without complete facility visit within 24 hours"
          "%"
          "Without complete household visit (but with complete facility visit)"
          "%"
          "Without complete household visit within 48 hours"
          "%"
        ]

        $("#analysis").append "
		  <div class='analysis dropDownBtn'>
			  <div class='report-subtitle'><button class='mdl-button mdl-js-button mdl-button--icon'><i class='mdi mdi-play mdi-24px'></i></button>
		  Cases Followed Up<small></small></div></div>
		"
        $("#analysis").append @createTable headings, "
          #{
            _.map(data.followups, (values,location) =>
              "
                <tr>
                  <td class='mdl-data-table__cell--non-numeric'>#{location}</td>
                  <td class='mdl-data-table__cell--non-numeric'>#{HTMLHelpers.createDisaggregatableCaseGroup(values.allCases)}</td>
                  <td class='mdl-data-table__cell--non-numeric'>#{HTMLHelpers.createDisaggregatableCaseGroup(values.casesWithCompleteHouseholdVisit)}</td>
                  <td class='mdl-data-table__cell--non-numeric'>#{HTMLHelpers.formattedPercent(values.casesWithCompleteHouseholdVisit.length/values.allCases.length)}</td>
                  <td class='missingUSSD details mdl-data-table__cell--non-numeric'>#{HTMLHelpers.createDisaggregatableCaseGroup(values.missingUssdNotification)}</td>
                  <td class='mdl-data-table__cell--non-numeric'>#{HTMLHelpers.createDisaggregatableCaseGroup(values.missingCaseNotification)}</td>
                  <td class='details mdl-data-table__cell--non-numeric'>#{HTMLHelpers.createDisaggregatableCaseGroup(values.casesWithCompleteFacilityVisit)}</td>
                  #{
                    withoutcompletefacilityvisitbutwithcasenotification = _.difference(values.casesWithoutCompleteFacilityVisit,values.missingCaseNotification)
                    ""
                  }
                  <td class='mdl-data-table__cell--non-numeric'>#{HTMLHelpers.createDisaggregatableCaseGroup(withoutcompletefacilityvisitbutwithcasenotification)}</td>
                  <td class='mdl-data-table__cell--non-numeric'>#{HTMLHelpers.formattedPercent(withoutcompletefacilityvisitbutwithcasenotification.length/values.allCases.length)}</td>

                  <td class='mdl-data-table__cell--non-numeric'>#{HTMLHelpers.createDisaggregatableCaseGroup(values.noFacilityFollowupWithin24Hours)}</td>
                  <td class='mdl-data-table__cell--non-numeric'>#{HTMLHelpers.formattedPercent(values.noFacilityFollowupWithin24Hours.length/values.allCases.length)}</td>


                  #{
                    withoutcompletehouseholdvisitbutwithcompletefacility = _.difference(values.casesWithoutCompleteHouseholdVisit,values.casesWithCompleteFacilityVisit)
                    ""
                  }

                  <td class='mdl-data-table__cell--non-numeric'>#{HTMLHelpers.createDisaggregatableCaseGroup(withoutcompletehouseholdvisitbutwithcompletefacility)}</td>
                  <td class='mdl-data-table__cell--non-numeric'>#{HTMLHelpers.formattedPercent(withoutcompletehouseholdvisitbutwithcompletefacility.length/values.allCases.length)}</td>


                  <td class='mdl-data-table__cell--non-numeric'>#{HTMLHelpers.createDisaggregatableCaseGroup(values.noHouseholdFollowupWithin48Hours)}</td>
                  <td class='mdl-data-table__cell--non-numeric'>#{HTMLHelpers.formattedPercent(values.noHouseholdFollowupWithin48Hours.length/values.allCases.length)}</td>

                </tr>
              "
            ).join("")
          }
        ", "cases-followed-up"

        _([
          "Complete facility visit"
          "Missing Sent Case Notification"
        ]).each (column) ->
          $("th:contains(#{column})").addClass "details"
        $(".details").hide()


        _.delay ->

          $("table.tablesorter").each (index,table) ->

            _($(table).find("tr:nth-child(1) td").length).times (columnNumber) ->
            #_($(table).find("th").length).times (columnNumber) ->
              return if columnNumber is 0

              maxIndex = null
              maxValue = 0
              columnsTds = $(table).find("td:nth-child(#{columnNumber+1})")
              columnsTds.each (index,td) ->
                return if index is 0
                td = $(td)
                value = parseInt(td.text())
                if value > maxValue
                  maxValue = value
                  maxIndex = index
              $(columnsTds[maxIndex]).addClass "max-value-for-column" if maxIndex
          $(".max-value-for-column ").css("color","#FF4081")
          $(".max-value-for-column ").css("font-weight","bold")
          $(".max-value-for-column button.same-cell-disaggregatable").css("color","#FF4081")

        ,2000

        $("div#cases-followed-up span.toggle-btn").html "
          <label class='mdl-switch mdl-js-switch mdl-js-ripple-effect' for='switch-details'>
            <input type='checkbox' id='switch-details' class='mdl-switch__input'>
            <span class='mdl-switch__label'>Toggle Details</span>
          </label>
        "
        $("#analysis").append "
          </div>
          <hr>
		  <div class='analysis dropDownBtn'>
		  	<div class='report-subtitle'><button class='mdl-button mdl-js-button mdl-button--icon'><i  class='mdi mdi-play mdi-24px'></i></button>
            Index Household and Neighbors</div>
		  </div>
        "
        $("#analysis").append @createTable """
          #{options.aggregationLevel}
          No. of cases followed up
          No. of additional index household members tested
          No. of additional index household members tested positive
          % of index household members tested positive
          % increase in cases found using MCN
          No. of additional neighbor households visited
          No. of additional neighbor household members tested
          No. of additional neighbor household members tested positive
        """.split(/\n/), "
          #{
#            console.log (_.pluck data.passiveCases.ALL.householdMembers, "MalariaCaseID").join("\n")
            _.map(data.passiveCases, (values,location) =>
              "
                <tr>
                  <td class='mdl-data-table__cell--non-numeric'>#{location}</td>
                  <td>#{HTMLHelpers.createDisaggregatableCaseGroup(values.indexCases)}</td>
                  <td>#{HTMLHelpers.createDisaggregatableDocGroup(values.indexCaseHouseholdMembers.length,values.indexCaseHouseholdMembers)}</td>
                  <td>#{HTMLHelpers.createDisaggregatableDocGroup(values.positiveCasesAtIndexHousehold.length,values.positiveCasesAtIndexHousehold)}</td>
                  <td>#{HTMLHelpers.formattedPercent(values.positiveCasesAtIndexHousehold.length / values.indexCaseHouseholdMembers.length)}</td>
                  <td>#{HTMLHelpers.formattedPercent(values.positiveCasesAtIndexHousehold.length / values.indexCases.length)}</td>

                  <td>#{HTMLHelpers.createDisaggregatableDocGroup(values.neighborHouseholds.length,values.neighborHouseholds)}</td>
                  <td>#{HTMLHelpers.createDisaggregatableDocGroup(values.neighborHouseholdMembers.length,values.neighborHouseholdMembers)}</td>
                  <td>#{HTMLHelpers.createDisaggregatableDocGroup(values.positiveCasesAtNeighborHouseholds.length,values.positiveCasesAtNeighborHouseholds)}</td>

                </tr>
              "
            ).join("")
          }
        ",'index-house-neighbors'

        $("#analysis").append "

          <hr>
          <div class='analysis dropDownBtn'>
            <div class='report-subtitle'><button class='mdl-button mdl-js-button mdl-button--icon'><i class='mdi mdi-play mdi-24px'></i></button>
		  		Age: <small>Includes index cases with complete household visits, positive index case household members, and positive neighbor household members</small></div>
          </div>
        "
        $("#analysis").append @createTable "#{options.aggregationLevel}, Total, <5, %, 5<15, %, 15<25, %, >=25, %, Unknown, %".split(/, */), "
          #{
            _.map(data.ages, (values,location) =>
              "
                <tr>
                  <td class='mdl-data-table__cell--non-numeric'>#{location}</td>
                  <td>#{HTMLHelpers.createDisaggregatableDocGroup(data.totalPositiveCases[location].length,data.totalPositiveCases[location])}</td>
                  <td>#{HTMLHelpers.createDisaggregatableDocGroup(values.underFive.length,values.underFive)}</td>
                  <td>#{HTMLHelpers.formattedPercent(values.underFive.length / data.totalPositiveCases[location].length)}</td>
                  <td>#{HTMLHelpers.createDisaggregatableDocGroup(values.fiveToFifteen.length,values.fiveToFifteen)}</td>
                  <td>#{HTMLHelpers.formattedPercent(values.fiveToFifteen.length / data.totalPositiveCases[location].length)}</td>
                  <td>#{HTMLHelpers.createDisaggregatableDocGroup(values.fifteenToTwentyFive.length,values.fifteenToTwentyFive)}</td>
                  <td>#{HTMLHelpers.formattedPercent(values.fifteenToTwentyFive.length / data.totalPositiveCases[location].length)}</td>
                  <td>#{HTMLHelpers.createDisaggregatableDocGroup(values.overTwentyFive.length,values.overTwentyFive)}</td>
                  <td>#{HTMLHelpers.formattedPercent(values.overTwentyFive.length / data.totalPositiveCases[location].length)}</td>
                  <td>#{HTMLHelpers.createDisaggregatableDocGroup(values.unknown.length,values.overTwentyFive)}</td>
                  <td>#{HTMLHelpers.formattedPercent(values.unknown.length / data.totalPositiveCases[location].length)}</td>

                </tr>
              "
            ).join("")
          }
        ", 'age'

        $("#analysis").append "
		  </div>
          <hr>
		  <div class='analysis dropDownBtn'>
		  	<div class='report-subtitle'><button class='mdl-button mdl-js-button mdl-button--icon'><i class='mdi mdi-play mdi-24px'></i></button>
		  		Gender: <small>Includes index cases with complete household visits, positive index case household members, and positive neighbor household members</small>
		  	</div>
		  </div>
        "
        $("#analysis").append @createTable "#{options.aggregationLevel}, Total, Male, %, Female, %, Unknown, %".split(/, */), "
          #{
            _.map(data.gender, (values,location) =>
              "
                <tr>
                  <td class='mdl-data-table__cell--non-numeric'>#{location}</td>
                  <td>#{HTMLHelpers.createDisaggregatableDocGroup(data.totalPositiveCases[location].length,data.totalPositiveCases[location])}</td>
                  <td>#{HTMLHelpers.createDisaggregatableDocGroup(values.male.length,values.male)}</td>
                  <td>#{HTMLHelpers.formattedPercent(values.male.length / data.totalPositiveCases[location].length)}</td>
                  <td>#{HTMLHelpers.createDisaggregatableDocGroup(values.female.length,values.female)}</td>
                  <td>#{HTMLHelpers.formattedPercent(values.female.length / data.totalPositiveCases[location].length)}</td>
                  <td style='display:none' class='gender-unknown'>#{HTMLHelpers.createDisaggregatableDocGroup(values.unknown.length,values.unknown)}</td>

                  <td style='display:none' class='gender-unknown'>#{HTMLHelpers.formattedPercent(values.unknown.length / data.totalPositiveCases[location].length)}</td>
                </tr>
              "
            ).join("")
          }
        ", "gender"
        $("table#gender th:nth-child(7)").addClass("gender-unknown").css("display", "none")
        $("table#gender th:nth-child(8)").addClass("gender-unknown").css("display", "none")

        $("div#gender span.toggle-btn").html "
          <label class='mdl-switch mdl-js-switch mdl-js-ripple-effect' for='switch-unknown'>
            <input type='checkbox' id='switch-unknown' class='mdl-switch__input'>
            <span class='mdl-switch__label'>Toggle Unknown</span>
          </label>
        "

        $("#analysis").append "
          </div>
          <hr>
		  <div class='analysis dropDownBtn'>
		  	<div class='report-subtitle'><button class='mdl-button mdl-js-button mdl-button--icon'><i class='mdi mdi-play mdi-24px'></i></button>
		  		Nets and Spraying: <small>Includes index cases with complete household visits, positive index case household members, and positive neighbor household members</small>
		  	</div>
		  </div>
        "
        $("#analysis").append @createTable "#{options.aggregationLevel}, Positive Cases (index & household), Slept under a net night before diagnosis, %, Household has been sprayed within last #{Coconut.IRSThresholdInMonths} months, %".split(/, */), "
          #{
            _.map(data.netsAndIRS, (values,location) =>
              "
                <tr>
                  <td class='mdl-data-table__cell--non-numeric'>#{location}</td>
                  <td>#{HTMLHelpers.createDisaggregatableDocGroup(data.totalPositiveCases[location].length,data.totalPositiveCases[location])}</td>
                  <td>#{HTMLHelpers.createDisaggregatableDocGroup(values.sleptUnderNet.length,values.sleptUnderNet)}</td>
                  <td>#{HTMLHelpers.formattedPercent(values.sleptUnderNet.length / data.totalPositiveCases[location].length)}</td>
                  <td>#{HTMLHelpers.createDisaggregatableDocGroup(values.recentIRS.length,values.recentIRS)}</td>
                  <td>#{HTMLHelpers.formattedPercent(values.recentIRS.length / data.totalPositiveCases[location].length)}</td>
                </tr>
              "
            ).join("")
          }
        ", 'nets-and-spraying'

        $("#analysis").append "
		  </div>
          <hr>
		  <div class='analysis dropDownBtn'>
		  	<div class='report-subtitle'><button class='mdl-button mdl-js-button mdl-button--icon'><i class='mdi mdi-play mdi-24px'></i></button>
		  		Travel History (within past month): <small>Includes index cases with complete household visits, positive index case household members, and positive neighbor household members</small>
		  	</div>
		  </div>
        "
        $("#analysis").append @createTable """
          #{options.aggregationLevel}
          Positive Cases
          Only outside Zanzibar
          %
          Only within Zanzibar
          %
          Within Zanzibar and outside
          %
          Any Travel outside Zanzibar
          %
          Any Travel
          %
        """.split(/\n/), "
          #{
            _.map data.travel, (values,location) =>
              "
                <tr>
                  <td class='mdl-data-table__cell--non-numeric'>#{location}</td>
                  <td>#{HTMLHelpers.createDisaggregatableDocGroupWithLength(data.totalPositiveCases[location])}</td>
                  #{
                    _.map """
                      Yes outside Zanzibar
                      Yes within Zanzibar
                      Yes within and outside Zanzibar
                    """.split(/\n/), (travelReportedString) =>
                      "
                        <td>#{HTMLHelpers.createDisaggregatableDocGroupWithLength(data.travel[location][travelReportedString])}</td>
                        <td>#{HTMLHelpers.formattedPercent(data.travel[location][travelReportedString].length / data.totalPositiveCases[location].length)}</td>
                      "
                    .join('')
                  }
                  #{
                    anyTravelOutsideZanzibar = _.union(data.travel[location]["Yes outside Zanzibar"], data.travel[location]["Yes within and outside Zanzibar"])
                    ""
                  }
                  <td>#{HTMLHelpers.createDisaggregatableDocGroupWithLength(anyTravelOutsideZanzibar)}</td>
                  <td>#{HTMLHelpers.formattedPercent(anyTravelOutsideZanzibar.length / data.totalPositiveCases[location].length)}</td>
                  <td>#{HTMLHelpers.createDisaggregatableDocGroupWithLength(data.travel[location]["Any travel"])}</td>
                  <td>#{HTMLHelpers.formattedPercent(data.travel[location]["Any travel"].length / data.totalPositiveCases[location].length)}</td>

                </tr>
              "
            .join("")
          }
		  </div>
        "
        , "travel-history-table"

        ###
        This looks nice but breaks copy/paste
        _.each [2..5], (column) ->
          $($("#travel-history-table th")[column]).attr("colspan",2)
        ###

        ###
        # dataTable doesn't help with copy/paste (disaggregated values appear) and sorting isn't sorted
        $("table#cases-followed-up").dataTable
          aaSorting: [[0,"asc"],[6,"desc"],[5,"desc"]]
          iDisplayLength: 50
          dom: 'T<"clear">lfrtip'
          tableTools:
            sSwfPath: "../js-libraries/copy_csv_xls.swf"
        ###

        $("#analysis table").tablesorter
          widgets: ['zebra']
          sortList: [[0,0]]
          textExtraction: (node) ->
           sortValue = $(node).find(".sort-value").text()
           if sortValue != ""
              sortValue
            else
              if $(node).text() is "--"
                "-1"
              else
                $(node).text()

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
      <div id='#{id}' class='analysis-report dropdown-section'>
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

module.exports = AnalysisView
