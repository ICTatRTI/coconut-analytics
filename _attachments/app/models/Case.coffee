_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
moment = require 'moment'
Dhis2 = require './Dhis2'
CONST = require "../Constants"
humanize = require 'underscore.string/humanize'
titleize = require 'underscore.string/titleize'
PouchDB = require 'pouchdb-core'
radix64 = require('radix-64')()
HouseholdMember = require './HouseholdMember'

Question = require './Question'

Individual = require './Individual'
TertiaryIndex = require './TertiaryIndex'

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
        @caseID ?= resultDoc["MalariaCaseID"].trim()
        @questions.push resultDoc.question
        if resultDoc.question is "Household Members"
          this["Household Members"].push resultDoc
          householdMember = new HouseholdMember()
          householdMember.load(resultDoc)
          (@householdMembers or= []).push(householdMember)
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
              #console.warn "Using the result marked as complete"
              return #  Use the version already loaded which is marked as complete
            else if this[resultDoc.question].complete and resultDoc.complete
              console.warn "Duplicate complete entries for case: #{@caseID}"
          this[resultDoc.question] = resultDoc
      else
        @caseID ?= resultDoc["caseid"].trim()
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

  LastModifiedAt: =>
    _.chain(@toJSON())
    .map (data, question) ->
      if _(data).isArray()
        _(data).pluck("lastModifiedAt")
      else
        data?.lastModifiedAt
    .flatten()
    .max (lastModifiedAt) ->
      moment(lastModifiedAt).unix()
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

  allUserNamesString: => @allUserNames()?.join(", ")

  facility: ->
    @facilityUnit()?.name or "UNKNOWN"
    #@["Case Notification"]?.FacilityName.toUpperCase() or @["USSD Notification"]?.hf.toUpperCase() or @["Facility"]?.FacilityName or "UNKNOWN"

  facilityType: =>
    facilityUnit = @facilityUnit()
    unless facilityUnit?
      console.warn "Unknown facility name for: #{@caseID}. Returning UNKNOWN for facilityType."
      return "UNKNOWN"
    GeoHierarchy.facilityTypeForFacilityUnit(@facilityUnit())

  facilityDhis2OrganisationUnitId: =>
    GeoHierarchy.findFirst(@facility(), "FACILITY")?.id

  isShehiaValid: =>
    if @validShehia() then true else false

  validShehia: =>
    @shehiaUnit()?.name
    ###
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
    ###

  shehiaUnit: (shehiaName, districtName) =>
    if shehiaName? and GeoHierarchy.validShehia(shehiaName)
      # Can pass in a shehiaName - useful for positive Individuals with different focal area
    else
      shehiaName = null
      # Priority order to find the best facilityName
      for name in [@Household?.Shehia, @Facility?.Shehia,  @["Case Notification"]?.Shehia, @["USSD Notification"]?.shehia]
        continue unless name?
        name = name.trim()
        if GeoHierarchy.validShehia(name)
          shehiaName = name
          break

    unless shehiaName?
      # If we have no valid shehia name, then try and use facility
      return @facilityUnit()?.ancestorAtLevel("SHEHIA")
    else
      shehiaUnits = GeoHierarchy.find(shehiaName,"SHEHIA")

      if shehiaUnits.length is 1
        return shehiaUnits[0]
      else if shehiaUnits.length > 1
        # At this point we have a shehia name, but it is not unique, so we can use any data to select the correct one
        # Shehia names are not unique across Zanzibar, but they are unique per island
        # We also have region which is a level between district and island.
        # Strategy: get another sub-island location from the data, then limit the
        # list of shehias to that same island
        # * "District" that was passed in (used for focal areas)
        #     Is Shehia in district?
        # * "District" from Household
        #     Is Shehia in district?
        # * "District for Shehia" from Case Notification
        #     Is Shehia in district?
        # * Facility District
        #     Is Shehia in District
        # * Facility Name
        #     Is Shehia parent of facility
        # * If REGION for FACILTY unit matches one of the shehia's region
        # * If ISLAND for FACILTY unit matches one of the shehia's region
        for district in [districtName, @Household?["District"], @["Case Notification"]?["District for Shehia"], @["Case Notification"]?["District for Facility"], @["USSD Notification"]?.facility_district]
          continue unless district?
          district = district.trim()
          districtUnit = GeoHierarchy.findOneMatchOrUndefined(district, "DISTRICT")
          if districtUnit?
            for shehiaUnit in shehiaUnits
              if shehiaUnit.ancestorAtLevel("DISTRICT") is districtUnit
                return shehiaUnit
            # CHECK THE REGION LEVEL
            for shehiaUnit in shehiaUnits
              if shehiaUnit.ancestorAtLevel("REGION") is districtUnit.ancestorAtLevel("REGION")
                return shehiaUnit
            # CHECK THE ISLAND LEVEL
            for shehiaUnit in shehiaUnits
              if shehiaUnit.ancestorAtLevel("ISLAND") is districtUnit.ancestorAtLevel("ISLAND")
                return shehiaUnit

        # In case we couldn't find a facility district above, try and use the facility unit which comes from the name
        facilityUnit = @facilityUnit()
        if facilityUnit?
          facilityUnitShehia = facilityUnit.ancestorAtLevel("SHEHIA")
          for shehiaUnit in shehiaUnits
            if shehiaUnit is facilityUnitShehia
              return shehiaUnit

          for level in ["DISTRICT", "REGION", "ISLAND"]
            facilityUnitAtLevel = facilityUnit.ancestorAtLevel(level)
            for shehiaUnit in shehiaUnits
              shehiaUnitAtLevel = shehiaUnit.ancestorAtLevel(level)
              #console.log "shehiaUnitAtLevel: #{shehiaUnitAtLevel.id}: #{shehiaUnitAtLevel.name}"
              #console.log "facilityUnitAtLevel: #{facilityUnitAtLevel.id}: #{facilityUnitAtLevel.name}"
              if shehiaUnitAtLevel is facilityUnitAtLevel
                return shehiaUnit

  villageFromGPS: =>
    longitude = @householdLocationLongitude()
    latitude = @householdLocationLatitude()
    if longitude? and latitude?
      GeoHierarchy.villagePropertyFromGPS(longitude, latitude)


  shehiaUnitFromGPS: =>
    longitude = @householdLocationLongitude()
    latitude = @householdLocationLatitude()
    if longitude? and latitude?
      GeoHierarchy.findByGPS(longitude, latitude, "SHEHIA")

  shehiaFromGPS: =>
    @shehiaUnitFromGPS()?.name

  facilityUnit: =>
    facilityName = null
    # Priority order to find the best facilityName
    for name in [@Facility?.FacilityName, @["Case Notification"]?.FacilityName, @["USSD Notification"]?["hf"]]
      continue unless name?
      name = name.trim()
      if GeoHierarchy.validFacility(name)
        facilityName = name
        break

    if facilityName
      facilityUnits = GeoHierarchy.find(facilityName, "HEALTH FACILITIES")
      if facilityUnits.length is 1
        return facilityUnits[0]
      else if facilityUnits.length is 0
        return null
      else if facilityUnits.length > 1

        facilityDistrictName = null
        for name in [@Facility?.DistrictForFacility, @["Case Notification"]?.DistrictForFacility, @["USSD Notification"]?["facility_district"]]
          if name? and GeoHierarchy.validDistrict(name)
            facilityDistrictName = name
            break

        if facilityDistrictName?
          facilityDistrictUnits = GeoHierarchy.find(facilityDistrictName, "DISTRICT")
          for facilityUnit in facilityUnits
            for facilityDistrictUnit in facilityDistrictUnits
              if facilityUnit.ancestorAtLevel("DISTRICT") is facilityDistrictUnit
                return facilityUnit


  householdShehiaUnit: =>
    @shehiaUnit()

  householdShehia: =>
    @householdShehiaUnit()?.name

  shehia: ->
    returnVal = @validShehia()
    return returnVal if returnVal?


    # If no valid shehia is found, then return whatever was entered (or null)
    returnVal = @.Household?.Shehia || @.Facility?.Shehia || @["Case Notification"]?.shehia || @["USSD Notification"]?.shehia

    if @hasCompleteFacility()
      if @complete()
        console.warn "Case was followed up to household, but shehia name: #{returnVal} is not a valid shehia. #{@MalariaCaseID()}."
      else
        console.warn "Case was followed up to facility, but shehia name: #{returnVal} is not a valid shehia: #{@MalariaCaseID()}."

    return returnVal

  village: ->
    @["Facility"]?.Village

  facilityDistrict: ->
    facilityDistrict = @["USSD Notification"]?.facility_district
    unless facilityDistrict and GeoHierarchy.validDistrict(facilityDistrict)
      facilityDistrict = @facilityUnit()?.ancestorAtLevel("DISTRICT").name
    unless facilityDistrict
      #if @["USSD Notification"]?.facility_district is "WEST" and _(GeoHierarchy.find(@shehia(), "SHEHIA").map( (u) => u.ancestors()[0].name )).include "MAGHARIBI A" # MEEDS doesn't have WEST split
      #
      #
      # WEST got split, but DHIS2 uses A & B, so use shehia to figure out the right one
      if @["USSD Notification"]?.facility_district is "WEST"
        if shehia = @validShehia()
          for shehia in GeoHierarchy.find(shehia, "SHEHIA")
            if shehia.ancestorAtLevel("DISTRICT").name.match(/MAGHARIBI/)
              return shehia.ancestorAtLevel("DISTRICT").name
        else
          return "MAGHARIBI A"
        #Check the shehia to see if it is either MAGHARIBI A or MAGHARIBI B

      console.warn "Could not find a district for USSD notification: #{JSON.stringify @["USSD Notification"]}"
      return "UNKNOWN"
    GeoHierarchy.swahiliDistrictName(facilityDistrict)

  districtUnit: ->
    districtUnit = @shehiaUnit()?.ancestorAtLevel("DISTRICT") or @facilityUnit()?.ancestorAtLevel("DISTRICT")
    return districtUnit if districtUnit?

    for name in [@Facility?.DistrictForFacility, @["Case Notification"]?.DistrictForFacility, @["USSD Notification"]?["facility_district"]]
      if name? and GeoHierarchy.validDistrict(name)
        return GeoHierarchy.findOneMatchOrUndefined(name, "DISTRICT")

  district: =>
    @districtUnit()?.name or "UNKNOWN"

  islandUnit: =>
    @districtUnit()?.ancestorAtLevel("ISLANDS")

  island: =>
    @islandUnit()?.name or "UNKNOWN"

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
      console.warn "No district for case: #{@caseID}"

  # namesOfAdministrativeLevels
  # Nation, Island, Region, District, Shehia, Facility
  # Example:
  #"ZANZIBAR","PEMBA","KUSINI PEMBA","MKOANI","WAMBAA","MWANAMASHUNGI
  namesOfAdministrativeLevels: () =>
    district = @district()
    if district
      districtAncestors = _(GeoHierarchy.findFirst(district, "DISTRICT")?.ancestors()).pluck "name"
      result = districtAncestors.reverse().concat(district).concat(@shehia()).concat(@facility())
      result.join(",")

  possibleQuestions: ->
    ["Case Notification", "Facility","Household","Household Members"]

  questionStatus: =>
    result = {}
    _.each @possibleQuestions(), (question) =>
      if question is "Household Members"
        if @["Household Members"].length is 0
          result["Household Members"] = false
        else
          result["Household Members"] = true
          for member in @["Household Members"]
            unless member.complete? and (member.complete is true or member.complete is "true")
              result["Household Members"] = false 
      else
        result[question] = (@[question]?.complete is "true" or @[question]?.complete is true)
    return result

  lastQuestionCompleted: =>
    questionStatus = @questionStatus()
    for question in @possibleQuestions().reverse()
      return question if questionStatus[question]
    return "None"

  hasHouseholdMembersWithRepeatedNames: =>
    @repeatedNamesInSameHousehold() isnt null

  repeatedNamesInSameHousehold: =>
    names = {}

    for individual in @positiveAndNegativeIndividualObjects()
      name = individual.name()
      if name? and name isnt ""
        names[name] or= 0
        names[name] += 1

    repeatedNames = []
    for name, frequency of names
      if frequency > 1
        repeatedNames.push name

    if repeatedNames.length > 0
      return repeatedNames.join(", ")
    else
      return null

  oneAndOnlyOneIndexCase: =>
    numberOfIndexCases = 0
    for individual in @positiveIndividualObjects()
      if individual.data.HouseholdMemberType is "Index Case"
        numberOfIndexCases+=1
    console.log "numberOfIndexCases: #{numberOfIndexCases}" if numberOfIndexCases isnt 1
    return numberOfIndexCases is 1

  hasIndexCaseClassified: =>
    @classificationsByHouseholdMemberType().match(/Index Case/)

  complete: =>
    @questionStatus()["Household Members"] is true

  status: =>
    if @["Facility"]?["Lost To Followup"] is "Yes"
      return "Lost To Followup"
    else
      if @complete()
        return "Followed up"
      else
        returnVal = ""
        for question, status of @questionStatus()
          if status is false
            returnVal = if question is "Household Members" and not @hasIndexCaseClassified()
              "Household Members does not have a classified Index Case"
            else
              if question is "Household Member"
                "<a href='##{Coconut.databaseName}/show/results/Household%20Members'>#{question}</a> in Progress"
              else
                url = if @[question]?._id
                  "##{Coconut.databaseName}/edit/result/#{@[question]._id}"
                else
                  "##{Coconut.databaseName}/show/results/#{question}"
                "<a href='#{url}'>#{question}</a> in Progress"
            break
        returnVal


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

  completeHouseholdVisit: =>
    @complete()

  dateHouseholdVisitCompleted: =>
    if @completeHouseholdVisit()
      @.Household?.lastModifiedAt or @["Household Members"]?[0]?.lastModifiedAt or @Facility?.lastModifiedAt # When the household has two cases

  followedUp: =>
    @completeHouseholdVisit()

  # Includes any kind of travel including only within Zanzibar
  indexCaseHasTravelHistory: =>
    @.Facility?.TravelledOvernightinpastmonth?.match(/Yes/) or false

  indexCaseHasNoTravelHistory: =>
    not @indexCaseHasTravelHistory()

  location: (type) ->
    # Not sure how this works, since we are using the facility name with a database of shehias
    #WardHierarchy[type](@toJSON()["Case Notification"]?["FacilityName"])
    GeoHierarchy.findOneShehia(@toJSON()["Case Notification"]?["FacilityName"])?[type.toUpperCase()]

  withinLocation: (location) ->
    return @location(location.type) is location.name

  # This is just a count of househhold members not how many are positive
  # It excludes neighbor households
  completeIndexCaseHouseholdMembers: =>
    return [] unless @["Household"]?
    _(@["Household Members"]).filter (householdMember) =>
      # HeadOfHouseholdName used to determine if it is neighbor household
      (householdMember.HeadofHouseholdName is @["Household"].HeadofHouseholdName or householdMember.HeadOfHouseholdName is @["Household"].HeadOfHouseholdName) and 
      (householdMember.complete is "true" or householdMember.complete is true)

  hasCompleteIndexCaseHouseholdMembers: =>
    @completeIndexCaseHouseholdMembers().length > 0

  # Note that this doesn't include Index - this is unclear function name 
  positiveIndividualsAtIndexHousehold: =>
    console.warn "Function name not clear consider using positiveIndividualsExcludingIndex instead"
    _(@completeIndexCaseHouseholdMembers()).filter (householdMember) ->
      householdMember.MalariaTestResult is "PF" or 
      householdMember.MalariaTestResult is "Mixed" or
      (householdMember.CaseCategory and householdMember.HouseholdMemberType is "Other Household Member")


  ###
  numberPositiveIndividualsAtIndexHousehold: =>
    throw "Deprecated since name was confusing about whether index case was included, use numberPositiveIndividualsExcludingIndex"
    @positiveIndividualsAtIndexHousehold().length
  ###

  numberPositiveIndividualsExcludingIndex: =>
    @positiveIndividualsExcludingIndex().length

  hasAdditionalPositiveIndividualsAtIndexHousehold: =>
    @numberPositiveIndividualsExcludingIndex() > 0

  completeNeighborHouseholds: =>
    _(@["Neighbor Households"]).filter (household) =>
      household.complete is "true" or household.complete is true

  completeNeighborHouseholdMembers: =>
    return [] unless @["Household"]?
    _(@["Household Members"]).filter (householdMember) =>
      (householdMember.HeadOfHouseholdName isnt @["Household"].HeadOfHouseholdName) and (householdMember.complete is "true" or householdMember.complete is true)

  hasCompleteNeighborHouseholdMembers: =>
    @completeIndexCaseHouseholdMembers().length > 0

  positiveIndividualsAtNeighborHouseholds: ->
    _(@completeNeighborHouseholdMembers()).filter (householdMember) ->
      householdMember.MalariaTestResult is "PF" or 
      householdMember.MalariaTestResult is "Mixed" or
      (householdMember.CaseCategory and householdMember.HouseholdMemberType is "Other Household Member")

  ###
  # Handles pre-2019 and post-2019
  positiveIndividualsAtIndexHouseholdAndNeighborHouseholds: ->
    throw "Deprecated"
    _(@["Household Members"]).filter (householdMember) =>
      householdMember.MalariaTestResult is "PF" or 
      householdMember.MalariaTestResult is "Mixed" or
      (householdMember.CaseCategory and householdMember.HouseholdMemberType is "Other Household Member")
  ###

  positiveIndividualsUnder5: =>
    _(@positiveIndividuals()).filter (householdMemberOrNeighbor) =>
      age = @ageInYears(householdMemberOrNeighbor.Age, householdMemberOrNeighbor.AgeInYearsMonthsDays)
      age and age < 5

  positiveIndividualsOver5: =>
    _(@positiveIndividuals()).filter (householdMemberOrNeighbor) =>
      age = @ageInYears(householdMemberOrNeighbor.Age, householdMemberOrNeighbor.AgeInYearsMonthsDays)
      age and age >= 5

  numberPositiveIndividuals: ->
    @positiveIndividuals().length

  numberHouseholdMembers: ->
    @["Household Members"].length

  numberHouseholdMembersTestedAndUntested: =>
    numberHouseholdMembersFromHousehold = @["Household"]?["TotalNumberOfResidentsInTheHousehold"] or @["Household"]?["TotalNumberofResidentsintheHousehold"]
    numberHouseholdMembersWithRecord = @numberHouseholdMembers()
    # Some cases have more member records than TotalNumberofResidentsintheHousehold so use higher

    Math.max(numberHouseholdMembersFromHousehold, numberHouseholdMembersWithRecord)


  numberHouseholdMembersTested: =>
    numberHouseholdMemberRecordsWithTest = _(@["Household Members"]).filter (householdMember) =>
      switch householdMember.MalariaTestResult
        when "NPF", "PF", "Mixed"
          return true
      switch householdMember["MalariaTestPerformed"]
        when "mRDT", "Microscopy"
          return true
    .length

    # Check if we have pre 2019 data by checking for classifications
    # If there is no classification then either it was pre-2019 or followup is not done, so we need to add on an additional individual that was tested (index case)
    classifiedNonIndexCases = _(@["Household Members"]).filter (householdMember) => 
      householdMember.CaseCategory? and householdMember.HouseholdMemberType isnt "Index Case"
    # If there is at least a case notification then we know the index case was tested
    if classifiedNonIndexCases.length is 0
      numberHouseholdMemberRecordsWithTest+1
    else
      numberHouseholdMemberRecordsWithTest

  percentOfHouseholdMembersTested: =>
    (@numberHouseholdMembersTested()/@numberHouseholdMembersTestedAndUntested()*100).toFixed(0)

  updateIndividualIndex: =>
    @tertiaryIndex or= new TertiaryIndex
      name: "Individual"
    @tertiaryIndex.updateIndexForCases({caseIDs:[@MalariaCaseID()]})
  
  positiveIndividualObjects: =>
    for positiveIndividual in @positiveIndividuals()
      new Individual(positiveIndividual, @)

  positiveIndividuals: =>
    @positiveIndividualsIncludingIndex()

  #This function is good - don't use completeIndexCaseHouseholdMembers
  positiveIndividualsIncludingIndex: =>
    positiveIndividualsExcludingIndex = @positiveIndividualsExcludingIndex()
    positiveIndividualsIndexCasesOnly = @positiveIndividualsIndexCasesOnly()

    nonIndexHaveCaseCategory = _(positiveIndividualsExcludingIndex).any (positiveIndividual) ->
      positiveIndividual.CaseCategory?

    indexHaveCaseCategory = _(positiveIndividualsIndexCasesOnly).any (positiveIndividual) ->
      positiveIndividual.CaseCategory?

    # Don't try and find an index case if there are already classified individuals
    # Probably these just have the wrong Household Member Type
    results = if nonIndexHaveCaseCategory and not indexHaveCaseCategory
      positiveIndividualsExcludingIndex
    else
      positiveIndividualsIndexCasesOnly?.concat(positiveIndividualsExcludingIndex)

    for result in results
      result["Malaria Positive"] = true
      result

  positiveAndNegativeIndividuals: =>
    for individual in @positiveIndividuals().concat(@negativeIndividuals())
      individual["Date Of Malaria Results"] = @dateOfMalariaResultFromIndividual(individual)
      individual

  positiveAndNegativeIndividualObjects: =>
    for individual in @positiveAndNegativeIndividuals()
      new Individual(individual, @)

  positiveIndividualsExcludingIndex: =>
    # if we have classification then index is in the household member data
    # Only positive individuals have a case category e.g. imported, so filter for non null values
    classifiedNonIndexIndividuals = _(@["Household Members"]).filter (householdMember) => 
      householdMember.CaseCategory? and householdMember.HouseholdMemberType isnt "Index Case"
    results = if classifiedNonIndexIndividuals.length > 0
      classifiedNonIndexIndividuals
    else
      # If there is no classification then there will be no index case in the list of household members (pre 2019 style). This also includes neighbor households.
      _(@["Household Members"]).filter (householdMember) =>
        householdMember.MalariaTestResult is "PF" or 
        householdMember.MalariaTestResult is "Mixed"

    for result in results
      # Make sure 
      result.HouseholdMemberType = "Other Household Member"
      result

  positiveIndividualsIndexCasesOnly: =>
    # if we have classification then index is in the household member data
    # Only positive individuals have a case category e.g. imported, so filter for non null values
    classifiedIndexCases = @["Household Members"].filter (householdMember) -> 
      householdMember.CaseCategory isnt null and householdMember.HouseholdMemberType is "Index Case"
    if classifiedIndexCases.length > 0
      classifiedIndexCases
    else
      # Case hasn't been followed up yet or pre 2019 data which didn't capture index case as a household member, so use facility data for index and then check for positive household members
      extraProperties = {
        MalariaCaseID: @MalariaCaseID()
        HouseholdMemberType: "Index Case"
      }
      if @["Facility"]
        # Note that if you don't start with an empty object then the first argument gets mutated
        [_.extend {}, @["Facility"], @["Household"], extraProperties]
      else if @["USSD Notification"]
        [_.extend {}, @["USSD Notification"], @["Household"], extraProperties]
      else []



  negativeIndividuals: =>
    # I've reversed the logic of positiveIndividualsExcludingIndex
    # if we have classification then index is in the household member data
    # Only positive individuals have a case category e.g. imported, so filter for non null values
    classifiedIndividuals = []
    unclassifiedNonIndexIndividuals = []
    _(@["Household Members"]).map (householdMember) => 
      if householdMember.CaseCategory?
        classifiedIndividuals.push householdMember
      else if householdMember.HouseholdMemberType isnt "Index Case"
        # These are the ones we want but only if others are classified
        unclassifiedNonIndexIndividuals.push householdMember

    # if we have classification then index is in the household member data
    # So we can return the unclassified cases which must all be negative
    results = if classifiedIndividuals.length > 0
      unclassifiedNonIndexIndividuals
    else
      # If there is no classification then there will be no index case in the list of household members (pre 2019 style). This also includes neighbor households.
      _(@["Household Members"]).filter (householdMember) =>
        (householdMember.complete is true or householdMember.complete is "true") and
        householdMember.MalariaTestResult isnt "PF" and
        householdMember.MalariaTestResult isnt "Mixed"

    for result in results
      result["Date Of Malaria Results"] = @dateOfMalariaResultFromIndividual(result)
      result["Malaria Positive"] = false
      result


  numberPositiveIndividuals: =>
    @positiveIndividuals().length

  numberPositiveIndividualsUnder5: =>
    @positiveIndividualsUnder5().length

  numberPositiveIndividualsOver5: =>
    @positiveIndividualsOver5().length

  massScreenCase: =>
    @Household?["Reason for visiting household"]? is "Mass Screen"

  indexCasePatientName: ->
    if (@["Facility"]?.complete is "true" or @["Facility"]?.complete is true)
      return "#{@["Facility"].FirstName} #{@["Facility"].LastName}"
    if @["USSD Notification"]?
      return @["USSD Notification"]?.name
    if @["Case Notification"]?
      return @["Case Notification"]?.Name

  # Not sure why the casing is weird - put this in to support mobile client
  indexCaseDiagnosisDate: => @IndexCaseDiagnosisDate()

  IndexCaseDiagnosisDateAndTime: ->
    # If we don't have the hour/minute of the diagnosis date
    # Then assume that everyone gets tested at 8am
    if @["Facility"]?.DateAndTimeOfPositiveResults?
      return moment(@["Facility"]?.DateAndTimeOfPositiveResults).format("YYYY-MM-DD HH:mm")

    if @["Facility"]?.DateOfPositiveResults?
      date = @["Facility"].DateOfPositiveResults
      momentDate = if date.match(/^20\d\d/)
        moment(@["Facility"].DateOfPositiveResults)
      else
        moment(@["Facility"].DateOfPositiveResults, "DD-MM-YYYY")
      if momentDate.isValid()
        return momentDate.set(hour:0,minute:0).format("YYYY-MM-DD HH:mm")

    if @["USSD Notification"]?
      return moment(@["USSD Notification"].date).set(hour:0,minute:0).format("YYYY-MM-DD HH:mm")

    else if @["Case Notification"]?
      return moment(@["Case Notification"].createdAt).set(hour:0,minute:0).format("YYYY-MM-DD HH:mm")

  IndexCaseDiagnosisDate: =>
    if indexCaseDiagnosisDateAndTime = @IndexCaseDiagnosisDateAndTime()
      moment(indexCaseDiagnosisDateAndTime).format("YYYY-MM-DD")

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

  ageInYears: (age = @Facility?.Age, ageInMonthsYearsOrDays = (@Facility?.AgeinMonthsOrYears or @Facility?.AgeInYearsMonthsDays)) =>
    return null unless age? and ageInMonthsYearsOrDays?
    if ageInMonthsYearsOrDays is "Months"
      age / 12.0
    else if ageInMonthsYearsOrDays is "Days"
      age / 365.0
    else
      age

    ###
    return null unless @Facility
    if @Facility["Age in Months Or Years"]? and @Facility["Age in Months Or Years"] is "Months"
      @Facility["Age"] / 12.0
    else
      @Facility["Age"]
    ###


  isUnder5: =>
    ageInYears = @ageInYears()
    if ageInYears
      ageInYears < 5
    else
      null

  householdLocationLatitude: =>
    parseFloat(@Location?["LocationLatitude"] or @Household?["HouseholdLocationLatitude"] or @Household?["Household Location - Latitude"]) or @Household?["HouseholdLocation-latitude"]

  householdLocationLongitude: =>
    parseFloat(@Location?["LocationLongitude"] or @Household?["HouseholdLocationLongitude"] or @Household?["Household Location - Longitude"]) or @Household?["HouseholdLocation-longitude"]

  householdLocationAccuracy: =>
    parseFloat(@Location?["LocationAccuracy"] or @Household?["HouseholdLocationAccuracy"] or @Household?["Household Location - Accuracy"])

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


  dateOfPositiveResults: =>
    @IndexCaseDiagnosisDate()

  daysBetweenPositiveResultAndNotificationFromFacility: =>

    dateOfPositiveResults = @dateOfPositiveResults()

    notificationDate = if @["USSD Notification"]?
      @["USSD Notification"].date

    if dateOfPositiveResults? and notificationDate?
      Math.abs(moment(dateOfPositiveResults).diff(notificationDate, 'days'))

  estimatedHoursBetweenPositiveResultAndNotificationFromFacility: =>
    dateAndTimeOfPositiveResults = @IndexCaseDiagnosisDateAndTime()

    notificationDate = @["USSD Notification"]?.date or @["Case Notification"]?.createdAt

    if dateAndTimeOfPositiveResults? and notificationDate?
      Math.abs(moment(dateAndTimeOfPositiveResults).diff(notificationDate, 'hours'))

  lessThanOneDayBetweenPositiveResultAndNotificationFromFacility: =>
    if (daysBetweenPositiveResultAndNotificationFromFacility = @daysBetweenPositiveResultAndNotificationFromFacility())?
      daysBetweenPositiveResultAndNotificationFromFacility <= 1

  oneToTwoDaysBetweenPositiveResultAndNotificationFromFacility: =>
    if (daysBetweenPositiveResultAndNotificationFromFacility = @daysBetweenPositiveResultAndNotificationFromFacility())?
      daysBetweenPositiveResultAndNotificationFromFacility > 1 and
      daysBetweenPositiveResultAndNotificationFromFacility <= 2

  twoToThreeDaysBetweenPositiveResultAndNotificationFromFacility: =>
    if (daysBetweenPositiveResultAndNotificationFromFacility = @daysBetweenPositiveResultAndNotificationFromFacility())?
      daysBetweenPositiveResultAndNotificationFromFacility > 2 and
      daysBetweenPositiveResultAndNotificationFromFacility <= 3

  moreThanThreeDaysBetweenPositiveResultAndNotificationFromFacility: =>
    if (daysBetweenPositiveResultAndNotificationFromFacility = @daysBetweenPositiveResultAndNotificationFromFacility())?
      daysBetweenPositiveResultAndNotificationFromFacility > 3

  daysBetweenPositiveResultAndCompleteHousehold: =>
    dateOfPositiveResults = @dateOfPositiveResults()
    completeHouseholdVisit = @dateHouseholdVisitCompleted()

    if dateOfPositiveResults and completeHouseholdVisit
      Math.abs(moment(dateOfPositiveResults).diff(completeHouseholdVisit, 'days'))

  lessThanOneDayBetweenPositiveResultAndCompleteHousehold: =>
    if (daysBetweenPositiveResultAndCompleteHousehold = @daysBetweenPositiveResultAndCompleteHousehold())?
      daysBetweenPositiveResultAndCompleteHousehold <= 1

  oneToTwoDaysBetweenPositiveResultAndCompleteHousehold: =>
    if (daysBetweenPositiveResultAndCompleteHousehold = @daysBetweenPositiveResultAndCompleteHousehold())?
      daysBetweenPositiveResultAndCompleteHousehold > 1 and
      daysBetweenPositiveResultAndCompleteHousehold <= 2

  twoToThreeDaysBetweenPositiveResultAndCompleteHousehold: =>
    if (daysBetweenPositiveResultAndCompleteHousehold = @daysBetweenPositiveResultAndCompleteHousehold())?
      daysBetweenPositiveResultAndCompleteHousehold > 2 and
      daysBetweenPositiveResultAndCompleteHousehold <= 3

  moreThanThreeDaysBetweenPositiveResultAndCompleteHousehold: =>
    if (daysBetweenPositiveResultAndCompleteHousehold = @daysBetweenPositiveResultAndCompleteHousehold())?
      daysBetweenPositiveResultAndCompleteHousehold > 3

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

  householdComplete: =>
    @complete()

  timeOfHouseholdComplete: =>
    return null unless @householdComplete()
    latestLastModifiedTimeOfHouseholdMemberRecords = ""
    for householdMember in @["Household Members"]
      if householdMember.lastModifiedAt > latestLastModifiedTimeOfHouseholdMemberRecords
        latestLastModifiedTimeOfHouseholdMemberRecords = householdMember.lastModifiedAt
    latestLastModifiedTimeOfHouseholdMemberRecords

  timeFromFacilityToCompleteHousehold: =>
    if @householdComplete() and @["Facility"]?
      return moment(@timeOfHouseholdComplete().replace(/\+0\d:00/,"")).diff(@["Facility"]?.lastModifiedAt)

  timeFromSMSToCompleteHousehold: =>
    if @householdComplete() and @["USSD Notification"]?
      return moment(@timeOfHouseholdComplete().replace(/\+0\d:00/,"")).diff(@["USSD Notification"]?.date)

  hoursFromNotificationToCompleteHousehold: => 
    Math.floor(moment.duration(@timeFromSMSToCompleteHousehold()).asHours())

  daysFromSMSToCompleteHousehold: =>
    if @householdComplete() and @["USSD Notification"]?
      moment.duration(@timeFromSMSToCompleteHousehold()).asDays()

  odkClassification: =>
    if @["ODK 2017-2019"]
      switch @["ODK 2017-2019"]["case_classification:case_category"]
        when 1 then "Imported"
        when 2,3 then "Indigenous"
        when 4 then "Induced"
        when 5 then "Relapsing"

  classificationsWithPositiveIndividualObjects: =>
    for positiveIndividual in @positiveIndividualObjects()
      {
        classification: positiveIndividual.classification()
        positiveIndividual: positiveIndividual
      }

  classificationsBy: (property) =>
    (for data in @classificationsWithPositiveIndividualObjects()
      "#{data.positiveIndividual.data[property]}: #{data.classification}"
    ).join(", ")

  classificationsByFunction: (functionName) =>
    (for data in @classificationsWithPositiveIndividualObjects()
      "#{data.positiveIndividual[functionName]()}: #{data.classification}"
    ).join(", ")

  classificationsByHouseholdMemberType: =>
    # IF household member type is undefined it is either:
    # in progress index case
    # pre 2019 household member
    (for data in @classificationsWithPositiveIndividualObjects()
      if data.positiveIndividual.data.question isnt "Household Members"
        "Index Case: #{data.classification}"
      else if data.positiveIndividual.data["HouseholdMemberType"] is undefined
        "Household Member: #{data.classification}"
      else
        "#{data.positiveIndividual.data["HouseholdMemberType"]}: #{data.classification}"
    ).join(", ")

  classificationsByDiagnosisDate: =>
    @classificationsByFunction("dateOfPositiveResults")

  classificationsByIsoYearIsoWeekFociDistrictFociShehia: =>
    (for classificationWithPositiveIndividual in @classificationsWithPositiveIndividualObjects()
      classification = classificationWithPositiveIndividual.classification
      positiveIndividual = classificationWithPositiveIndividual.positiveIndividual
      dateOfPositiveResults = positiveIndividual.dateOfPositiveResults()
      date = if dateOfPositiveResults
        moment(dateOfPositiveResults)
      else 
        # Use index case date if we are missing positiveIndividual's date
        if dateOfPositiveResults = @dateOfPositiveResults()
          moment(dateOfPositiveResults)

      if date?
        isoYear = date.isoWeekYear()
        isoWeek = date.isoWeek()

      fociDistrictShehia = if (focus = positiveIndividual.data["WhereCouldTheMalariaFocusBe"])
        focus = focus.trim()
        if focus is "Patient Shehia"
          [@district(), @shehia()]
        else if focus is "Other Shehia Within Zanzibar"
          otherDistrict = positiveIndividual.data["WhichOtherDistrictWithinZanzibar"]
          otherShehia = positiveIndividual.data["WhichOtherShehiaWithinZanzibar"]
          shehiaUnit = @shehiaUnit(otherShehia, otherDistrict)
          [
            shehiaUnit?.ancestorAtLevel("DISTRICT")?.name or @district()
            shehiaUnit?.name or @shehia()
          ]
        else
          [@district(), @shehia()]
      else if positiveIndividual.data.HouseholdMemberType is "Index Case" and (odkData = @["ODK 2017-2019"])


        #TODO waiting to find out which ODK questions were used for this
        [@district(), @shehia()]
      else
        [@district(), @shehia()]

      [fociDistrict,fociShehia] = fociDistrictShehia

      "#{isoYear}:#{isoWeek}:#{fociDistrict}:#{fociShehia}:#{classification}"

    ).join(", ")

  evidenceForClassifications: =>
    _(for householdMember in @["Household Members"]
      if householdMember.CaseCategory 
        "#{householdMember.CaseCategory}: #{householdMember.SummarizeEvidenceUsedForClassification}"
    ).compact().join(", ")


  concatenateHouseholdMembers: (property) =>
    _(for householdMember in @["Household Members"]
      if householdMember.CaseCategory
        "#{householdMember.CaseCategory}: #{householdMember[property]}"
    ).compact().join(", ")

  occupations: =>
    @concatenateHouseholdMembers("Occupation")

  numbersSentTo: =>
    @["USSD Notification"]?.numbersSentTo?.join(", ")


  # Data properties above #
  # ------------- #

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
    priorityOrder = options?.priorityOrder or [
      "Household"
      "Facility"
      "Case Notification"
      "USSD Notification"
    ]

    if property.match(/:/)
      propertyName = property
      priorityOrder = [property.split(/: */)[0]]

    # If prependQuestion then we only want to search within that question
    priorityOrder = [options.prependQuestion] if options?.prependQuestion

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

    result = @[options.functionName]() if options?.functionName
    result = @[property]() if result is null and @[property]
    result = findPrioritizedProperty() if result is null

    if result is null
      result = findPrioritizedProperty(options.otherPropertyNames) if options?.otherPropertyNames

    result = JSON.stringify(result) if _(result).isObject()

    if _(result).isString()
      result = result?.trim()

    if options?.propertyName
      property = options.propertyName
    else
      property = titleize(humanize(property))

    if options?.prependQuestion
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
    IndexCaseDiagnosisDate:
      propertyName: "Index Case Diagnosis Date"
    IndexCaseDiagnosisDateIsoWeek:
      propertyName: "Index Case Diagnosis Date ISO Week"
    IndexCaseDiagnosisDateAndTime:
      propertyName: "Index Case Diagnosis Date And Time"

    classificationsByHouseholdMemberType: {}
    classificationsByDiagnosisDate: {}
    classificationsByIsoYearIsoWeekFociDistrictFociShehia: {}
    evidenceForClassifications: {}
    reasonForLostToFollowup: {}

    namesOfAdministrativeLevels: {}

    island: {}

    district: {}
    facility: {}
    facilityType: {}
    facilityDistrict:
      propertyName: "District of Facility"
    shehia: {}
    shehiaFromGPS: {}
    isShehiaValid: {}
    highRiskShehia: {}
    village:
      propertyName: "Village"
    villageFromGPS: {}

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

    lastQuestionCompleted: {}

    hasCompleteFacility: {}
    notCompleteFacilityAfter24Hours:
      propertyName: "Not Complete Facility After 24 Hours"
    notFollowedUpAfter48Hours:
      propertyName: "Not Followed Up After 48 Hours"
    notFollowedUpAfterXHours:
      propertyName: "Not Followed Up After X Hours"
    followedUpWithin48Hours:
      propertyName: "Followed Up Within 48 Hours"
    completeHouseholdVisit:
      propertyName: "Complete Household Visit"
    CompleteHouseholdVisit:
      propertyName: "Complete Household Visit"
    numberHouseholdMembersTestedAndUntested: {}
    numberHouseholdMembersTested: {}

    NumberPositiveIndividualsAtIndexHousehold: {}
    NumberHouseholdOrNeighborMembers: {}
    NumberPositiveIndividualsAtIndexHouseholdAndNeighborHouseholds: {}
    NumberHouseholdOrNeighborMembersTested: {}
    NumberPositiveIndividualsIncludingIndex: {}
    NumberPositiveIndividualsAtIndexHouseholdAndNeighborHouseholdsUnder5:
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
    TreatmentGiven: {}

    #Household
    CouponNumbers: {}
    FollowupNeighbors: {}
    HaveYouGivenCouponsForNets: {}
    HeadOfHouseholdName: {}
    HouseholdLocationAccuracy:
      propertyName: "Household Location - Accuracy"
      functionName: "householdLocationAccuracy"
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
      functionName: "householdLocationLatitude"
    HouseholdLocationLongitude:
      propertyName: "Household Location - Longitude"
      functionName: "householdLocationLongitude"
    HouseholdLocationTimestamp:
      propertyName: "Household Location - Timestamp"
    IndexCaseIfPatientIsFemale1545YearsOfAgeIsSheIsPregant:
      propertyName: "Is Index Case Pregnant"
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
    TravelledOvernightinpastmonth:
      propertyName: "Travelled Overnight in Past Month"
    Hassomeonefromthesamehouseholdrecentlytestedpositiveatahealthfacility:
      propertyName: "Has Someone From The Same Household Recently Tested Positive at a Health Facility"
    Reasonforvisitinghousehold:
      propertyName: "Reason For Visiting Household"
    Ifyeslistallplacestravelled:
      propertyName: "If Yes List All Places Travelled"
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
    daysBetweenPositiveResultAndNotificationFromFacility: {}
    estimatedHoursBetweenPositiveResultAndNotificationFromFacility: {}
    daysFromCaseNotificationToCompleteFacility:
      propertyName: "Days From Case Notification To Complete Facility"
    daysFromSMSToCompleteHousehold:
      propertyName: "Days between SMS Sent to DMSO to Having Complete Household"
    "HouseholdLocation-description":
      propertyName: "Household Location - Description"
    "HouseholdLocation-latitude":
      propertyName: "Household Location - Latitude"
      functionName: "householdLocationLatitude"
    "HouseholdLocation-longitude":
      propertyName: "Household Location - Longitude"
      functionName: "householdLocationLongitude"
    "HouseholdLocation-accuracy":
      propertyName: "Household Location - Accuracy"
      functionName: "householdLocationAccuracy"
    "HouseholdLocation-altitude":
      propertyName: "Household Location - Altitude"
    "HouseholdLocation-altitudeAccuracy":
      propertyName: "Household Location - Altitude Accuracy"
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
    hasCompleteFacility:
      propertyName: "Has Complete Facility"
    notCompleteFacilityAfter24Hours:
      propertyName: "Not Complete Facility After 24 Hours"
    notFollowedUpAfter48Hours:
      propertyName: "Not Followed Up After 48 Hours"
    followedUpWithin48Hours:
      propertyName: "Followed Up Within 48Hours"
    completeHouseholdVisit:
      propertyName: "Complete Household Visit"
    numberPositiveIndividualsExcludingIndex:
      propertyName: "Number Positive Individuals At Household Excluding Index"
    numberPositiveIndividualsAtIndexHouseholdAndNeighborHouseholds:
      propertyName: "Number Positive Cases At Index Household And Neighbor Households"
    numberPositiveIndividuals:
      propertyName: "Number Positive Individuals"
    numberPositiveIndividualsUnder5:
      propertyName: "Number Positive Individuals Under 5"
    numberPositiveIndividualsOver5:
      propertyName: "Number Positive Individuals Over 5"
    NumberofHouseholdMembersTreatedforMalariaWithinPastWeek:
      propertyName: "Number of Household Members Treated for Malaria Within Past Week"
    NumberofHouseholdMemberswithFeverorHistoryofFeverWithinPastWeek:
      propertyName: "Number of Household Members With Fever or History of Fever Within Past Week"
    massScreenCase:
      propertyName: "Mass Screen Case"
    TotalNumberofResidentsintheHousehold:
      propertyName: "Total Number Of Residents In The Household"
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
    occupations: {}

    dhis2CasesByTypeOfDetection:
      propertyName: "DHIS2 Cases by Type of Detection"
    dhis2CasesByClassification:
      propertyName: "DHIS2 Cases by Classification"
    dhis2CasesByAge:
      propertyName: "DHIS2 Cases by Age"
    dhis2CasesByGender:
      propertyName: "DHIS2 Cases by Gender"

    allUserNamesString:
      propertyName: "Malaria Surveillance Officers"

    wasTransferred: {}

    DmsoVerifiedResults: {}
    CaseInvestigationStatus: {}
    HasTheHouseReceivedIrsInTheLast12Months: {}
    LastYearOfIRS: {}
    LastMonthOfIRS: {}

  }

  dateOfMalariaResultFromIndividual: (positiveIndividual) =>
    # First try and get the individuals' date, then the createdAt time (pre-2019) if all fails just use the date for the case or the date that the notification was made
    date = positiveIndividual.DateOfPositiveResults or positiveIndividual.createdAt or @dateOfPositiveResults() or positiveIndividual.date
    moment(date).format("YYYY-MM-DD")

  dhis2CasesByTypeOfDetection: =>
    result = {}

    for positiveIndividual in @positiveIndividualsIndexCasesOnly()
      date = @dateOfMalariaResultFromIndividual(positiveIndividual)
      shehia = @shehia()
      if date and shehia
        result[date] or= {}
        result[date][shehia] or= {
          "Passive": 0
          "Active": 0
        }
        result[date][shehia]["Passive"] += 1

    for positiveIndividual in @positiveIndividualsExcludingIndex()
      date = @dateOfMalariaResultFromIndividual(positiveIndividual)
      shehia = @shehia()
      if date and shehia
        result[date] or= {}
        result[date][shehia] or= {
          "Passive": 0
          "Active": 0
        }
        result[date][shehia]["Active"] += 1

    result

  dhis2CasesByClassification: =>
    result = {}
    for positiveIndividual in @positiveIndividualsIncludingIndex()
      date = @dateOfMalariaResultFromIndividual(positiveIndividual)
      shehia = @shehia()
      if date and shehia
        result[date] or= {}
        result[date][shehia] or= {}
        result[date][shehia][positiveIndividual.CaseCategory or "Unclassified"] or= 0
        result[date][shehia][positiveIndividual.CaseCategory or "Unclassified"] += 1

    result

  dhis2CasesByAge: =>
    result = {}
    for positiveIndividual in @positiveIndividualsIncludingIndex()
      age = @ageInYears(positiveIndividual.Age, positiveIndividual.AgeInYearsMonthsDays)
      ageRange = if age?
        switch
          when age < 5 then "<5 yrs"
          when age < 15 then "5<15 yrs"
          when age < 25 then "15<25 yrs"
          when age >= 25 then ">25 yrs"
          else "Unknown"
      else
        "Unknown"

      date = @dateOfMalariaResultFromIndividual(positiveIndividual)
      shehia = @shehia()
      if date and shehia
        result[date] or= {}
        result[date][shehia] or= {}
        result[date][shehia][ageRange] or= 0
        result[date][shehia][ageRange] += 1

    result

  dhis2CasesByGender: =>
    result = {}
    for positiveIndividual in @positiveIndividualsIncludingIndex()

      date = @dateOfMalariaResultFromIndividual(positiveIndividual)
      shehia = @shehia()
      if date and shehia
        gender = positiveIndividual.Sex
        if gender isnt "Male" and gender isnt "Female" then gender = "Unknown"
        result[date] or= {}
        result[date][shehia] or= {}
        result[date][shehia][gender] or=0
        result[date][shehia][gender] += 1

    result

  saveAndAddResultToCase: (result) =>
    if @[result.question]?
      console.error "#{result.question} already exists for:"
      console.error @
      return
    resultQuestion = result.question
    Coconut.database.put result
    .then (result) =>
      console.log "saved:"
      console.log result
      @questions.push result.question
      @[result.question] = result
      Coconut.headerView.update()
      Coconut.showNotification( "#{resultQuestion} record created")
    .catch (error) ->
      console.error error

  createNextResult: =>
    @fetch
      error: -> console.error error
      success: =>
        if @["Household Members"] and @["Household Members"].length > 0
          console.log "Household Members exists, no result created"
          # Don't create anything
        else if @Household?.complete
          console.log "Creating Household members and neighbor households if necessary"
          @createHouseholdMembers()
          @createNeighborHouseholds()
        else if @Facility?.complete
          console.log "Creating Household"
          @createHousehold()
        else if @["Case Notification"]?.complete
          console.log "Creating Facility"
          @createFacility()
        _.delay(Coconut.menuView.render, 500)

  createFacility: =>
    @saveAndAddResultToCase
      _id: "result-case-#{@caseID}-Facility-#{radix64.encodeInt(moment().format('x'))}-#{Coconut.instanceId}"
      question: "Facility"
      MalariaCaseID: @caseID
      DistrictForFacility: @facilityDistrict()
      FacilityName: @facility()
      DistrictForShehia: @shehiaUnit().ancestorAtLevel("DISTRICT")?.name
      Shehia: @shehia()
      collection: "result"
      createdAt: moment(new Date()).format(Coconut.config.get "date_format")
      lastModifiedAt: moment(new Date()).format(Coconut.config.get "date_format")

  createHousehold: =>
    @saveAndAddResultToCase
      _id: "result-case-#{@caseID}-Household-#{radix64.encodeInt(moment().format('x'))}-#{Coconut.instanceId}"
      question: "Household"
      Reasonforvisitinghousehold: "Index Case Household"
      MalariaCaseID: @caseID
      HeadOfHouseholdName: @Facility.HeadOfHouseholdName
      District: @district()
      Shehia: @shehia()
      Village: @Facility.Village
      ShehaMjumbe: @Facility.ShehaMjumbe
      ContactMobilePatientRelative: @Facility.ContactMobilePatientRelative
      collection: "result"
      createdAt: moment(new Date()).format(Coconut.config.get "date_format")
      lastModifiedAt: moment(new Date()).format(Coconut.config.get "date_format")

  createHouseholdMembers: =>
    unless _(@questions).contains 'Household Members'
      _(@Household.TotalNumberOfResidentsInTheHousehold).times (index) =>
        result = {
          _id: "result-case-#{@caseID}-Household-Members-#{radix64.encodeInt(moment().format('x'))}-#{radix64.encodeInt(Math.round(Math.random()*100000))}-#{Coconut.instanceId}" # There's a chance moment will be the same so add some randomness
          question: "Household Members"
          MalariaCaseID: @caseID
          HeadOfHouseholdName: @Household.HeadOfHouseholdName
          collection: "result"
          createdAt: moment(new Date()).format(Coconut.config.get "date_format")
          lastModifiedAt: moment(new Date()).format(Coconut.config.get "date_format")
        }

        if index is 0
          _(result).extend
            HouseholdMemberType: "Index Case"
            FirstName: @Facility?.FirstName
            LastName: @Facility?.LastName
            DateOfPositiveResults: @Facility?.DateOfPositiveResults
            DateAndTimeOfPositiveResults: @Facility?.DateAndTimeOfPositiveResults
            Sex: @Facility?.Sex
            Age: @Facility?.Age
            AgeInYearsMonthsDays: @Facility?.AgeInYearsMonthsDays
            MalariaMrdtTestResults: @Facility?.MalariaMrdtTestResults
            MalariaTestPerformed: @Facility?.MalariaTestPerformed

        Coconut.database.put result
        .then =>
          @questions.push result.question
          @[result.question] = [] unless @[result.question]
          @[result.question].push result
        .catch (error) ->
          console.error error

      Coconut.headerView.update()
      Coconut.showNotification( "Household member record(s) created")

  createNeighborHouseholds: =>
    # If there is more than one Household for this case, then Neighbor households must already have been created
    unless (_(@questions).filter (question) -> question is 'Household').length is 1
      _(@Household.NumberOfOtherHouseholdsWithin50StepsOfIndexCaseHousehold).times =>

        result = {
          _id: "result-case-#{@caseID}-Household-#{radix64.encodeInt(moment().format('x'))}-#{radix64.encodeInt(Math.round(Math.random()*100000))}-#{Coconut.instanceId}" # There's a chance moment will be the same so add some randomness
          ReasonForVisitingHousehold: "Index Case Neighbors"
          question: "Household"
          MalariaCaseID: @result.get "MalariaCaseID"
          Shehia: @result.get "Shehia"
          Village: @result.get "Village"
          ShehaMjumbe: @result.get "ShehaMjumbe"
          collection: "result"
          createdAt: moment(new Date()).format(Coconut.config.get "date_format")
          lastModifiedAt: moment(new Date()).format(Coconut.config.get "date_format")
        }

        Coconut.database.put result
        .then =>
          Coconut.headerView.update()
        .catch (error) ->
          console.error error

      Coconut.showNotification( "Neighbor Household created")

  wasTransferred: =>
    @transferData().length > 0

  transferData: =>
    transferData = []
    for question in @questions
      if @[question].transferred
        data = @[question].transferred
        data["question"] = question
        transferData.push data

    transferData

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
    cases = _.chain(result.rows)
      .groupBy (row) =>
        row.key
      .map (resultsByCaseID) =>
        malariaCase = new Case
          results: _.pluck resultsByCaseID, "doc"
        malariaCase
      .compact()
      .value()

    options?.success?(cases)
    Promise.resolve(cases)


# Used on mobile client
Case.getCasesSummaryData = (startDate, endDate) =>
  Coconut.database.query "casesWithSummaryData",
    startDate: startDate
    endDate: endDate
    descending: true
    include_docs: true
  .catch (error) =>
    console.error JSON.stringify error
  .then (result) =>
    _(result.rows).chain().map (row) =>
      row.doc.MalariaCaseID ?= row.key  # For case docs without MalariaCaseID add it (caseid etc)
      row.doc
    .groupBy "MalariaCaseID"
    .map (resultDocs, malariaCaseID) =>
      new Case
        caseID: malariaCaseID
        results: resultDocs
    .value()


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
  # Docs to save
  designDocs = await Coconut.reportingDatabase.allDocs
    startkey: "_design"
    endkey: "_design\uf777"
    include_docs: true
  .then (result) ->
    Promise.resolve _(result.rows).map (row) ->
      doc = row.doc
      delete doc._rev
      doc

  otherDocsToSave = await Coconut.reportingDatabase.allDocs
    include_docs: true
    keys: [
      "shehia metadata"
    ]
  .then (result) ->
    console.log result
    Promise.resolve( _(result.rows).chain().map (row) ->
        doc = row.doc
        delete doc._rev if doc
        doc
      .compact().value()
    )

  docsToSave = designDocs.concat(otherDocsToSave)
  reportingDatabaseNameWithCredentials = Coconut.reportingDatabase.name

  await Coconut.reportingDatabase.destroy()
  .catch (error) -> 
    console.error error
    throw "Error while destroying database"

  Coconut.reportingDatabase = new PouchDB(reportingDatabaseNameWithCredentials)
  await Coconut.reportingDatabase.bulkDocs docsToSave

  try
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

    if numberLatestChangeForDatabase - numberLatestChangeForCurrentSummaryDataDocs > 50000
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
    
    return resolve() if options.caseIDs.length is 0

    numberOfCasesToProcess = options.caseIDs.length
    numberOfCasesProcessed = 0
    numberOfCasesToProcessPerIteration = 100

    while options.caseIDs.length > 0
      caseIDs = options.caseIDs.splice(0,numberOfCasesToProcessPerIteration) # remove 100 caseids

      cases = await Case.getCases
        caseIDs: caseIDs

      docsToSave = []
      for malariaCase in cases
        caseID = malariaCase.caseID

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

      try
        await Coconut.reportingDatabase.bulkDocs(docsToSave)
      catch error
        console.error "ERROR SAVING #{docsToSave.length} case summaries: #{caseIDs.join ","}"
        console.error error

      numberOfCasesProcessed += caseIDs.length
      console.log "#{numberOfCasesProcessed}/#{numberOfCasesToProcess} #{Math.floor(numberOfCasesProcessed/numberOfCasesToProcess*100)}% (last ID: #{caseIDs.pop()})"
    resolve()


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
  
Case.setup = =>
  new Promise (resolve) =>

    for docId in ["shehias_high_risk","shehias_received_irs"]
      await Coconut.database.get docId
      .catch (error) -> console.error JSON.stringify error
      .then (result) ->
        Coconut[docId] = result
        Promise.resolve()

    designDocs = {
      cases: (doc) ->
        emit(doc.MalariaCaseID, null) if doc.MalariaCaseID
        emit(doc.caseid, null) if doc.caseid

      casesWithSummaryData: (doc) ->
        if doc.MalariaCaseID
          date = doc.DateofPositiveResults or doc.lastModifiedAt
          match = date.match(/^(\d\d).(\d\d).(2\d\d\d)/)
          if match?
            date = "#{match[3]}-#{match[2]}-#{match[1]}"

          if doc.transferred?
            lastTransfer = doc.transferred[doc.transferred.length-1]

          if date.match(/^2\d\d\d\-\d\d-\d\d/)
            emit date, [doc.MalariaCaseID,doc.question,doc.complete,lastTransfer]

        if doc.caseid
          if document.transferred?
            lastTransfer = doc.transferred[doc.transferred.length-1]
          if doc.date.match(/^2\d\d\d\-\d\d-\d\d/)
            emit doc.date, [doc.caseid, "Facility Notification", null, lastTransfer]

    }

    for name, designDocFunction of designDocs
      designDoc = Utils.createDesignDoc name, designDocFunction
      await Coconut.database.upsert designDoc._id, (existingDoc) =>
        return false if _(designDoc.views).isEqual(existingDoc?.views)
        console.log "Creating Case view: #{name}"
        designDoc
      .catch (error) => 
        console.error error
    resolve()

module.exports = Case
