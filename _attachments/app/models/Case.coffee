_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
moment = require 'moment'
Question = require './Question'
Dhis2 = require './Dhis2'
CONST = require "../Constants"
humanize = require 'underscore.string/humanize'
titleize = require 'underscore.string/titleize'

class Case
  constructor: (options) ->
    @caseID = options?.caseID
    @loadFromResultDocs(options.results) if options?.results

  loadFromResultDocs: (resultDocs) ->
    @caseResults = resultDocs
    @questions = []
    this["Household Members"] = []
    this["Neighbor Households"] = []

    userRequiresDeidentification = (Coconut.currentUser?.hasRole("reports") or Coconut.currentUser is null) and not Coconut.currentUser?.hasRole("admin")

    _.each resultDocs, (resultDoc) =>
      resultDoc = resultDoc.toJSON() if resultDoc.toJSON?

      if userRequiresDeidentification
        _.each resultDoc, (value,key) ->
          resultDoc[key] = b64_sha1(value) if value? and _.contains(Coconut.identifyingAttributes, key)

      if resultDoc.question
        @caseID ?= resultDoc["MalariaCaseID"]
        throw "Inconsistent Case ID" if @caseID isnt resultDoc["MalariaCaseID"]
        @questions.push resultDoc.question
        if resultDoc.question is "Household Members"
          this["Household Members"].push resultDoc
        else if resultDoc.question is "Household" and resultDoc.Reasonforvisitinghousehold is "Index Case Neighbors"
          this["Neighbor Households"].push resultDoc
        else
          if resultDoc.question is "Facility"
            dateOfPositiveResults = resultDoc.DateofPositiveResults
            if dateOfPositiveResults?
              dayMonthYearMatch = dateOfPositiveResults.match(/^(\d\d).(\d\d).(20\d\d)/)
              if dayMonthYearMatch
                [day,month,year] = dayMonthYearMatch[1..]
                if day > 31 or month > 12
                  console.error "Invalid DateOfPositiveResults: #{this}"
                else
                  resultDoc.DateofPositiveResults = "#{year}-#{month}-#{day}"

          if this[resultDoc.question]?
            # Duplicate
            if this[resultDoc.question].complete is "true" and (resultDoc.complete isnt "true")
              console.warn "Using the result marked as complete"
              return #  Use the version already loaded which is marked as complete
            else if this[resultDoc.question].complete and resultDoc.complete
              console.warn "Duplicate complete entries for case: #{@caseID}"
          this[resultDoc.question] = resultDoc
      else
        @caseID ?= resultDoc["caseid"]
        if @caseID isnt resultDoc["caseid"]
          console.error "Inconsistent Case ID. Working on #{@caseID} but current doc has #{resultDoc["caseid"]}: #{JSON.stringify resultDoc}:"
          console.error resultDoc
          console.error resultDocs
          throw "Inconsistent Case ID. Working on #{@caseID} but current doc has #{resultDoc["caseid"]}: #{JSON.stringify resultDoc}"
        @questions.push "USSD Notification"
        this["USSD Notification"] = resultDoc


  fetch: (options) =>
    Coconut.database.query "cases/cases",
      key: @caseID
      include_docs: true
    .catch (error) ->
      options?.error(error)
    .then (result) =>
      return options?.error("Could not find any existing data for case #{@caseID}") if result.rows.length is 0
      @loadFromResultDocs(_.pluck(result.rows, "doc"))
      options?.success()

  toJSON: =>
    returnVal = {}
    _.each @questions, (question) =>
      returnVal[question] = this[question]
    return returnVal

  deIdentify: (result) ->

  flatten: (questions = @questions) ->
    returnVal = {}
    _.each questions, (question) =>
      type = question
      _.each this[question], (value, field) ->
        if _.isObject value
          _.each value, (arrayValue, arrayField) ->
            returnVal["#{question}-#{field}: #{arrayField}"] = arrayValue
        else
          returnVal["#{question}:#{field}"] = value
    returnVal

  caseId: => @caseID

  LastModifiedAt: ->
    _.chain(@toJSON())
    .map (question) ->
      question.lastModifiedAt
    .max (lastModifiedAt) ->
      lastModifiedAt?.replace(/[- :]/g,"")
    .value()

  Questions: ->
    _.keys(@toJSON()).join(", ")

  MalariaCaseID: ->
    @caseID

  user: ->
    userId = @.Household?.user || @.Facility?.user || @["Case Notification"]?.user

  facility: ->
    @["Case Notification"]?.FacilityName.toUpperCase() or @["USSD Notification"]?.hf.toUpperCase()

  facilityType: =>
    FacilityHierarchy.facilityType(@facility())

  facilityDhis2OrganisationUnitId: =>
    GeoHierarchy.findFirst(@facility(), "FACILITY")?.id

  isShehiaValid: =>
    if @validShehia() then true else false

  validShehia: ->
    # Try and find a shehia is in our database
    if @.Household?.Shehia and GeoHierarchy.validShehia(@.Household.Shehia)
      return @.Household?.Shehia
    else if @.Facility?.Shehia and GeoHierarchy.validShehia(@.Facility.Shehia)
      return @.Facility?.Shehia
    else if @["Case Notification"]?.Shehia and GeoHierarchy.validShehia(@["Case Notification"]?.Shehia)
      return @["Case Notification"]?.Shehia
    else if @["USSD Notification"]?.shehia and GeoHierarchy.validShehia(@["USSD Notification"]?.shehia)
      return @["USSD Notification"]?.shehia

    return null

  shehia: ->
    returnVal = @validShehia()
    return returnVal if returnVal?

    console.warn "No valid shehia found for case: #{@MalariaCaseID()} result will be either null or unknown."
    #console.warn @

    # If no valid shehia is found, then return whatever was entered (or null)
    @.Household?.Shehia || @.Facility?.Shehia || @["Case Notification"]?.shehia || @["USSD Notification"]?.shehia

  village: ->
    @["Facility"]?.Village

  # Want best guess for the district - try and get a valid shehia, if not use district for reporting facility
  district: ->
    shehia = @validShehia()
    if shehia?

      findOneShehia = GeoHierarchy.findOneShehia(shehia)
      if findOneShehia
        return findOneShehia.parent().name
      else
        shehias = GeoHierarchy.findShehia(shehia)
        district = GeoHierarchy.swahiliDistrictName @["USSD Notification"]?.facility_district
        shehiaWithSameFacilityDistrict = _(shehias).findWhere {DISTRICT: district}
        if shehiaWithSameFacilityDistrict
          return shehiaWithSameFacilityDistrict.DISTRICT

    else
      console.warn "#{@MalariaCaseID()}: No valid shehia found, using district of reporting health facility (which may not be where the patient lives). Data from USSD Notification:"
      console.warn @["USSD Notification"]

      district = GeoHierarchy.swahiliDistrictName @["USSD Notification"]?.facility_district
      if _(GeoHierarchy.allDistricts()).include district
        return district
      else
        console.warn "#{@MalariaCaseID()}: The reported district (#{district}) used for the reporting facility is not a valid district. Looking up the district for the health facility name."
        district = GeoHierarchy.swahiliDistrictName(FacilityHierarchy.getDistrict @["USSD Notification"]?.hf)
        if _(GeoHierarchy.allDistricts()).include district
          return district
        else
          console.warn "#{@MalariaCaseID()}: The health facility name (#{@["USSD Notification"]?.hf}) is not valid. Giving up and returning UNKNOWN."
          return "UNKNOWN"

  highRiskShehia: (date) =>
    date = moment().startOf('year').format("YYYY-MM") unless date
    if Coconut.shehias_high_risk?[date]?
      _(Coconut.shehias_high_risk[date]).contains @shehia()
    else
      false

  locationBy: (geographicLevel) =>
    return @district() if geographicLevel.match(/district/i)
    return @validShehia() if geographicLevel.match(/shehia/i)

  namesOfAdministrativeLevels: () =>
    [@shehia()].concat(_(GeoHierarchy.findFirst(@shehia(), "SHEHIA")?.ancestors()).pluck "name").reverse().join(",")

  possibleQuestions: ->
    ["Case Notification", "Facility","Household","Household Members"]

  questionStatus: =>
    result = {}
    _.each @possibleQuestions(), (question) =>
      if question is "Household Members"
        result["Household Members"] = true
        _.each @["Household Members"]?, (member) ->
          result["Household Members"] = false if member.complete is "false"
      else
        result[question] = (@[question]?.complete is "true")
    return result

  complete: =>
    @questionStatus()["Household Members"] is true

  hasCompleteFacility: =>
    @.Facility?.complete is "true" or @.Facility?.complete is true

  notCompleteFacilityAfter24Hours: =>
    @moreThan24HoursSinceFacilityNotifed() and not @hasCompleteFacility()

  notFollowedUpAfter48Hours: =>
    @moreThan48HoursSinceFacilityNotifed() and not @followedUp()

  followedUpWithin48Hours: =>
    not @notFollowedUpAfter48Hours()

  notFollowedUpAfterXHours: =>
    @moreThanXHoursSinceFacilityNotifed() and not @followedUp()

  followedUpWithinXHours: =>
    not @notFollowedUpAfterXHours()

  # Includes any kind of travel including only within Zanzibar
  indexCaseHasTravelHistory: =>
    @.Facility?.TravelledOvernightinpastmonth?.match(/Yes/)? or false

  indexCaseHasNoTravelHistory: =>
    not @indexCaseHasTravelHistory()

  personTravelledInLast3Weeks = (householdOrHouseholdMember) ->
    zeroToSevenDays = householdOrHouseholdMember?["AlllocationsandentrypointsfromovernighttraveloutsideZanzibar07daysbeforepositivetestresult"]
    eightToFourteenDays = householdOrHouseholdMember?["AlllocationsandentrypointsfromovernighttraveloutsideZanzibar814daysbeforepositivetestresult"]
    fourteenToTwentyOneDays = householdOrHouseholdMember?["AlllocationsandentrypointsfromovernighttraveloutsideZanzibar1421daysbeforepositivetestresult"]
    if zeroToSevenDays?
      return true if zeroToSevenDays isnt ""
    else if eightToFourteenDays?
      return true if eightToFourteenDays isnt ""
    else if fourteenToTwentyOneDays?
      return true if fourteenToTwentyOneDays isnt ""
    else
      return false

  indexCaseSuspectedImportedCase: =>
    personTravelledInLast3Weeks(@.Household) or @indexCaseHasTravelHistory()

  numberSuspectedImportedCasesIncludingHouseholdMembers: =>
    result = 0
    # Check index case
    result +=1 if @indexCaseSuspectedImportedCase()
    # Check household cases
    _(@["Household Members"]).each (householdMember) ->
      result +=1 if personTravelledInLast3Weeks(householdMember)
    return result

  completeHouseholdVisit: =>
    @.Household?.complete is "true" or @.Facility?.Hassomeonefromthesamehouseholdrecentlytestedpositiveatahealthfacility is "Yes"

  dateHouseholdVisitCompleted: =>
    if @completeHouseholdVisit()
      @.Household.lastModifiedAt

  followedUp: =>
    @completeHouseholdVisit()

  location: (type) ->
    # Not sure how this works, since we are using the facility name with a database of shehias
    #WardHierarchy[type](@toJSON()["Case Notification"]?["FacilityName"])
    GeoHierarchy.findOneShehia(@toJSON()["Case Notification"]?["FacilityName"])?[type.toUpperCase()]

  withinLocation: (location) ->
    return @location(location.type) is location.name

  completeIndexCaseHouseholdMembers: =>
    return [] unless @["Household"]?
    _(@["Household Members"]).filter (householdMember) =>
      householdMember.HeadofHouseholdName is @["Household"].HeadofHouseholdName and householdMember.complete is "true"

  hasCompleteIndexCaseHouseholdMembers: =>
    @completeIndexCaseHouseholdMembers().length > 0

  positiveCasesAtIndexHousehold: ->
    _(@completeIndexCaseHouseholdMembers()).filter (householdMember) ->
      householdMember.MalariaTestResult is "PF" or householdMember.MalariaTestResult is "Mixed"

  numberPositiveCasesAtIndexHousehold: =>
    @positiveCasesAtIndexHousehold().length

  hasAdditionalPositiveCasesAtIndexHousehold: =>
    @numberPositiveCasesAtIndexHousehold() > 0


  completeNeighborHouseholds: =>
    _(@["Neighbor Households"]).filter (household) =>
      household.complete is "true"

  completeNeighborHouseholdMembers: =>
    return [] unless @["Household"]?
    _(@["Household Members"]).filter (householdMember) =>
      householdMember.HeadofHouseholdName isnt @["Household"].HeadofHouseholdName and householdMember.complete is "true"

  hasCompleteNeighborHouseholdMembers: =>
    @completeIndexCaseHouseholdMembers().length > 0

  positiveCasesAtNeighborHouseholds: ->
    _(@completeNeighborHouseholdMembers()).filter (householdMember) ->
      householdMember.MalariaTestResult is "PF" or householdMember.MalariaTestResult is "Mixed"

  positiveCasesAtIndexHouseholdAndNeighborHouseholds: ->
    _(@["Household Members"]).filter (householdMember) =>
      householdMember.MalariaTestResult is "PF" or householdMember.MalariaTestResult is "Mixed"

  positiveCasesAtIndexHouseholdAndNeighborHouseholdsUnder5: =>
    _(@positiveCasesAtIndexHouseholdAndNeighborHouseholds()).filter (householdMemberOrNeighbor) =>
      @ageInYears() < 5

  positiveCasesAtIndexHouseholdAndNeighborHouseholdsOver5: =>
    _(@positiveCasesAtIndexHouseholdAndNeighborHouseholds()).filter (householdMemberOrNeighbor) =>
      @ageInYears >= 5


  numberPositiveCasesAtIndexHouseholdAndNeighborHouseholds: ->
    @positiveCasesAtIndexHouseholdAndNeighborHouseholds().length

  numberHouseholdMembers: ->
    @["Household Members"].length

  #TODO this name implies neighbor members are counted, but they aren't - should be fixed
  numberHouseholdOrNeighborMembers: ->
    @["Household Members"].length

  # TODO this is only filtering for a specific result, not whether or not they are tested
  numberHouseholdOrNeighborMembersTested: ->
    _(@["Household Members"]).filter (householdMember) =>
      householdMember.MalariaTestResult is "NPF"
    .length or 0

  numberHouseholdMembersTestedAndUntested: =>
    numberHouseholdMembersFromHousehold = @["Household"]?["TotalNumberofResidentsintheHousehold"]
    numberHouseholdMembersWithRecord = @numberHouseholdMembers()
    # Some cases have more member records than TotalNumberofResidentsintheHousehold so use higher

    Math.max(numberHouseholdMembersFromHousehold, numberHouseholdMembersWithRecord)


  numberHouseholdMembersTested: =>
    _(@["Household Members"]).filter (householdMember) =>
      switch householdMember.MalariaTestResult
        when "NPF", "PF", "Mixed"
          true
    .length

  percentOfHouseholdMembersTested: =>
    (@numberHouseholdMembersTested()/@numberHouseholdMembersTestedAndUntested()*100).toFixed(0)

  positiveCasesIncludingIndex: =>
    if @["Facility"]
      @positiveCasesAtIndexHouseholdAndNeighborHouseholds().concat(_.extend @["Facility"], @["Household"])
    else if @["USSD Notification"]
      @positiveCasesAtIndexHouseholdAndNeighborHouseholds().concat(_.extend @["USSD Notification"], @["Household"], {MalariaCaseID: @MalariaCaseID()})
    else []

  numberPositiveCasesIncludingIndex: =>
    @positiveCasesIncludingIndex().length

  numberPositiveCasesAtIndexHouseholdAndNeighborHouseholdsUnder5: =>
    @positiveCasesAtIndexHouseholdAndNeighborHouseholdsUnder5().length

  massScreenCase: =>
    @Household?["Reason for visiting household"]? is "Mass Screen"

  indexCasePatientName: ->
    if @["Facility"]?.complete is "true"
      return "#{@["Facility"].FirstName} #{@["Facility"].LastName}"
    if @["USSD Notification"]?
      return @["USSD Notification"]?.name
    if @["Case Notification"]?
      return @["Case Notification"]?.Name

  indexCaseDiagnosisDate: ->
    if @["Facility"]?.DateofPositiveResults?
      date = @["Facility"].DateofPositiveResults
      momentDate = if date.match(/^20\d\d/)
        moment(@["Facility"].DateofPositiveResults)
      else
        moment(@["Facility"].DateofPositiveResults, "DD-MM-YYYY")
      return momentDate.format("YYYY-MM-DD") if momentDate.isValid()

    if @["USSD Notification"]?
      return moment(@["USSD Notification"].date).format("YYYY-MM-DD")

    else if @["Case Notification"]?
      return moment(@["Case Notification"].createdAt).format("YYYY-MM-DD")

  indexCaseDiagnosisDateIsoWeek: =>
    moment(@indexCaseDiagnosisDate()).isoWeek()

  householdMembersDiagnosisDates: =>
    @householdMembersDiagnosisDate()

  householdMembersDiagnosisDate: =>
    returnVal = []
    _.each @["Household Members"]?, (member) ->
      returnVal.push member.lastModifiedAt if member.MalariaTestResult is "PF" or member.MalariaTestResult is "Mixed"

  ageInYears: =>
    return null unless @Facility
    if @Facility["Age in Months Or Years"]? and @Facility["Age in Months Or Years"] is "Months"
      @Facility["Age"] / 12.0
    else
      @Facility["Age"]

  isUnder5: =>
    @ageInYears() < 5

  resultsAsArray: =>
    _.chain @possibleQuestions()
    .map (question) =>
      @[question]
    .flatten()
    .compact()
    .value()

  fetchResults: (options) =>
    results = _.map @resultsAsArray(), (result) =>
      returnVal = new Result()
      returnVal.id = result._id
      returnVal

    count = 0
    _.each results, (result) ->
      result.fetch
        success: ->
          count += 1
          options.success(results) if count >= results.length
    return results


  updateCaseID: (newCaseID) ->
    @fetchResults
      success: (results) ->
        _.each results, (result) ->
          throw "No MalariaCaseID" unless result.attributes.MalariaCaseID?
          result.save
            MalariaCaseID: newCaseID

  issuesRequiringCleaning: () ->
    # Case has multiple USSD notifications
    resultCount = {}
    questionTypes = "USSD Notification, Case Notification, Facility, Household, Household Members".split(/, /)
    _.each questionTypes, (questionType) ->
      resultCount[questionType] = 0

    _.each @caseResults, (result) ->
      resultCount["USSD Notification"]++ if result.caseid?
      resultCount[result.question]++ if result.question?

    issues = []
    _.each questionTypes[0..3], (questionType) ->
      issues.push "#{resultCount[questionType]} #{questionType}s" if resultCount[questionType] > 1
    issues.push "Not followed up" unless @followedUp()
    issues.push "Orphaned result" if @caseResults.length is 1
    issues.push "Missing case notification" unless @["Case Notification"]? or @["Case Notification"]?.length is 0

    return issues


  allResultsByQuestion: ->
    returnVal = {}
    _.each "USSD Notification, Case Notification, Facility, Household".split(/, /), (question) ->
      returnVal[question] = []

    _.each  @caseResults, (result) ->
      if result["question"]?
        returnVal[result["question"]].push result
      else if result.hf?
        returnVal["USSD Notification"].push result

    return returnVal

  redundantResults: ->
    redundantResults = []
    _.each @allResultsByQuestion, (results, question) ->
      console.log _.sort(results, "createdAt")


  dateOfPositiveResults: ->
    if @["Facility"]?.DateofPositiveResults?
      date = @["Facility"].DateofPositiveResults
      if date.match(/^20\d\d/)
        moment(@["Facility"].DateofPositiveResults).format("YYYY-MM-DD")
      else
        moment(@["Facility"].DateofPositiveResults, "DD-MM-YYYY").format("YYYY-MM-DD")

  daysBetweenPositiveResultAndNotificationFromFacility: =>

    dateOfPositiveResults = @dateOfPositiveResults()

    notificationDate = if @["USSD Notification"]?
      @["USSD Notification"].date

    if dateOfPositiveResults? and notificationDate?
      Math.abs(moment(dateOfPositiveResults).diff(notificationDate, 'days'))


  lessThanOneDayBetweenPositiveResultAndNotificationFromFacility: =>
    @daysBetweenPositiveResultAndNotificationFromFacility() <= 1

  oneToTwoDaysBetweenPositiveResultAndNotificationFromFacility: =>
    @daysBetweenPositiveResultAndNotificationFromFacility() <= 2

  twoToThreeDaysBetweenPositiveResultAndNotificationFromFacility: =>
    @daysBetweenPositiveResultAndNotificationFromFacility() <= 3

  moreThanThreeDaysBetweenPositiveResultAndNotificationFromFacility: =>
    @daysBetweenPositiveResultAndNotificationFromFacility() > 3


  daysBetweenPositiveResultAndCompleteHousehold: =>
    dateOfPositiveResults = @dateOfPositiveResults()
    completeHouseholdVisit = @dateHouseholdVisitCompleted()

    if dateOfPositiveResults and completeHouseholdVisit
      Math.abs(moment(dateOfPositiveResults).diff(completeHouseholdVisit, 'days'))

  lessThanOneDayBetweenPositiveResultAndCompleteHousehold: =>
    @daysBetweenPositiveResultAndCompleteHousehold() <= 1

  oneToTwoDaysBetweenPositiveResultAndCompleteHousehold: =>
    @daysBetweenPositiveResultAndCompleteHousehold() <= 2

  twoToThreeDaysBetweenPositiveResultAndCompleteHousehold: =>
    @daysBetweenPositiveResultAndCompleteHousehold() <= 3

  moreThanThreeDaysBetweenPositiveResultAndCompleteHousehold: =>
    @daysBetweenPositiveResultAndCompleteHousehold() > 3

  timeFacilityNotified: =>
    if @["USSD Notification"]?
      @["USSD Notification"].date
    else
      null

  timeSinceFacilityNotified: =>
    timeFacilityNotified = @timeFacilityNotified()
    if timeFacilityNotified?
      moment().diff(timeFacilityNotified)
    else
      null

  hoursSinceFacilityNotified: =>
    timeSinceFacilityNotified = @timeSinceFacilityNotified()
    if timeSinceFacilityNotified?
      moment.duration(timeSinceFacilityNotified).asHours()
    else
      null

   moreThan24HoursSinceFacilityNotifed: =>
     @hoursSinceFacilityNotified() > 24

   moreThan48HoursSinceFacilityNotifed: =>
     @hoursSinceFacilityNotified() > 48

   moreThanXHoursSinceFacilityNotifed: =>
     @hoursSinceFacilityNotified() > parseInt(Coconut.config.case_followup)

  timeFromSMSToCaseNotification: =>
    if @["Case Notification"]? and @["USSD Notification"]?
      return moment(@["Case Notification"]?.createdAt).diff(@["USSD Notification"]?.date)

  # Note the replace call to handle a bug that created lastModified entries with timezones
  timeFromCaseNotificationToCompleteFacility: =>
    if @["Facility"]?.complete is "true" and @["Case Notification"]?
      return moment(@["Facility"].lastModifiedAt.replace(/\+0\d:00/,"")).diff(@["Case Notification"]?.createdAt)

  daysFromCaseNotificationToCompleteFacility: =>
    if @["Facility"]?.complete is "true" and @["Case Notification"]?
      moment.duration(@timeFromCaseNotificationToCompleteFacility()).asDays()

  timeFromFacilityToCompleteHousehold: =>
    if @["Household"]?.complete is "true" and @["Facility"]?
      return moment(@["Household"].lastModifiedAt.replace(/\+0\d:00/,"")).diff(@["Facility"]?.lastModifiedAt)

  timeFromSMSToCompleteHousehold: =>
    if @["Household"]?.complete is "true" and @["USSD Notification"]?
      return moment(@["Household"].lastModifiedAt.replace(/\+0\d:00/,"")).diff(@["USSD Notification"]?.date)

  daysFromSMSToCompleteHousehold: =>
    if @["Household"]?.complete is "true" and @["USSD Notification"]?
      moment.duration(@timeFromSMSToCompleteHousehold()).asDays()

  createOrUpdateOnDhis2: (options = {}) =>
    options.malariaCase = @
    Coconut.dhis2.createOrUpdateMalariaCase(options)

  spreadsheetRow: (question) =>
    console.error "Must call loadSpreadsheetHeader at least once before calling spreadsheetRow" unless Coconut.spreadsheetHeader?

    spreadsheetRowObjectForResult = (fields,result) ->
      if result?
        _(fields).map (field) =>
          if result[field]?
            if _.contains(Coconut.identifyingAttributes, field)
              return b64_sha1(result[field])
            else
              return result[field]
          else
            return ""
      else
        return null

    if question is "Household Members"
      _(@[question]).map (householdMemberResult) ->
        spreadsheetRowObjectForResult(Coconut.spreadsheetHeader[question], householdMemberResult)
    else
      spreadsheetRowObjectForResult(Coconut.spreadsheetHeader[question], @[question])

  spreadsheetRowString: (question) =>

    if question is "Household Members"
      _(@spreadsheetRow(question)).map (householdMembersRows) ->
        result = _(householdMembersRows).map (data) ->
          "\"#{data}\""
        .join(",")
        result += "--EOR--" if result isnt ""
      .join("")
    else
      result = _(@spreadsheetRow(question)).map (data) ->
        "\"#{data}\""
      .join(",")
      result += "--EOR--" if result isnt ""


  summaryResult: (property,options) =>
    priorityOrder = options.priorityOrder or [
      "Household"
      "Facility"
      "Case Notification"
      "USSD Notification"
    ]

    if property.match(/:/)
      propertyName = property
      priorityOrder = [property.split(/: */)[0]]

    # If prependQuestion then we only want to search within that question
    priorityOrder = [options.prependQuestion] if options.prependQuestion

    # Make the labels be human readable by looking up the original question text and using that
    labelMappings = {}
    _(priorityOrder).each (question) ->
      return if question is "USSD Notification"
      labelMappings[question] = Coconut.questions.findWhere({_id:question}).safeLabelsToLabelsMappings()

    # Looks through the results in the prioritized order for a match
    findPrioritizedProperty = (propertyNames=[property]) =>
      result = null
      _(propertyNames).each (propertyName) =>
        return if result
        _(priorityOrder).each (question) =>
          return if result
          return unless @[question]?
          if @[question][propertyName]?
            result = @[question][propertyName]
            property = labelMappings[question][propertyName] if labelMappings[question] and labelMappings[question][propertyName]

      return result

    result = null

    result = @[property]() if result is null and @[property]
    result = findPrioritizedProperty() if result is null

    if result is null
      result = findPrioritizedProperty(options.otherPropertyNames) if options.otherPropertyNames

    if options.propertyName
      property = options.propertyName
    else
      property = titleize(humanize(property))

    if options.prependQuestion
      property = "#{options.prependQuestion}: #{property}"

    return {"#{property}": result}

  summaryCollection: ->
    result = {}
    _(Case.summaryProperties).each (options, property) =>
      result = _(result).extend @summaryResult(property, options)
    return result

  summary: ->
    _(Case.summaryProperties).map (options, property) =>
      @summaryResult(property, options)

  Case.summaryPropertiesKeys = ->
    _(Case.summaryProperties).map (options, key) ->
      if options.propertyName
        key = options.propertyName
      else
        key = s(key).humanize().titleize().value().replace("Numberof", "Number of")

  summaryAsCSVString: =>
    _(@summary()).chain().map (summaryItem) ->
      "\"#{_(summaryItem).values()}\""
    .flatten().value().join(",") + "--EOR--<br/>"

  Case.summaryProperties = {

    # TODO Document how the different options work
    # propertyName is used to change the column name at the top of the CSV
    # otherPropertyNames is an array of other values to try and check

    # Case Notification
    MalariaCaseID:
      propertyName: "Malaria Case ID"
    indexCaseDiagnosisDate: {}
    indexCaseDiagnosisDateIsoWeek: {}

    # LostToFollowup: {}
    #
    namesOfAdministrativeLevels: {}

    district:
      propertyName: "District (if no household district uses facility)"
    facility: {}
    facilityType: {}
    facility_district:
      propertyName: "District of Facility"
    shehia: {}
    isShehiaValid: {}
    highRiskShehia: {}
    village:
      propertyName: "Village"

    indexCasePatientName:
      propertyName: "Patient Name"
    ageInYears: {}
    Sex: {}
    isUnder5:
      propertyName: "Is Index Case Under 5"

    SMSSent:
      propertyName: "SMS Sent to DMSO"
    hasCaseNotification: {}
    numbersSentTo: {}
    source: {}
    source_phone: {}
    type: {}

    hasCompleteFacility: {}
    notCompleteFacilityAfter24Hours: {}
    notFollowedUpAfter48Hours: {}
    notFollowedUpAfterXHours: {}
    followedUpWithin48Hours: {}
    indexCaseHasTravelHistory: {}
    indexCaseHasNoTravelHistory: {}
    indexCaseSuspectedImportedCase: {}
    completeHouseholdVisit: {}
    numberHouseholdMembersTestedAndUntested: {}
    numberHouseholdMembersTested: {}
    numberPositiveCasesAtIndexHousehold: {}
    numberPositiveCasesAtIndexHouseholdAndNeighborHouseholds: {}
    numberHouseholdOrNeighborMembers: {}
    numberHouseholdOrNeighborMembersTested: {}
    numberPositiveCasesIncludingIndex: {}
    numberPositiveCasesAtIndexHouseholdAndNeighborHouseholdsUnder5: {}
    numberSuspectedImportedCasesIncludingHouseholdMembers: {}
    massScreenCase: {}

    CaseIDforotherhouseholdmemberthattestedpositiveatahealthfacility:
      propertyName: "Case ID for Other Household Member That Tested Positive at a Health Facility"
    CommentRemarks: {}
    ContactMobilepatientrelative:
      propertyName: "Contact Mobile Patient Relative"
    Hassomeonefromthesamehouseholdrecentlytestedpositiveatahealthfacility:
      propertyName: "Has Someone From the Same Household Recently Tested Positive at a Health Facility"
    HeadofHouseholdName: {}
    ParasiteSpecies: {}
    ReferenceinOPDRegister: {}
    ShehaMjumbe: {}
    TravelledOvernightinpastmonth:
      propertyName: "Travelled Overnight in Past Month"
    IfYESlistALLplacestravelled:
      propertyName: "All Places Traveled to in Past Month"
    TreatmentGiven: {}

    #Household
    CouponNumbers: {}
    FollowupNeighbors: {}
    Haveyougivencouponsfornets: {}
    HeadofHouseholdName: {}
    "HouseholdLocation-accuracy": {}
    "HouseholdLocation-altitude": {}
    "HouseholdLocation-altitudeAccuracy": {}
    "HouseholdLocation-description": {}
    "HouseholdLocation-heading": {}
    "HouseholdLocation-latitude": {}
    "HouseholdLocation-longitude": {}
    "HouseholdLocation-timestamp": {}
    IndexcaseIfpatientisfemale1545yearsofageissheispregant:
      propertyName: "Is Index Case Pregnant"
    IndexcaseOvernightTraveloutsideofZanzibarinthepastyear:
      propertyName: "Has Index Case had Overnight Travel Outside of Zanzibar in the Past Year"
    IndexcaseOvernightTravelwithinZanzibar1024daysbeforepositivetestresult: {}
      "Index Case Overnight Travel Within Zanzibar 10-24 Days Before Positive Test Result"
    travelLocationName: {}
    AlllocationsandentrypointsfromovernighttraveloutsideZanzibar07daysbeforepositivetestresult:
      propertyName: "All Locations and Entry Points From Overnight Travel Outside Zanzibar 0-7 Days Before Positive Test Result"
    AlllocationsandentrypointsfromovernighttraveloutsideZanzibar814daysbeforepositivetestresult:
      propertyName: "All Locations and Entry Points From Overnight Travel Outside Zanzibar 8-14 Days Before Positive Test Result"
    AlllocationsandentrypointsfromovernighttraveloutsideZanzibar1521daysbeforepositivetestresult:
      propertyName: "All Locations and Entry Points From Overnight Travel Outside Zanzibar 15-21 Days Before Positive Test Result"
    AlllocationsandentrypointsfromovernighttraveloutsideZanzibar2242daysbeforepositivetestresult:
      propertyName: "All Locations and Entry Points From Overnight Travel Outside Zanzibar 22-42 Days Before Positive Test Result"
    AlllocationsandentrypointsfromovernighttraveloutsideZanzibar43365daysbeforepositivetestresult:
      propertyName: "All Locations and Entry Points From Overnight Travel Outside Zanzibar 43-365 Days Before Positive Test Result"
    ListalllocationsofovernighttravelwithinZanzibar1024daysbeforepositivetestresult:
      propertyName: "All Locations Of Overnight Travel Within Zanzibar 10-24 Days Before Positive Test Result"
    IndexcasePatient: {}
    IndexcasePatientscurrentstatus: {}
    IndexcasePatientstreatmentstatus: {}
    IndexcaseSleptunderLLINlastnight: {}
    LastdateofIRS: {}
    NumberofHouseholdMembersTreatedforMalariaWithinPastWeek: {}
    NumberofHouseholdMemberswithFeverorHistoryofFeverWithinPastWeek: {}
    NumberofLLIN: {}
    NumberofSleepingPlacesbedsmattresses: {}
    Numberofotherhouseholdswithin50stepsofindexcasehousehold:
      propertyName: "Number of Other Households Within 50 Steps of Index Case Household"
    Reasonforvisitinghousehold:
      propertyName: "Reason for Visiting Household"
    ShehaMjumbe: {}
    TotalNumberofResidentsintheHousehold: {}

    daysFromCaseNotificationToCompleteFacility: {}
    daysFromSMSToCompleteHousehold:
      propertyName: "Days between SMS Sent to DMSO to Having Complete Household"

    daysBetweenPositiveResultAndNotificationFromFacility: {}
    lessThanOneDayBetweenPositiveResultAndNotificationFromFacility: {}
    oneToTwoDaysBetweenPositiveResultAndNotificationFromFacility: {}
    twoToThreeDaysBetweenPositiveResultAndNotificationFromFacility: {}
    moreThanThreeDaysBetweenPositiveResultAndNotificationFromFacility: {}

    daysBetweenPositiveResultAndCompleteHousehold: {}
    lessThanOneDayBetweenPositiveResultAndCompleteHousehold: {}
    oneToTwoDaysBetweenPositiveResultAndCompleteHousehold: {}
    twoToThreeDaysBetweenPositiveResultAndCompleteHousehold: {}
    moreThanThreeDaysBetweenPositiveResultAndCompleteHousehold: {}

    "USSD Notification: Created At":
      otherPropertyNames: ["createdAt"]
    "USSD Notification: Date":
      otherPropertyNames: ["date"]
    "USSD Notification: Last Modified At":
      otherPropertyNames: ["lastModifiedAt"]
    "USSD Notification: User":
      otherPropertyNames: ["user"]
    "Case Notification: Created At":
      otherPropertyNames: ["createdAt"]
    "Case Notification: Last Modified At":
      otherPropertyNames: ["lastModifiedAt"]
    "Case Notification: Saved By":
      otherPropertyNames: ["savedBy"]
    "Facility: Created At":
      otherPropertyNames: ["createdAt"]
    "Facility: Last Modified At":
      otherPropertyNames: ["lastModifiedAt"]
    "Facility: Saved By":
      otherPropertyNames: ["savedBy"]
    "Facility: User":
      otherPropertyNames: ["user"]
    "Household: Created At":
      otherPropertyNames: ["createdAt"]
    "Household: Last Modified At":
      otherPropertyNames: ["lastModifiedAt"]
    "Household: Saved By":
      otherPropertyNames: ["savedBy"]
    "Household: User":
      otherPropertyNames: ["user"]
  }

Case.resetSpreadsheetForAllCases = =>
  Coconut.database.get "CaseSpreadsheetData"
  .then (caseSpreadsheetData) ->
    Case.updateCaseSpreadsheetDocs(0,caseSpreadsheetData)
  .catch (error) -> console.error error

Case.loadSpreadsheetHeader = (options) ->
  if Coconut.spreadsheetHeader
    options.success()
  else
    Coconut.database.get "spreadsheet_header"
    .catch (error) -> console.error error
    .then (result) ->
      Coconut.spreadsheetHeader = result.fields
      options.success()

Case.updateCaseSpreadsheetDocs = (options) ->

  # defaults used for first run
  caseSpreadsheetData = {_id: "CaseSpreadsheetData" }
  changeSequence = 0

  updateCaseSpreadsheetDocs = (changeSequence, caseSpreadsheetData) ->
    Case.updateCaseSpreadsheetDocsSince
      changeSequence: changeSequence
      error: (error) ->
        console.log "Error updating CaseSpreadsheetData:"
        console.log error
        options.error?()
      success: (numberCasesChanged,lastChangeSequenceProcessed) ->
        console.log "Updated CaseSpreadsheetData"
        caseSpreadsheetData.lastChangeSequenceProcessed = lastChangeSequenceProcessed
        console.log caseSpreadsheetData
        Coconut.database.put caseSpreadsheetData
        .catch (error) -> console.error error
        .then ->
          console.log numberCasesChanged
          if numberCasesChanged > 0
            Case.updateCaseSpreadsheetDocs(options)  #recurse
          else
            options?.success?()

  Coconut.database.get "CaseSpreadsheetData"
  .catch (error) ->
    console.log "Couldn't find 'CaseSpreadsheetData' using defaults: changeSequence: #{changeSequence}"
    updateCaseSpreadsheetDocs(changeSequence,caseSpreadsheetData)
  .then (result) ->
    caseSpreadsheetData = result
    changeSequence = result.lastChangeSequenceProcessed
    updateCaseSpreadsheetDocs(changeSequence,caseSpreadsheetData)

Case.updateCaseSpreadsheetDocsSince = (options) ->
  Case.loadSpreadsheetHeader
    success: ->
      $.ajax
        url: "/#{Coconut.config.database_name()}/_changes"
        dataType: "json"
        data:
          since: options.changeSequence
          include_docs: true
          limit: 500
        error: (error) =>
          console.log "Error downloading changes after #{options.changeSequence}:"
          console.log error
          options.error?(error)
        success: (changes) =>
          changedCases = _(changes.results).chain().map (change) ->
            change.doc.MalariaCaseID if change.doc.MalariaCaseID? and change.doc.question?
          .compact().uniq().value()
          lastChangeSequence = changes.results.pop()?.seq
          Case.updateSpreadsheetForCases
            caseIDs: changedCases
            error: (error) ->
              console.log "Error updating #{changedCases.length} cases, lastChangeSequence: #{lastChangeSequence}"
              console.log error
            success: ->
              console.log "Updated #{changedCases.length} cases, lastChangeSequence: #{lastChangeSequence}"
              options.success(changedCases.length, lastChangeSequence)



Case.updateSpreadsheetForCases = (options) ->
  docsToSave = []
  questions = "USSD Notification,Case Notification,Facility,Household,Household Members".split(",")
  options.success() if options.caseIDs.length is 0

  finished = _.after options.caseIDs.length, ->
    Coconut.database.bulkDocs docsToSave
    .catch (error) -> console.error error
    .then -> options.success()

  _(options.caseIDs).each (caseID) ->
    malariaCase = new Case
      caseID: caseID
    malariaCase.fetch
      error: (error) ->
        console.log error
      success: ->

        docId = "spreadsheet_row_#{caseID}"
        spreadsheet_row_doc = {_id: docId}

        saveRowDoc = (result) ->
          spreadsheet_row_doc = result if result? # if the row already exists use the _rev
          _(questions).each (question) ->
            spreadsheet_row_doc[question] = malariaCase.spreadsheetRowString(question)

          spreadsheet_row_doc["Summary"] = malariaCase.summaryAsCSVString()

          docsToSave.push spreadsheet_row_doc
          finished()

        Coconut.database.get docId
        .catch (error) -> saveRowDoc()
        .then (result) -> saveRowDoc(result)

Case.getCases = (options) ->
  Coconut.database.query "cases",
    keys: options.caseIDs
    include_docs: true
  .catch (error) ->
      options?.error(error)
  .then (result) =>
    options?.success(_.chain(result.rows)
      .groupBy (row) =>
        row.key
      .map (resultsByCaseID) =>
        malariaCase = new Case
          results: _.pluck resultsByCaseID, "doc"
        malariaCase
      .compact()
      .value()
    )

Case.getLatestChange = (options) ->
  Coconut.database.changes
    descending: true
    include_docs: false
    limit: 1
  .on "complete", (mostRecentChange) ->
    options?.success(mostRecentChange.last_seq)
  .on "error", (error) ->
    console.error error
    options?.error()

Case.setCaseSummaryDataDoc = (options) ->
  save = (doc) ->
    Coconut.database.put doc
    .catch (error) -> console.error error
    .then -> options?.success()

  Coconut.database.get "CaseSummaryData"
  .catch (error) ->
    console.log "Couldn't find 'CaseSummaryData' document (#{error.toJSON()}), creating a new one."
    save(
      _id: "CaseSummaryData",
      lastChangeSequenceProcessed: options.changeSequence
    )
  .then (caseSummaryData) ->
    caseSummaryData.lastChangeSequenceProcessed = options.changeSequence
    save(caseSummaryData)

Case.resetAllCaseSummaryDocs = (options)  =>
  numberCasesToProcessConcurrently = options?.numberCasesToProcessConcurrently or 2

  # Delete all existing case_summary_ docs
  Coconut.database.allDocs
    startkey: "case_summary_"
    endkey: "case_summary_\ufff0"
    include_docs: false
  .then (result) ->
    docs = _(result.rows).map (row) ->
      {
        _id: row.id
        _rev: row.value.rev
        _deleted: true
      }

    console.log "Deleting #{docs.length} case_summary_ docs"

    Coconut.database.bulkDocs docs
    .catch (error) -> console.error error
    .then ->
      console.log "Existing case_summary_ docs deleted"

      # This approach works different than update, by getting all cases ids and updating every one, versus working based on changes. It's faster this way
      #
      Case.getLatestChange
        error: (error) -> console.error error
        success: (latestChange) ->
          console.log "Latest change: #{latestChange}"
          console.log "Retrieving all available case IDs"

          Coconut.database.query "cases/cases"
          .then (result) =>
            allCases = _(result.rows).chain().pluck("key").uniq().value()
            console.log "ALL CASES"
            console.log allCases.join(',')


            updateCases = ->
              try
                if allCases.length is 0
                  console.log "Finished, checking for changes since this process started: (#{latestChange})"
                  Case.setCaseSummaryDataDoc
                    changeSequence: latestChange
                    error: (error) -> console.error error
                    success: ->
                      Case.updateCaseSummaryDocs # Catches changes since this process started
                        error: (error) -> console.error error
                        success: -> options?.success()

                  return
                console.log "Remaining: #{allCases.length}"
                casesToProcess = allCases.splice(-numberCasesToProcessConcurrently,numberCasesToProcessConcurrently)
                Case.updateSummaryForCases
                  caseIDs: casesToProcess
                  success: ->
                    console.log "Updated: #{casesToProcess.join(',')}"
                    updateCases() # recurse
              catch error
                console.error error

            updateCases()
          .catch (error) ->
            options?.error()

Case.updateCaseSummaryDocs = (options) ->

  update = (changeSequence, caseSummaryData) ->
    Case.updateCaseSummaryDocsSince
      maximumNumberChangesToProcess: options.maximumNumberChangesToProcess or 500
      changeSequence: changeSequence
      error: (error) ->
        console.error "Error updating CaseSummaryData:"
        console.error error
        options.error?()
      success: (numberCasesChanged,lastChangeSequenceProcessed) ->
        caseSummaryData.lastChangeSequenceProcessed = lastChangeSequenceProcessed
        Coconut.database.put caseSummaryData
        .then (result) ->
          console.log "Number of cases changed: #{numberCasesChanged}"
          Case.getLatestChange
            error: -> console.error error
            success: (latestChange) ->
              if lastChangeSequenceProcessed+1 < latestChange
                Case.updateCaseSummaryDocs(options)  #recurse
              else
                options?.success?()
        .catch (error) -> console.error error


  Coconut.database.get "CaseSummaryData"
  .catch (error) ->
    console.log error
    console.log "Couldn't find 'CaseSummaryData' document. Starting from the beginning."
    # defaults used for first run
    update(0,{_id: "CaseSummaryData"})
  .then (caseSummaryData) ->
    console.log caseSummaryData
    Coconut.database.changes
      since: "now"
      include_docs: false
      limit: 1
    .then (result) ->
      console.log result
      update(caseSummaryData.lastChangeSequenceProcessed, caseSummaryData)

Case.updateCaseSummaryDocsSince = (options) ->
    limit = options.maximumNumberChangesToProcess
    console.log "Looking for the next #{limit} changes after #{options.changeSequence}"

    Coconut.database.changes
      live: false
      since: options.changeSequence
      include_docs: true
      limit: limit
    .then (result) ->
        # Could do this with a filter but still need to loop to extract the MalariaCaseID, so this should be faster
        changedCases = _(result.results).chain().map (change) ->
          change.doc.MalariaCaseID if change.doc.MalariaCaseID? and change.doc.question?
        .compact().uniq().value()
        console.log "Changed cases: #{_(changedCases).join(',')}"
        lastChangeSequence = result.last_seq
        Case.updateSummaryForCases
          caseIDs: changedCases
          error: (error) ->
            console.log "Error updating #{changedCases.length} cases, lastChangeSequence: #{lastChangeSequence}"
            console.log error
          success: ->
            console.log "Updated #{changedCases.length} cases, lastChangeSequence: #{lastChangeSequence}"
            options.success(changedCases.length, lastChangeSequence)

    .catch (error) =>
      console.error "Error downloading changes after #{options.changeSequence}:"
      console.error error
      options.error?(error)


Case.getCasesByCaseIds = (options) ->
  Coconut.database.query "cases",
    keys: options.caseIDs
    include_docs: true
  .catch (error) -> console.error error
  .then (result) =>
    groupedResults = _.chain(result.rows)
      .groupBy (row) =>
        row.key
      .map (resultsByCaseID) =>
        new Case
          results: _.pluck resultsByCaseID, "doc"
      .compact()
      .value()
    options.success groupedResults

Case.updateSummaryForCases = (options) ->
  docsToSave = []
  options.success() if options.caseIDs.length is 0

  finished = _.after options.caseIDs.length, ->
    console.log "FINISHED"
    Coconut.database.bulkDocs docsToSave
      .then ->
        options.success()
      .catch (error) ->
        console.error "ERROR SAVING #{docsToSave.length} case summaries: #{caseIDs.join ","}"
        console.error error

  _(options.caseIDs).each (caseID) ->
    malariaCase = new Case
      caseID: caseID
    malariaCase.fetch
      error: (error) ->
        console.error "ERROR fetching case: #{caseID}"
        console.error error
        finished()
      success: ->
        docId = "case_summary_#{caseID}"
        caseSummaryDoc = {_id: docId}

        saveCaseSummaryDoc = (result) ->
          caseSummaryDoc._rev = result._rev if result? # if the row already exists use the _rev
          try
            caseSummaryDoc = _(caseSummaryDoc).extend(malariaCase.summaryCollection())
          catch error
            console.error error

          docsToSave.push caseSummaryDoc
          finished()

        Coconut.database.get docId
        .then (result) ->
          saveCaseSummaryDoc(result)
        .catch (error) ->
          saveCaseSummaryDoc()



Case.createCaseView = (options) ->
  @case = options.case

  tables = [
    "USSD Notification"
    "Case Notification"
    "Facility"
    "Household"
    "Household Members"
  ]

  @mappings = {
    createdAt: "Created At"
    lastModifiedAt: "Last Modified At"
    question: "Question"
    user: "User"
    complete: "Complete"
    savedBy: "Saved By"
  }

  #hack to rename Question name in Case view report
  caseQuestions = @case.Questions().replace("Case Notification", "Case Notification Received").replace("USSD Notification","Case Notification Sent")

  Coconut.caseview = "
    <h5>Case ID: #{@case.MalariaCaseID()}</h5><button id='closeDialog' class='mdl-button mdl-js-button mdl-button--icon mdl-button--colored f-right'><i class='mdi mdi-close-circle mdi-24px'></i></button>
    <h6>Last Modified: #{@case.LastModifiedAt()}</h6>
    <h6>Questions: #{caseQuestions}</h6>
  "

  # USSD Notification doesn't have a mapping
  finished = _.after 5, =>
    Coconut.caseview += _.map(tables, (tableType) =>
      if @case[tableType]?
        if tableType is "Household Members"
          _.map(@case[tableType], (householdMember) =>
            @createObjectTable(tableType,householdMember, @mappings)
          ).join("")
        else
          @createObjectTable(tableType,@case[tableType], @mappings)
    ).join("")
    options?.success()
    return false

  _(tables).each (question) =>
    if question != "USSD Notification"
      question = new Question(id: question)
      question.fetch
        success: =>
          _.extend(@mappings, question.safeLabelsToLabelsMappings())
    finished()
    return false


Case.createObjectTable = (name,object,mappings) ->
  #Hack to replace title to differ from Questions title
  name = "Case Notification Received" if name == 'Case Notification'
  name = "Case Notification Sent" if name == 'USSD Notification'

  "
    <h4 id=#{object._id}>#{name}
      <!-- <small><a href='#edit/result/#{object._id}'>Edit</a></small> -->
    </h4>
    <table class='mdl-data-table mdl-js-data-table mdl-data-table--selectable mdl-shadow--2dp caseTable'>
      <thead>
        <tr>
          <th class='mdl-data-table__cell--non-numeric width65pct'>Field</th>
          <th class='mdl-data-table__cell--non-numeric'>Value</th>
        </tr>
      </thead>
      <tbody>
        #{
          labels = CONST.Labels
          _.map(object, (value, field) =>
            if !(Coconut.currentUser.isAdmin())
              if (_.indexOf(['name','Name','FirstName','MiddleName','LastName','HeadofHouseholdName','ContactMobilepatientrelative'],field) != -1)
                value = "************"
            return if "#{field}".match(/_id|_rev|collection/)
            "
              <tr>
                <td class='mdl-data-table__cell--non-numeric'>
                  #{
                   mappings[field] or labels[field]
                  }
                </td>
                <td class='mdl-data-table__cell--non-numeric'>#{value}</td>
              </tr>
            "
          ).join("")

        }
      </tbody>
    </table>
  "

Case.showCaseDialog = (options) ->
  caseId = options.caseID

  Coconut.case = new Case
    caseID: caseId
  Coconut.case.fetch
    success: ->
      Case.createCaseView
        case: Coconut.case
        success: ->
          $('#caseDialog').html(Coconut.caseview)
          if (Env.is_chrome)
             caseDialog.showModal() if !caseDialog.open
          else
             caseDialog.show() if !caseDialog.open
          options?.success()
      return false



module.exports = Case
