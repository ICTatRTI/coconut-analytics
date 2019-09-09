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
            dateOfPositiveResults = resultDoc.DateOfPositiveResults
            if dateOfPositiveResults?
              dayMonthYearMatch = dateOfPositiveResults.match(/^(\d\d).(\d\d).(20\d\d)/)
              if dayMonthYearMatch
                [day,month,year] = dayMonthYearMatch[1..]
                if day > 31 or month > 12
                  console.error "Invalid DateOfPositiveResults: #{this}"
                else
                  resultDoc.DateOfPositiveResults = "#{year}-#{month}-#{day}"

          if this[resultDoc.question]?
            # Duplicate
            if (this[resultDoc.question].complete is "true" or this[resultDoc.question].complete is true) and (resultDoc.complete isnt "true" or resultDoc.complete isnt true)
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
      unless @caseID
        return Promise.reject "No caseID to fetch data for"
      Coconut.database.query "cases",
        key: @caseID
        include_docs: true
      .catch (error) -> 
        options?.error()
        Promise.reject(error)
      .then (result) =>
        if result.rows.length is 0
          options?.error("Could not find any existing data for case #{@caseID}")
          Promise.reject ("Could not find any existing data for case #{@caseID}")
        @loadFromResultDocs(_.pluck(result.rows, "doc"))
        options?.success()
        Promise.resolve()



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

  allUserIds: ->
    users = []
    users.push @.Household?.user 
    users.push @.Facility?.user 
    users.push @["Case Notification"]?.user

    _(users).chain().uniq().compact().value()

  allUserNames: =>
    for userId in @allUserIds()
      Coconut.nameByUsername[userId] or "Unknown"

  facility: ->
    @["Case Notification"]?.FacilityName.toUpperCase() or @["USSD Notification"]?.hf.toUpperCase() or @["Facility"]?.FacilityName or "UNKNOWN"

  facilityType: =>
    facilityName = @facility()
    unless facilityName
      console.warn "No facility name found"
    else
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

  facilityDistrict: ->
    facilityDistrict = @["USSD Notification"]?.facility_district
    unless facilityDistrict and GeoHierarchy.validDistrict(facilityDistrict)
      facilityUnit = GeoHierarchy.findFirst(@facility(), "FACILITY")
      facilityDistrict = facilityUnit?.ancestorAtLevel("DISTRICT").name
    unless facilityDistrict
      console.warn "Could not find a district for USSD notification: #{JSON.stringify @["USSD Notification"]}"
      return "UNKNOWN"
    GeoHierarchy.swahiliDistrictName(facilityDistrict)

  # Want best guess for the district - try and get a valid shehia, if not use district for reporting facility
  district: ->
    shehia = @validShehia()
    if shehia?

      findOneShehia = GeoHierarchy.findOneShehia(shehia)
      if findOneShehia
        return findOneShehia.parent().name
      else
        shehias = GeoHierarchy.findShehia(shehia)
        facilityDistrict = @facilityDistrict()
        shehiaWithSameFacilityDistrict = _(shehias).find (shehia) ->
          shehia.parent().name is facilityDistrict
        if shehiaWithSameFacilityDistrict
          return shehiaWithSameFacilityDistrict.parent().name
        else
          console.warn "#{@MalariaCaseID()}: Shehia #{shehia} is not unique, and the facility's district '#{facilityDistrict}' doesn't match the possibilities. It's possible districts are: #{(_(shehias).map (shehia) -> shehia.parent().name).join(', ')}. Using Facility District: #{facilityDistrict}." 
          return facilityDistrict

    else
      console.warn "#{@MalariaCaseID()}: No valid shehia found, using district of reporting health facility (which may not be where the patient lives). Data from USSD Notification: #{JSON.stringify(@["USSD Notification"])}"

      facilityDistrict = @facilityDistrict()

      if facilityDistrict
        facilityDistrict
      else
        return "UNKNOWN"

  highRiskShehia: (date) =>
    date = moment().startOf('year').format("YYYY-MM") unless date
    if Coconut.shehias_high_risk?[date]?
      _(Coconut.shehias_high_risk[date]).contains @shehia()
    else
      false

  locationBy: (geographicLevel) =>
    return @validShehia() if geographicLevel.match(/shehia/i)
    district = @district()
    if district?
      return district if geographicLevel.match(/district/i)
      GeoHierarchy.getAncestorAtLevel(district, "DISTRICT", geographicLevel)
    else
      console.warn "No district for case: #{@caseId}"

  namesOfAdministrativeLevels: () =>
    shehia = @shehia()
    district = @district()
    if district
      districtAncestors = _(GeoHierarchy.findFirst(district, "DISTRICT")?.ancestors()).pluck "name"
      result = districtAncestors.reverse()
      if shehia
        result.concat(shehia)
      result.join(",")

  possibleQuestions: ->
    ["Case Notification", "Facility","Household","Household Members"]

  questionStatus: =>
    result = {}
    _.each @possibleQuestions(), (question) =>
      if question is "Household Members"
        result["Household Members"] = true
        _.each @["Household Members"]?, (member) ->
          result["Household Members"] = false if (member.complete is "false" or member.complete is false)
      else
        result[question] = (@[question]?.complete is "true" or @[question]?.complete is true)
    return result

  complete: =>
    @questionStatus()["Household Members"] is true or @questionStatus()["Household Members"] is "true"

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
    @.Facility?.TravelledOvernightInPastMonth?.match(/Yes/)? or false

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
    @.Household?.complete is "true" or @.Household?.complete is true or @.Facility?.HasSomeoneFromTheSameHouseholdRecentlyTestedPositiveAtAHealthFacility is "Yes" or @.Facility?.Hassomeonefromthesamehouseholdrecentlytestedpositiveatahealthfacility is "Yes"

  dateHouseholdVisitCompleted: =>
    if @completeHouseholdVisit()
      @.Household?.lastModifiedAt or @Facility.lastModifiedAt # When the household has two cases

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
      (householdMember.HeadofHouseholdName is @["Household"].HeadofHouseholdName or householdMember.HeadOfHouseholdName is @["Household"].HeadOfHouseholdName) and (householdMember.complete is "true" or householdMember.complete is true)

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
      household.complete is "true" or household.complete is true

  completeNeighborHouseholdMembers: =>
    return [] unless @["Household"]?
    _(@["Household Members"]).filter (householdMember) =>
      (householdMember.HeadofHouseholdName isnt @["Household"].HeadofHouseholdName or householdMember.HeadOfHouseholdName isnt @["Household"].HeadOfHouseholdName) and (householdMember.complete is "true" or householdMember.complete is true)

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
    if (@["Facility"]?.complete is "true" or @["Facility"]?.complete is true)
      return "#{@["Facility"].FirstName} #{@["Facility"].LastName}"
    if @["USSD Notification"]?
      return @["USSD Notification"]?.name
    if @["Case Notification"]?
      return @["Case Notification"]?.Name

  IndexCaseDiagnosisDate: ->
    if @["Facility"]?.DateOfPositiveResults?
      date = @["Facility"].DateOfPositiveResults
      momentDate = if date.match(/^20\d\d/)
        moment(@["Facility"].DateOfPositiveResults)
      else
        moment(@["Facility"].DateOfPositiveResults, "DD-MM-YYYY")
      return momentDate.format("YYYY-MM-DD") if momentDate.isValid()

    if @["USSD Notification"]?
      return moment(@["USSD Notification"].date).format("YYYY-MM-DD")

    else if @["Case Notification"]?
      return moment(@["Case Notification"].createdAt).format("YYYY-MM-DD")

  IndexCaseDiagnosisDateIsoWeek: =>
    indexCaseDiagnosisDate = @IndexCaseDiagnosisDate()
    if indexCaseDiagnosisDate
      moment(indexCaseDiagnosisDate).format("GGGG-WW")

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
    if @["Facility"]?.DateOfPositiveResults?
      date = @["Facility"].DateOfPositiveResults
      if date.match(/^20\d\d/)
        moment(@["Facility"].DateOfPositiveResults).format("YYYY-MM-DD")
      else
        moment(@["Facility"].DateOfPositiveResults, "DD-MM-YYYY").format("YYYY-MM-DD")

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
    if (@["Facility"]?.complete is "true" or @["Facility"]?.complete is true) and @["Case Notification"]?
      return moment(@["Facility"].lastModifiedAt.replace(/\+0\d:00/,"")).diff(@["Case Notification"]?.createdAt)

  daysFromCaseNotificationToCompleteFacility: =>
    if (@["Facility"]?.complete is "true" or @["Facility"]?.complete is true) and @["Case Notification"]?
      moment.duration(@timeFromCaseNotificationToCompleteFacility()).asDays()

  timeFromFacilityToCompleteHousehold: =>
    if (@["Household"]?.complete is "true" or @["Household"]?.complete is true) and @["Facility"]?
      return moment(@["Household"].lastModifiedAt.replace(/\+0\d:00/,"")).diff(@["Facility"]?.lastModifiedAt)

  timeFromSMSToCompleteHousehold: =>
    if (@["Household"]?.complete is "true" or @["Household"]?.complete is true) and @["USSD Notification"]?
      return moment(@["Household"].lastModifiedAt.replace(/\+0\d:00/,"")).diff(@["USSD Notification"]?.date)

  daysFromSMSToCompleteHousehold: =>
    if (@["Household"]?.complete is "true" or @["Household"]?.complete is true) and @["USSD Notification"]?
      moment.duration(@timeFromSMSToCompleteHousehold()).asDays()

  classificationsByHouseholdMemberType: =>
    _(for householdMember in @["Household Members"]
      if householdMember.CaseCategory 
        "#{householdMember.HouseholdMemberType}: #{householdMember.CaseCategory}"
    ).compact().join(", ")

  classificationsByDiagnosisDate: =>
    _(for householdMember in @["Household Members"]
      if householdMember.CaseCategory 
        "#{householdMember.DateOfPositiveResults}: #{householdMember.CaseCategory}"
    ).compact().join(", ")

  evidenceForClassifications: =>
    _(for householdMember in @["Household Members"]
      if householdMember.CaseCategory 
        "#{householdMember.CaseCategory}: #{householdMember.SummarizeEvidenceUsedForClassification}"
    ).compact().join(", ")

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

  summaryCollection: =>
    result = {}
    _(Case.summaryProperties).each (options, property) =>
      summaryResult = @summaryResult(property, options)
      # Don't overwrite data if it is already there
      # Not exactly sure why this is needed, but there seem to be 
      # Null duplicates that replace good data
      unless result[_(summaryResult).keys()[0]]?
        result = _(result).extend summaryResult
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
    # For now just look up at summaryResult function
    # propertyName is used to change the column name at the top of the CSV
    # otherPropertyNames is an array of other values to try and check

    # Case Notification
    MalariaCaseID:
      propertyName: "Malaria Case ID"
    indexCaseDiagnosisDate: {}
    IndexCaseDiagnosisDateIsoWeek:
      propertyName: "Index Case Diagnosis Date ISO Week"

    classificationsByHouseholdMemberType: {}
    classificationsByDiagnosisDate: {}
    evidenceForClassifications: {}

    # LostToFollowup: {}
    #
    namesOfAdministrativeLevels: {}

    district:
      propertyName: "District (if no household district uses facility)"
    facility: {}
    facilityType: {}
    facilityDistrict:
      propertyName: "District of Facility"
    shehia: {}
    isShehiaValid: {}
    highRiskShehia: {}
    village:
      propertyName: "Village"

    IndexCasePatientName:
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
    notCompleteFacilityAfter24Hours:
      propertyName: "Not Complete Facility After 24 Hours"
    notFollowedUpAfter48Hours:
      propertyName: "Not Followed Up After 48 Hours"
    notFollowedUpAfterXHours:
      propertyName: "Not Followed Up After X Hours"
    followedUpWithin48Hours:
      propertyName: "Followed Up Within 48 Hours"
    indexCaseHasTravelHistory: {}
    indexCaseHasNoTravelHistory: {}
    indexCaseSuspectedImportedCase: {}
    completeHouseholdVisit:
      propertyName: "Complete Household Visit"
    CompleteHouseholdVisit:
      propertyName: "Complete Household Visit"
    numberHouseholdMembersTestedAndUntested: {}
    numberHouseholdMembersTested: {}

    NumberPositiveCasesAtIndexHousehold: {}
    NumberHouseholdOrNeighborMembers: {}
    NumberPositiveCasesAtIndexHouseholdAndNeighborHouseholds: {}
    NumberHouseholdOrNeighborMembersTested: {}
    NumberPositiveCasesIncludingIndex: {}
    NumberPositiveCasesAtIndexHouseholdAndNeighborHouseholdsUnder5:
      propertyName: "Number Positive Cases At Index Household And Neighbor Households Under 5"
    NumberSuspectedImportedCasesIncludingHouseholdMembers: {}
    MassScreenCase: {}
    CaseIdForOtherHouseholdMemberThatTestedPositiveAtAHealthFacility:
      propertyName: "Case ID for Other Household Member That Tested Positive at a Health Facility"
    CommentRemarks: {}
    ContactMobilePatientRelative: {}
    HasSomeoneFromTheSameHouseholdRecentlyTestedPositiveAtAHealthFacility:
      propertyName: "Has Someone From the Same Household Recently Tested Positive at a Health Facility"
    HeadOfHouseholdName: {}
    ParasiteSpecies: {}
    ReferenceInOpdRegister:
      propertyName: "Reference In OPD Register"
    TravelledOvernightInPastMonth:
      propertyName: "Travelled Overnight in Past Month"
    IfYesListAllPlacesTravelled:
      propertyName: "All Places Traveled to in Past Month"
    TreatmentGiven: {}

    #Household
    CouponNumbers: {}
    FollowupNeighbors: {}
    HaveYouGivenCouponsForNets: {}
    HeadOfHouseholdName: {}
    HouseholdLocationAccuracy:
      propertyName: "Household Location - Accuracy"
    HouseholdLocationAltitude:
      propertyName: "Household Location - Altitude"
    HouseholdLocationAltitudeAccuracy:
      propertyName: "Household Location - Altitude Accuracy"
    HouseholdLocationDescription:
      propertyName: "Household Location - Description"
    HouseholdLocationHeading:
      propertyName: "Household Location - Heading"
    HouseholdLocationLatitude:
      propertyName: "Household Location - Latitude"
    HouseholdLocationLongitude:
      propertyName: "Household Location - Longitude"
    HouseholdLocationTimestamp:
      propertyName: "Household Location - Timestamp"
    IndexCaseIfPatientIsFemale1545YearsOfAgeIsSheIsPregant:
      propertyName: "Is Index Case Pregnant"
    IndexCaseOvernightTravelOutsideOfZanzibarInThePastYear:
      propertyName: "Has Index Case had Overnight Travel Outside of Zanzibar in the Past Year"
    IndexCaseOvernightTravelWithinZanzibar1024DaysBeforePositiveTestResult:
      propertyName: "Index Case Overnight Travel Within Zanzibar 10-24 Days Before Positive Test Result"
    TravelLocationName: {}
    AllLocationsAndEntryPointsFromOvernightTravelOutsideZanzibar07DaysBeforePositiveTestResult:
      propertyName: "All Locations and Entry Points From Overnight Travel Outside Zanzibar 0-7 Days Before Positive Test Result"
    AllLocationsAndEntryPointsFromOvernightTravelOutsideZanzibar814DaysBeforePositiveTestResult:
      propertyName: "All Locations and Entry Points From Overnight Travel Outside Zanzibar 8-14 Days Before Positive Test Result"
    AllLocationsAndEntryPointsFromOvernightTravelOutsideZanzibar1521DaysBeforePositiveTestResult:
      propertyName: "All Locations and Entry Points From Overnight Travel Outside Zanzibar 15-21 Days Before Positive Test Result"
    AllLocationsAndEntryPointsFromOvernightTravelOutsideZanzibar2242DaysBeforePositiveTestResult:
      propertyName: "All Locations and Entry Points From Overnight Travel Outside Zanzibar 22-42 Days Before Positive Test Result"
    AllLocationsAndEntryPointsFromOvernightTravelOutsideZanzibar43365DaysBeforePositiveTestResult:
      propertyName: "All Locations and Entry Points From Overnight Travel Outside Zanzibar 43-365 Days Before Positive Test Result"
    ListAllLocationsOfOvernightTravelWithinZanzibar1024DaysBeforePositiveTestResult:
      propertyName: "All Locations Of Overnight Travel Within Zanzibar 10-24 Days Before Positive Test Result"
    IndexCasePatient: {}
    IndexCasePatientSCurrentStatus:
      propertyName: "Index Case Patient's Current Status"
    IndexCasePatientSTreatmentStatus:
      propertyName: "Index Case Patient's Treatment Status"
    IndexCaseSleptUnderLlinLastNight:
      propertyName: "Index Case Slept Under LLIN Last Night"
    IndexCaseDiagnosisDate: {}
    LastDateOfIrs:
      propertyName: "Last Date Of IRS"
    NumberOfHouseholdMembersTreatedForMalariaWithinPastWeek:
      propertyName: "Number of Household Members Treated for Malaria Within Past Week"
    NumberOfHouseholdMembersWithFeverOrHistoryOfFeverWithinPastWeek:
      propertyName: "Number of Household Members With Fever or History of Fever Within Past Week"
    NumberOfLlin:
      propertyName: "Number Of LLIN"
    NumberOfSleepingPlacesBedsMattresses:
      propertyName: "Number of Sleeping Places (Beds/Mattresses)"
    NumberOfOtherHouseholdsWithin50StepsOfIndexCaseHousehold:
      propertyName: "Number of Other Households Within 50 Steps of Index Case Household"
    ReasonForVisitingHousehold: {}
    ShehaMjumbe:
      propertyName: "Sheha Mjumbe"
    TotalNumberOfResidentsInTheHousehold: {}

    DaysFromCaseNotificationToCompleteFacility: {}
    DaysFromSmsToCompleteHousehold:
      propertyName: "Days between SMS Sent to DMSO to Having Complete Household"

    DaysBetweenPositiveResultAndNotificationFromFacility: {}
    LessThanOneDayBetweenPositiveResultAndNotificationFromFacility: {}
    OneToTwoDaysBetweenPositiveResultAndNotificationFromFacility: {}
    TwoToThreeDaysBetweenPositiveResultAndNotificationFromFacility: {}
    MoreThanThreeDaysBetweenPositiveResultAndNotificationFromFacility: {}

    DaysBetweenPositiveResultAndCompleteHousehold: {}
    LessThanOneDayBetweenPositiveResultAndCompleteHousehold: {}
    OneToTwoDaysBetweenPositiveResultAndCompleteHousehold: {}
    TwoToThreeDaysBetweenPositiveResultAndCompleteHousehold: {}
    MoreThanThreeDaysBetweenPositiveResultAndCompleteHousehold: {}

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
## Old naming
    HeadofHouseholdName:
      propertyName: "Head Of Household Name"
    ContactMobilepatientrelative:
      propertyName: "Contact Mobile Patient Relative"
    IfYESlistALLplacestravelled:
      propertyName: "All Places Traveled to in Past Month"
    CaseIDforotherhouseholdmemberthattestedpositiveatahealthfacility:
      propertyName: "CaseID For Other Household Member That Tested Positive at a Health Facility"
    AgeinMonthsorYears:
      propertyName: "Age in Months or Years"
    TravelledOvernightinpastmonth:
      propertyName: "Travelled Overnight in Past Month"
    Hassomeonefromthesamehouseholdrecentlytestedpositiveatahealthfacility:
      propertyName: "Has Someone From The Same Household Recently Tested Positive at a Health Facility"
    Reasonforvisitinghousehold:
      propertyName: "Reason For Visiting Household"
    Ifyeslistallplacestravelled:
      propertyName: "If Yes List All Places Travelled"
    AgeinYearsorMonths:
      propertyName: "Age in Years or Months"
    Fevercurrentlyorinthelasttwoweeks:
      propertyName: "Fever Currently Or In The Last Two Weeks?"
    SleptunderLLINlastnight:
      propertyName: "Slept Under LLIN Last Night?"
    OvernightTravelinpastmonth:
      propertyName: "Overnight Travel in Past Month"
    ResidentofShehia:
      propertyName: "Resident of Shehia"
    TotalNumberofResidentsintheHousehold:
      propertyName: "Total Number of Residents in the Household"
    NumberofLLIN:
      propertyName: "Number of LLIN"
    NumberofSleepingPlacesbedsmattresses:
      propertyName: "Number of Sleeping Places (Beds/Mattresses)"
    NumberofHouseholdMemberswithFeverorHistoryofFeverWithinPastWeek:
      propertyName: "Number of Household Members With Fever or History of Fever Within Past Week"
    NumberofHouseholdMembersTreatedforMalariaWithinPastWeek:
      propertyName: "Number of Household Members Treated for Malaria Within Past Week"
    LastdateofIRS:
      propertyName: "Last Date of IRS"
    Haveyougivencouponsfornets:
      propertyName: "Have you given coupon(s) for nets?"
    IndexcaseIfpatientisfemale1545yearsofageissheispregant:
      propertyName: "Index Case: If Patient is Female 15-45 Years of Age, Is She Pregnant?"
    IndexcasePatientscurrentstatus:
      propertyName: "Index case: Patient's current status"
    IndexcasePatientstreatmentstatus:
      propertyName: "Index case: Patient's treatment status"
    indexCasePatientName:
      propertyName: "Patient Name"
    IndexcasePatient:
      propertyName: "Index Case Patient"
    IndexcaseSleptunderLLINlastnight:
      propertyName: "Index case: Slept under LLIN last night?"
    IndexcaseOvernightTraveloutsideofZanzibarinthepastyear:
      propertyName: "Index Case Overnight Travel Outside of Zanzibar in the Past Year"
    IndexcaseOvernightTravelwithinZanzibar1024daysbeforepositivetestresult:
      propertyName: "Index Case Overnight Travel Within Zanzibar 10-24 Days Before Positive Test Result"
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
    daysBetweenPositiveResultAndNotificationFromFacility:
      propertyName: "Days Between Positive Result at Facility and Case Notification"
    daysFromCaseNotificationToCompleteFacility:
      propertyName: "Days From Case Notification To Complete Facility"
    daysFromSMSToCompleteHousehold:
      propertyName: "Days between SMS Sent to DMSO to Having Complete Household"
    "HouseholdLocation-description":
      propertyName: "Household Location - Description"
    "HouseholdLocation-latitude":
      propertyName: "Household Location - Latitude"
    "HouseholdLocation-longitude":
      propertyName: "Household Location - Longitude"
    "HouseholdLocation-accuracy":
      propertyName: "Household Location - Accuracy"
    "HouseholdLocation-altitude":
      propertyName: "Household Location - Altitude"
    "HouseholdLocation-altitudeAccuracy":
      propertyName: "Household Location - Altitude Accuracy"
    "HouseholdLocation-heading":
      propertyName: "Household Location - Heading"
    "HouseholdLocation-timestamp":
      propertyName: "Household Location - Timestamp"
    travelLocationName:
      propertyName: "Travel Location Name"
    OvernightTravelwithinZanzibar1024daysbeforepositivetestresult:
      propertyName: "Overnight Travel Within Zanzibar 10-24 Days Before Positive Test Result"
    OvernightTraveloutsideofZanzibarinthepastyear:
      propertyName: "Overnight Travel Outside of Zanzibar In The Past Year"
    ReferredtoHealthFacility:
      propertyName: "Referred to Health Facility"
    indexCaseDiagnosisDate:
      propertyName: "Index Case Diagnosis Date"
    hasCompleteFacility:
      propertyName: "Has Complete Facility"
    notCompleteFacilityAfter24Hours:
      propertyName: "Not Complete Facility After 24 Hours"
    notFollowedUpAfter48Hours:
      propertyName: "Not Followed Up After 48 Hours"
    followedUpWithin48Hours:
      propertyName: "Followed Up Within 48Hours"
    indexCaseHasTravelHistory:
      propertyName: "Index Case Has Travel History"
    indexCaseHasNoTravelHistory:
      propertyName: "Index Case Has No Travel History"
    completeHouseholdVisit:
      propertyName: "Complete Household Visit"
    numberPositiveCasesAtIndexHousehold:
      propertyName: "Number Positive Cases At Index Household"
    numberPositiveCasesAtIndexHouseholdAndNeighborHouseholds:
      propertyName: "Number Positive Cases At Index Household And Neighbor Households"
    numberHouseholdOrNeighborMembersTested:
      propertyName: "Number Household Or Neighbor Members Tested"
    numberPositiveCasesIncludingIndex:
      propertyName: "Number Positive Cases Including Index"
    numberHouseholdOrNeighborMembers:
      propertyName: "Number Household Or Neighbor Members"
    numberPositiveCasesAtIndexHouseholdAndNeighborHouseholdsUnder5:
      propertyName: "Number Positive Cases At Index Household And Neighbor Households Under 5"
    numberSuspectedImportedCasesIncludingHouseholdMembers:
      propertyName: "Number Suspected Imported Cases Including Household Members"
    NumberofHouseholdMembersTreatedforMalariaWithinPastWeek:
      propertyName: "Number of Household Members Treated for Malaria Within Past Week"
    NumberofHouseholdMemberswithFeverorHistoryofFeverWithinPastWeek:
      propertyName: "Number of Household Members With Fever or History of Fever Within Past Week"
    massScreenCase:
      propertyName: "Mass Screen Case"
    TotalNumberofResidentsintheHousehold:
      propertyName: "Total Number Of Residents In The Household"
    daysBetweenPositiveResultAndNotificationFromFacility:
       propertyName: "Days Between Positive Result at Facility and Case Notification"
    lessThanOneDayBetweenPositiveResultAndNotificationFromFacility:
       propertyName: "Less Than One Day Between Positive Result And Notification From Facility"
    oneToTwoDaysBetweenPositiveResultAndNotificationFromFacility:
       propertyName: "One To Two Days Between Positive Result And Notification From Facility"
    twoToThreeDaysBetweenPositiveResultAndNotificationFromFacility:
       propertyName: "Two To Three Days Between Positive Result And Notification From Facility"
    moreThanThreeDaysBetweenPositiveResultAndNotificationFromFacility:
       propertyName: "More Than Three Days Between Positive Result And Notification From Facility"
    daysBetweenPositiveResultAndCompleteHousehold:
       propertyName: "Days Between Positive Result And Complete Household"
    lessThanOneDayBetweenPositiveResultAndCompleteHousehold:
      propertyName: "Less Than One Day Between Positive Result And Complete Household"
    oneToTwoDaysBetweenPositiveResultAndCompleteHousehold:
       propertyName: "One To Two Days Between Positive Result And Complete Household"
    twoToThreeDaysBetweenPositiveResultAndCompleteHousehold:
       propertyName: "Two To Three Days Between Positive Result And Complete Household"
    moreThanThreeDaysBetweenPositiveResultAndCompleteHousehold:
       propertyName: "More Than Three Days Between Positive Result And Complete Household"

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

Case.getLatestChangeForDatabase = ->
  new Promise (resolve,reject) =>
    Coconut.database.changes
      descending: true
      include_docs: false
      limit: 1
    .on "complete", (mostRecentChange) ->
      resolve(mostRecentChange.last_seq)
    .on "error", (error) ->
      reject error

Case.getLatestChangeForCurrentSummaryDataDocs = ->
  Coconut.reportingDatabase.get "CaseSummaryData"
  .catch (error) ->
    console.error "Error while getLatestChangeForCurrentSummaryDataDocs: #{error}"
    if error.reason is "missing"
      return Promise.resolve(null)
    else
      return Promise.reject("Non-missing error when getLatestChangeForCurrentSummaryDataDocs")
  .then (caseSummaryData) ->
    return Promise.resolve(caseSummaryData?.lastChangeSequenceProcessed or null)

Case.resetAllCaseSummaryDocs = (options)  =>
  # Delete all existing case_summary_ docs
  Coconut.reportingDatabase.allDocs
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

    try
      await Coconut.reportingDatabase.bulkDocs(docs)
      console.log "Existing case_summary_ docs deleted"

      latestChangeForDatabase = await Case.getLatestChangeForDatabase()

      console.log "Latest change: #{latestChangeForDatabase}"
      console.log "Retrieving all available case IDs"

      Coconut.database.query "cases/cases"
      .then (result) =>
        allCases = _(result.rows).chain().pluck("key").uniq(true).reverse().value()
        console.log "Updating #{allCases.length} cases"

        await Case.updateSummaryForCases
          caseIDs: allCases
        console.log "Updated: #{allCases.length} cases"

        Coconut.reportingDatabase.upsert "CaseSummaryData", (doc) =>
          doc.lastChangeSequenceProcessed = latestChangeForDatabase
          doc

    catch error
      console.error 

Case.updateCaseSummaryDocs = (options) ->

  latestChangeForDatabase = await Case.getLatestChangeForDatabase()
  latestChangeForCurrentSummaryDataDocs = await Case.getLatestChangeForCurrentSummaryDataDocs()
  #latestChangeForCurrentSummaryDataDocs = "3490519-g1AAAACseJzLYWBgYM5gTmEQTM4vTc5ISXIwNDLXMwBCwxygFFMiQ1JoaGhIVgZzEoPg_se5QDF2S3MjM8tkE2x68JgEMic0j4Vh5apVq7KAhu27jkcxUB1Q2Sog9R8IQMqPyGYBAJk5MBA"
  #
  console.log "latestChangeForDatabase: #{latestChangeForDatabase?.replace(/-.*/, "")}, latestChangeForCurrentSummaryDataDocs: #{latestChangeForCurrentSummaryDataDocs?.replace(/-.*/,"")}"

  if latestChangeForCurrentSummaryDataDocs
    numberLatestChangeForDatabase = parseInt(latestChangeForDatabase?.replace(/-.*/,""))
    numberLatestChangeForCurrentSummaryDataDocs = parseInt(latestChangeForCurrentSummaryDataDocs?.replace(/-.*/,""))

    if numberLatestChangeForDatabase - numberLatestChangeForCurrentSummaryDataDocs > 10000
      console.log "Large number of changes, so just resetting since this is more efficient that reviewing every change."
      return Case.resetAllCaseSummaryDocs()

  unless latestChangeForCurrentSummaryDataDocs 
    console.log "No recorded change for current summary data docs, so resetting"
    Case.resetAllCaseSummaryDocs()
  else
    #console.log "Getting changes since #{latestChangeForCurrentSummaryDataDocs.replace(/-.*/, "")}"
    # Get list of cases changed since latestChangeForCurrentSummaryDataDocs
    Coconut.database.changes
      since: latestChangeForCurrentSummaryDataDocs
      include_docs: true
      filter: "_view"
      view: "cases/cases"
    .then (result) =>
      return if result.results.length is 0
      #console.log "Found changes, now plucking case ids"
      changedCases = _(result.results).chain().map (change) ->
        change.doc.MalariaCaseID if change.doc.MalariaCaseID? and change.doc.question?
      .compact().uniq().value()
      #console.log "Changed cases: #{_(changedCases).length}"

      await Case.updateSummaryForCases
        caseIDs: changedCases
      console.log "Updated: #{changedCases.length} cases"

      Coconut.reportingDatabase.upsert "CaseSummaryData", (doc) =>
        doc.lastChangeSequenceProcessed = latestChangeForDatabase
        doc
      .catch (error) => console.error error
      .then =>
        console.log "CaseSummaryData updated through sequence: #{latestChangeForDatabase}"


Case.updateSummaryForCases = (options) =>
  new Promise (resolve, reject) =>
    
    docsToSave = []
    return resolve() if options.caseIDs.length is 0

    for caseID, counter in options.caseIDs
      console.log "#{caseID}: (#{counter+1}/#{options.caseIDs.length} #{Math.floor(((counter+1) / options.caseIDs.length) * 100)}%)"

      malariaCase = new Case
        caseID: caseID
      try
        await malariaCase.fetch()
      catch
        console.error "ERROR fetching case: #{caseID}"
        console.error error

      docId = "case_summary_#{caseID}"

      currentCaseSummaryDoc = null
      try 
         currentCaseSummaryDoc = await Coconut.reportingDatabase.get(docId)
      catch
        # Ignore if there is no document

      try
        updatedCaseSummaryDoc = malariaCase.summaryCollection()
      catch error
        console.error error

      updatedCaseSummaryDoc["_id"] = docId
      updatedCaseSummaryDoc._rev = currentCaseSummaryDoc._rev if currentCaseSummaryDoc?

      docsToSave.push updatedCaseSummaryDoc

      if docsToSave.length > 500
        try
          await Coconut.reportingDatabase.bulkDocs(docsToSave)
        catch
          console.error "ERROR SAVING #{docsToSave.length} case summaries: #{caseIDs.join ","}"
          console.error error
        docsToSave.length = 0 # Clear the array: https://stackoverflow.com/questions/1232040/how-do-i-empty-an-array-in-javascript

    try
      await Coconut.reportingDatabase.bulkDocs(docsToSave)
      resolve()
    catch error
      console.error "ERROR SAVING #{docsToSave.length} case summaries: #{caseIDs.join ","}"
      console.error error


### I think this can be removed
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
###

Case.createCaseView = (options) ->
  @case = options.case

  tables = [
    "Summary"
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
  finished = _.after tables.length, =>
    Coconut.caseview += _.map(tables, (tableType) =>
      if (tableType is "Summary")
        @createObjectTable(tableType,@case.summaryCollection())
      else if @case[tableType]?
        if tableType is "Household Members"
          _.map(@case[tableType], (householdMember) =>
            @createObjectTable(tableType,householdMember)
          ).join("")
        else
          @createObjectTable(tableType,@case[tableType])
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


Case.createObjectTable = (name,object) ->
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
              if (_.indexOf(['name','Name','FirstName','MiddleName','LastName','HeadOfHouseholdName','ContactMobilePatientRelative'],field) != -1)
                value = "************"
            return if "#{field}".match(/_id|_rev|collection/)
            "
              <tr>
                <td class='mdl-data-table__cell--non-numeric'>
                  #{
                   @mappings[field] or labels[field] or field
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

module.exports = Case
