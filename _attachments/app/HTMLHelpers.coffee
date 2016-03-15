class HTMLHelpers

  @createDashboardLinkForResult = (malariaCase,resultType,buttonText, buttonClass = "") ->

    if malariaCase[resultType]?
      unless malariaCase[resultType].complete?
        unless malariaCase[resultType].complete
           buttonClass = "incomplete" unless resultType is "USSD Notification"
#          buttonText = buttonText.replace(".png","Incomplete.png") unless resultType is "USSD Notification"
      @createCaseLink
        caseID: malariaCase.caseID
        docId: malariaCase[resultType]._id
        buttonClass: buttonClass
        buttonText: buttonText
    else ""

  @createCaseLink = (options) ->
#    options.buttonText ?= options.caseID
    "<a href='#show/case/#{options.caseID}#{if options.docId? then "/" + options.docId else ""}'><button class='mdl-button mdl-js-button mdl-button--icon mdl-button--primary'><i class='material-icons #{options.buttonClass}'>#{options.buttonText}</i>
      </button></a>"


  # Can handle either full case object or just array of caseIDs
  @createCasesLinks = (cases) ->
    _.map(cases, (malariaCase) =>
      @createCaseLink  caseID: (malariaCase.caseID or malariaCase)
    ).join("")

  @createDisaggregatableCaseGroup = (cases, text) ->
    text = cases.length unless text?
    "
      <button class='sort-value same-cell-disaggregatable'>#{text}</button>
      <div class='cases' style='padding:10px;display:none'>
        <br/>
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
      <button class='sort-value same-cell-disaggregatable'>#{text}</button>
      <div class='cases' style='display:none'>
        #{@createDocLinks docs}
      </div>
    "

  @createDisaggregatableDocGroupWithLength = (docs) =>
    @createDisaggregatableDocGroup docs.length, docs

module.exports = HTMLHelpers
