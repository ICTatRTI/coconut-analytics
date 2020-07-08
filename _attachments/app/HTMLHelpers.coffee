global.copy = require('copy-text-to-clipboard');

SetsView = require './views/SetsView'
CasesTabulatorView = require './views/CasesTabulatorView'

global.disaggregateSet = (element) ->
  targetElement = $(element)
  cases = targetElement.siblings(".cases").children().map((i,element) => element.id).toArray()

  inTabulator = targetElement.closest(".tabulator").length isnt 0


  rowName = if inTabulator
    targetElement.closest("div[role=row]").children().first().text()
  else
    targetElement.closest("tr").children().first().text()

  headerName = if inTabulator
    tableElement = targetElement.closest(".tabulator-cell")
    targetElement.closest('.tabulator').find('.tabulator-headers').children().eq(tableElement.index()).text()
  else
    tableElement = targetElement.closest("td")
    targetElement.closest('table').find('th').eq(tableElement.index()).text()

  CasesTabulatorView.showDialog
    cases: cases

  #SetsView.showDialog
  #  name: "#{rowName} #{headerName}"
  #  cases: cases

class HTMLHelpers

  @createDashboardLinkForResult = (malariaCase,resultType,iconText, buttonText = "", buttonClass = "") ->
    if malariaCase[resultType]?
      unless malariaCase[resultType].complete?
#        unless malariaCase[resultType].complete
           buttonClass = "incomplete" unless (resultType is "USSD Notification" or buttonClass is "not-complete-facility-after-24-hours-true")
#          buttonText = buttonText.replace(".png","Incomplete.png") unless resultType is "USSD Notification"
      @createCaseLink
        caseID: malariaCase.caseID
        docId: malariaCase[resultType]._id
        buttonClass: buttonClass
        iconText: iconText
        buttonText: buttonText
        iconOnly: true
        caseBtn: 'caseBtnLg'
    else ""

  @createCaseLink = (options) ->
    options.buttonText ?= options.caseID
    buttonText = if(options.iconOnly) then "" else options.buttonText
    "<button class='mdl-button mdl-js-button mdl-button--icon mdl-button--primary #{options.caseBtn}' id='#{options.caseID}' data-anchor='#{if options.docId? then options.docId else ""}'>
      <i class=\"mdi #{options.iconText} #{options.buttonClass}\"></i>
      #{if(options.iconOnly && options.buttonClass is 'incomplete') then "<div class='overlay'>&nbsp;</div>" else ""}
      #{buttonText}</button>"


  # Can handle either full case object or just array of caseIDs
  @createCasesLinks = (cases) ->
    _.map(@caseIds(cases), (caseID) =>
      @createCaseLink
        caseID: caseID
        iconOnly: false
        buttonClass: ''
        iconText: ''
        caseBtn: 'caseBtn'
    ).join("")

  @caseIds = (cases) ->
    _.map cases, (malariaCase) =>
      if typeof malariaCase == 'object' then (malariaCase.caseID or malariaCase.MalariaCaseID) else malariaCase

  @createDisaggregatableCaseGroup = (cases, text) ->
    text = cases.length unless text?
    "
      <button class='mdl-button mdl-js-button mdl-button--raised sort-value same-cell-disaggregatable' onClick='console.log(this);disaggregateSet(this)'>#{text}</button>
      <div class='cases' style='padding:10px; display:none'>
        #{@createCasesLinks cases}
        <button onClick='copy(\"#{@caseIds(cases).join("\\n")}\")'>copy</button>
      </div>
    "
    ###
    "
      <button class='mdl-button mdl-js-button mdl-button--raised sort-value same-cell-disaggregatable' onClick='$(this).parent().children(\"div\").toggle()'>#{text}</button>
      <div class='cases' style='padding:10px; display:none'>
        #{@createCasesLinks cases}
        <button onClick='copy(\"#{@caseIds(cases).join("\\n")}\")'>copy</button>
      </div>
    "
    ###

  @createDisaggregatableCaseGroupWithLength = (cases) ->
    text = if cases then cases.length or _(cases).size() else "-"
    @createDisaggregatableCaseGroup cases, text

  @createDocLinks = (docs) ->
    _.map(docs, (doc) =>
      @createCaseLink
        caseID: doc.MalariaCaseID
        docId: doc._id
        iconOnly: false
        buttonClass: ''
        iconText: ''
        caseBtn: 'caseBtn'
    ).join("")

  @createDisaggregatableDocGroup = (text,docs) ->
    ###
    "
      <button class='mdl-button mdl-js-button mdl-button--raised sort-value same-cell-disaggregatable' onClick='$(this).parent().children(\"div\").toggle()'>#{text}</button>
      <div class='cases' style='padding:10px;text-align: left; display:none'>
        #{@createDocLinks docs}
      </div>
    "
    ###
    "
      <button class='mdl-button mdl-js-button mdl-button--raised sort-value same-cell-disaggregatable' onClick='console.log(this);disaggregateSet(this)'>#{text}</button>
      <div class='cases' style='padding:10px;text-align: left; display:none'>
        #{@createDocLinks docs}
      </div>
    "

  @createDisaggregatableDocGroupWithLength = (docs) =>
    @createDisaggregatableDocGroup docs.length, docs

  @formattedPercent: (number) ->
    percent = (number * 100).toFixed(0)
    if isNaN(percent) then "--" else "#{percent}%"

  @numberWithCommas: (num) ->
     return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",")

  @resizeChartContainer: () ->
    $(".chart_container").height(0.8 * $('#content').height())
    $(".chart_container").width(0.95 * $('#content').width())

  @noRecordFound: () ->
    "<div id='noRecordFound'>No Record Found For Date Range</div>"

  @roundToTwo: (num) ->
     +(Math.round(num + "e+2")  + "e-2")

  #show the background (header and drawer menu) if user is authenticated.
  @showBackground: ->
    $('header.coconut-header').show()
    $('div.coconut-drawer').show()

  #Change Header Title
  @ChangeTitle: (title) ->
    $('#layout-title').html(title)

module.exports = HTMLHelpers
