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
    else ""

  @createCaseLink = (options) ->
    options.buttonText ?= options.caseID
    buttonText = if(options.iconOnly) then "" else options.buttonText    
    "<button class='mdl-button mdl-js-button mdl-button--icon mdl-button--primary caseBtn' id='#{options.caseID}' data-anchor='#{if options.docId? then options.docId else ""}'>
      <i class=\"mdi #{options.iconText} #{options.buttonClass}\"></i>
      #{if(options.buttonClass == 'incomplete') then "<div class='overlay'>&nbsp;</div>"}
      #{buttonText}</button>"
      

  # Can handle either full case object or just array of caseIDs
  @createCasesLinks = (cases) ->
    _.map(cases, (malariaCase) =>
      caseID = if typeof malariaCase == 'object' then (malariaCase.caseID or malariaCase.MalariaCaseID) else malariaCase
      @createCaseLink 
        caseID: caseID
        iconOnly: false
    ).join("")

  @createDisaggregatableCaseGroup = (cases, text) ->
    text = cases.length unless text?
    "
      <button class='sort-value same-cell-disaggregatable' onClick='$(this).parent().children(\"div\").toggle()'>#{text}</button>
      <div class='cases' style='padding:10px; display:none'>
        #{@createCasesLinks cases}
      </div>
    "

  @createDisaggregatableCaseGroupWithLength = (cases) ->
    text = if cases then cases.length else "-"
    @createDisaggregatableCaseGroup cases, text

  @createDocLinks = (docs) ->
    _.map(docs, (doc) =>
      @createCaseLink
        caseID: doc.MalariaCaseID
        docId: doc._id
    ).join("")

  @createDisaggregatableDocGroup = (text,docs) ->
    "
      <button class='sort-value same-cell-disaggregatable' onClick='$(this).parent().children(\"div\").toggle()'>#{text}</button>
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
    $(".chart_container").height(0.80 * $('#content').height())
    $(".chart_container").width(0.95 * $('#content').width())
    
  @noRecordFound: () ->
    "<div id='noRecordFound'>No Record Found For Date Range</div>"
  
  @roundToTwo: (num) ->    
     +(Math.round(num + "e+2")  + "e-2")

module.exports = HTMLHelpers
