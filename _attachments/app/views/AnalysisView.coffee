_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

global.jQuery = require 'jquery'
require 'tablesorter'

Reports = require '../models/Reports'

class AnalysisView extends Backbone.View

  events:
    "click div.analysis.dropDownBtn": "showDropDown"

  showDropDown: (e) =>
    $target =  $(e.target).closest('.analysis')
    $target.next(".analysis-report").slideToggle()
    if ($target.find("i").text()== "play_arrow")
       iconStatus = "details"	
    else
       iconStatus = "play_arrow"
    $target.find("i").text(iconStatus)

  render: =>
    @$el.html "
      <style>
        td button.same-cell-disaggregatable{
          float:right;
        }
      </style>

      <div id='analysis'>
      <hr/>
      Aggregation Type:
      <input name='aggregationType' type='radio' #{if Coconut.router.reportViewOptions.aggregationLevel is "District" then "checked='true'" else ""} value='District'>District</input>
      <input name='aggregationType' type='radio' #{if Coconut.router.reportViewOptions.aggregationLevel is "Shehia" then "checked='true'" else ""}  value='Shehia'>Shehia</input>
      <div style='font-style:italic; margin-top: 10px'>Click on arrow button/title to show table.</div>
      <hr/>
      <img id='analysis-spinner' src='images/spinner.gif'/>
      </div>
    "

    options = Coconut.router.reportViewOptions

    Reports.casesAggregatedForAnalysis
      aggregationLevel:     options.aggregationLevel
      startDate:            options.startDate
      endDate:              options.endDate
      mostSpecificLocation: options.mostSpecificLocation
      success: (data) =>
        $("#analysis-spinner").hide()
        headings = [
          options.aggregationLevel
          "Cases"
          "Complete household visit"
          "%"
          "Missing USSD Notification"
          "Missing Case Notification"
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
			  <h4><button class='mdl-button mdl-js-button mdl-button--icon'><i class='material-icons'>play_arrow</i></button>
		  Cases Followed Up<small> <button onClick='$(\".details\").toggle()'>Toggle Details</button></small></h4></div>
		"
        $("#analysis").append @createTable headings, "
          #{
            _.map(data.followups, (values,location) =>
              "
                <tr>
                  <td>#{location}</td>
                  <td>#{@createDisaggregatableCaseGroup(values.allCases)}</td>
                  <td>#{@createDisaggregatableCaseGroup(values.casesWithCompleteHouseholdVisit)}</td>
                  <td>#{@formattedPercent(values.casesWithCompleteHouseholdVisit.length/values.allCases.length)}</td>
                  <td class='missingUSSD details'>#{@createDisaggregatableCaseGroup(values.missingUssdNotification)}</td>
                  <td>#{@createDisaggregatableCaseGroup(values.missingCaseNotification)}</td>
                  <td class='details'>#{@createDisaggregatableCaseGroup(values.casesWithCompleteFacilityVisit)}</td>
                  #{
                    withoutcompletefacilityvisitbutwithcasenotification = _.difference(values.casesWithoutCompleteFacilityVisit,values.missingCaseNotification)
                    ""
                  }
                  <td>#{@createDisaggregatableCaseGroup(withoutcompletefacilityvisitbutwithcasenotification)}</td>
                  <td>#{@formattedPercent(withoutcompletefacilityvisitbutwithcasenotification.length/values.allCases.length)}</td>

                  <td>#{@createDisaggregatableCaseGroup(values.noFacilityFollowupWithin24Hours)}</td>
                  <td>#{@formattedPercent(values.noFacilityFollowupWithin24Hours.length/values.allCases.length)}</td>


                  #{
                    withoutcompletehouseholdvisitbutwithcompletefacility = _.difference(values.casesWithoutCompleteHouseholdVisit,values.casesWithCompleteFacilityVisit)
                    ""
                  }

                  <td>#{@createDisaggregatableCaseGroup(withoutcompletehouseholdvisitbutwithcompletefacility)}</td>
                  <td>#{@formattedPercent(withoutcompletehouseholdvisitbutwithcompletefacility.length/values.allCases.length)}</td>


                  <td>#{@createDisaggregatableCaseGroup(values.noHouseholdFollowupWithin48Hours)}</td>
                  <td>#{@formattedPercent(values.noHouseholdFollowupWithin48Hours.length/values.allCases.length)}</td>

                </tr>
              "
            ).join("")
          }  
        ", "cases-followed-up"

        _([
          "Complete facility visit"
          "Missing USSD Notification"
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


        $("#analysis").append "
          </div>
          <hr>
		  <div class='analysis dropDownBtn'>
		  	<h4><button class='mdl-button mdl-js-button mdl-button--icon'><i  class='material-icons'>play_arrow</i></button>
            Index Household and Neighbors</h4>
		  </div>
        "
        $("#analysis").append @createTable """
          District
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
                  <td>#{location}</td>
                  <td>#{@createDisaggregatableCaseGroup(values.indexCases)}</td>
                  <td>#{@createDisaggregatableDocGroup(values.indexCaseHouseholdMembers.length,values.indexCaseHouseholdMembers)}</td>
                  <td>#{@createDisaggregatableDocGroup(values.positiveCasesAtIndexHousehold.length,values.positiveCasesAtIndexHousehold)}</td>
                  <td>#{@formattedPercent(values.positiveCasesAtIndexHousehold.length / values.indexCaseHouseholdMembers.length)}</td>
                  <td>#{@formattedPercent(values.positiveCasesAtIndexHousehold.length / values.indexCases.length)}</td>

                  <td>#{@createDisaggregatableDocGroup(values.neighborHouseholds.length,values.neighborHouseholds)}</td>
                  <td>#{@createDisaggregatableDocGroup(values.neighborHouseholdMembers.length,values.neighborHouseholdMembers)}</td>
                  <td>#{@createDisaggregatableDocGroup(values.positiveCasesAtNeighborHouseholds.length,values.positiveCasesAtNeighborHouseholds)}</td>

                </tr>
              "
            ).join("")
          }
        ",'index-house-neighbors'

        $("#analysis").append "

          <hr>
          <div class='analysis dropDownBtn'>
            <h4><button class='mdl-button mdl-js-button mdl-button--icon'><i class='material-icons'>play_arrow</i></button>
		  		Age: <small>Includes index cases with complete household visits, positive index case household members, and positive neighbor household members</small></h4>
          </div>
        "
        $("#analysis").append @createTable "District, Total, <5, %, 5<15, %, 15<25, %, >=25, %, Unknown, %".split(/, */), "
          #{
            _.map(data.ages, (values,location) =>
              "
                <tr>
                  <td>#{location}</td>
                  <td>#{@createDisaggregatableDocGroup(data.totalPositiveCases[location].length,data.totalPositiveCases[location])}</td>
                  <td>#{@createDisaggregatableDocGroup(values.underFive.length,values.underFive)}</td>
                  <td>#{@formattedPercent(values.underFive.length / data.totalPositiveCases[location].length)}</td>
                  <td>#{@createDisaggregatableDocGroup(values.fiveToFifteen.length,values.fiveToFifteen)}</td>
                  <td>#{@formattedPercent(values.fiveToFifteen.length / data.totalPositiveCases[location].length)}</td>
                  <td>#{@createDisaggregatableDocGroup(values.fifteenToTwentyFive.length,values.fifteenToTwentyFive)}</td>
                  <td>#{@formattedPercent(values.fifteenToTwentyFive.length / data.totalPositiveCases[location].length)}</td>
                  <td>#{@createDisaggregatableDocGroup(values.overTwentyFive.length,values.overTwentyFive)}</td>
                  <td>#{@formattedPercent(values.overTwentyFive.length / data.totalPositiveCases[location].length)}</td>
                  <td>#{@createDisaggregatableDocGroup(values.unknown.length,values.overTwentyFive)}</td>
                  <td>#{@formattedPercent(values.unknown.length / data.totalPositiveCases[location].length)}</td>

                </tr>
              "
            ).join("")
          }
        ", 'age'

        $("#analysis").append "
		  </div>
          <hr>
		  <div class='analysis dropDownBtn'>
		  	<h4><button class='mdl-button mdl-js-button mdl-button--icon'><i class='material-icons'>play_arrow</i></button>
		  		Gender: <small>Includes index cases with complete household visits, positive index case household members, and positive neighbor household members</small> 
				<button type='button'' onclick=\"$('.gender-unknown').toggle()\">Toggle Unknown</button>
		  	</h4>
		  </div>
        "
        $("#analysis").append @createTable "District, Total, Male, %, Female, %, Unknown, %".split(/, */), "
          #{
            _.map(data.gender, (values,location) =>
              "
                <tr>
                  <td>#{location}</td>
                  <td>#{@createDisaggregatableDocGroup(data.totalPositiveCases[location].length,data.totalPositiveCases[location])}</td>
                  <td>#{@createDisaggregatableDocGroup(values.male.length,values.male)}</td>
                  <td>#{@formattedPercent(values.male.length / data.totalPositiveCases[location].length)}</td>
                  <td>#{@createDisaggregatableDocGroup(values.female.length,values.female)}</td>
                  <td>#{@formattedPercent(values.female.length / data.totalPositiveCases[location].length)}</td>
                  <td style='display:none' class='gender-unknown'>#{@createDisaggregatableDocGroup(values.unknown.length,values.unknown)}</td>

                  <td style='display:none' class='gender-unknown'>#{@formattedPercent(values.unknown.length / data.totalPositiveCases[location].length)}</td>
                </tr>
              "
            ).join("")
          }
        ", "gender"
        $("table#gender th:nth-child(7)").addClass("gender-unknown").css("display", "none")
        $("table#gender th:nth-child(8)").addClass("gender-unknown").css("display", "none")

        $("#analysis").append "
          </div>
          <hr>
		  <div class='analysis dropDownBtn'>
		  	<h4><button class='mdl-button mdl-js-button mdl-button--icon'><i class='material-icons'>play_arrow</i></button>
		  		Nets and Spraying: <small>Includes index cases with complete household visits, positive index case household members, and positive neighbor household members</small>
		  	</h4>
		  </div>
        "
        $("#analysis").append @createTable "District, Positive Cases (index & household), Slept under a net night before diagnosis, %, Household has been sprayed within last #{Coconut.IRSThresholdInMonths} months, %".split(/, */), "
          #{
            _.map(data.netsAndIRS, (values,location) =>
              "
                <tr>
                  <td>#{location}</td>
                  <td>#{@createDisaggregatableDocGroup(data.totalPositiveCases[location].length,data.totalPositiveCases[location])}</td>
                  <td>#{@createDisaggregatableDocGroup(values.sleptUnderNet.length,values.sleptUnderNet)}</td>
                  <td>#{@formattedPercent(values.sleptUnderNet.length / data.totalPositiveCases[location].length)}</td>
                  <td>#{@createDisaggregatableDocGroup(values.recentIRS.length,values.recentIRS)}</td>
                  <td>#{@formattedPercent(values.recentIRS.length / data.totalPositiveCases[location].length)}</td>
                </tr>
              "
            ).join("")
          }
        ", 'nets-and-spraying'

        $("#analysis").append "
		  </div>
          <hr>
		  <div class='analysis dropDownBtn'>
		  	<h4><button class='mdl-button mdl-js-button mdl-button--icon'><i class='material-icons'>play_arrow</i></button>
		  		Travel History (within past month): <small>Includes index cases with complete household visits, positive index case household members, and positive neighbor household members</small>
		  	</h4>
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
                  <td>#{location}</td>
                  <td>#{@createDisaggregatableDocGroupWithLength(data.totalPositiveCases[location])}</td>
                  #{
                    _.map """
                      Yes outside Zanzibar
                      Yes within Zanzibar
                      Yes within and outside Zanzibar
                    """.split(/\n/), (travelReportedString) =>
                      "
                        <td>#{@createDisaggregatableDocGroupWithLength(data.travel[location][travelReportedString])}</td>
                        <td>#{@formattedPercent(data.travel[location][travelReportedString].length / data.totalPositiveCases[location].length)}</td>
                      "
                    .join('')
                  }
                  #{
                    anyTravelOutsideZanzibar = _.union(data.travel[location]["Yes outside Zanzibar"], data.travel[location]["Yes within and outside Zanzibar"])
                    ""
                  }
                  <td>#{@createDisaggregatableDocGroupWithLength(anyTravelOutsideZanzibar)}</td>
                  <td>#{@formattedPercent(anyTravelOutsideZanzibar.length / data.totalPositiveCases[location].length)}</td>
                  <td>#{@createDisaggregatableDocGroupWithLength(data.travel[location]["Any travel"])}</td>
                  <td>#{@formattedPercent(data.travel[location]["Any travel"].length / data.totalPositiveCases[location].length)}</td>

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
        $("#analysis table").dataTable
          aaSorting: [[0,"asc"],[6,"desc"],[5,"desc"]]
          iDisplayLength: 50
          dom: 'T<"clear">lfrtip'
          tableTools:
            sSwfPath: "js-libraries/copy_csv_xls.swf"
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



  createDashboardLinkForResult: (malariaCase,resultType,buttonText, buttonClass = "") ->

    if malariaCase[resultType]?
      unless malariaCase[resultType].complete?
        unless malariaCase[resultType].complete
          buttonText = buttonText.replace(".png","Incomplete.png") unless resultType is "USSD Notification"
      @createCaseLink
        caseID: malariaCase.caseID
        docId: malariaCase[resultType]._id
        buttonClass: buttonClass
        buttonText: buttonText
    else ""

  createCaseLink: (options) ->
    options.buttonText ?= options.caseID
    "<a href='#show/case/#{options.caseID}#{if options.docId? then "/" + options.docId else ""}'><button class='#{options.buttonClass}'>#{options.buttonText}</button></a>"

  # Can handle either full case object or just array of caseIDs
  createCasesLinks: (cases) ->
    _.map(cases, (malariaCase) =>
      @createCaseLink  caseID: (malariaCase.caseID or malariaCase)
    ).join("")

  createDisaggregatableCaseGroup: (cases, text) ->
    text = cases.length unless text?
    "
      <button class='sort-value same-cell-disaggregatable'>#{text}</button>
      <div class='cases' style='padding:10px;display:none'>
        <br/>
        #{@createCasesLinks cases}
      </div>
    "

  createDisaggregatableCaseGroupWithLength: (cases) ->
    text = if cases then cases.length else "-"
    @createDisaggregatableCaseGroup cases, text

  createDocLinks: (docs) ->
    _.map(docs, (doc) =>
      @createCaseLink
        caseID: doc.MalariaCaseID
        docId: doc._id
    ).join("")

  createDisaggregatableDocGroup: (text,docs) ->
    "
      <button class='sort-value same-cell-disaggregatable'>#{text}</button>
      <div class='cases' style='display:none'>
        #{@createDocLinks docs}
      </div>
    "

  createDisaggregatableDocGroupWithLength: (docs) =>
    @createDisaggregatableDocGroup docs.length, docs


  formattedPercent: (number) ->
    percent = (number * 100).toFixed(0)
    if isNaN(percent) then "--" else "#{percent}%"

  createTable: (headerValues, rows, id, colspan = 1) ->
   "
      <div id='#{id}' class='analysis-report dropdown-section'>
		<div style='font-style:italic'>Click on a column heading to sort.</div>
        <table #{if id? then "id=#{id}" else ""} class='tablesorter'>
          <thead>
            <tr>
            #{
              _.map(headerValues, (header) ->
                "<th class='header' colspan='#{colspan}'>#{header}</th>"
              ).join("")
            }
            </tr>
          </thead>
          <tbody>
            #{rows}
          </tbody>
        </table>
      </div>	
    "

module.exports = AnalysisView
