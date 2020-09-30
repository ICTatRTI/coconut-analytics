moment = require 'moment'
humanize = require 'underscore.string/humanize'
titleize = require 'underscore.string/titleize'
TertiaryIndex = require './TertiaryIndex'

class Individual
  constructor: (@data, @case) ->

  formatProperty: (string) =>
    titleize(humanize(string))
      .replace(/llin/i,"LLIN")
      .replace(/llinlast/i,"LLIN Last")
      .replace(/Under5/,"Under 5")
      .replace(/Ahealth/,"A Health")
      .replace(/Malaria Case/,"Malaria Case ID")

  summary: =>
    result = @caseSummaryResult()
      .concat(@householdMemberSummaryResult())
      .concat(@calculatedPropertiesResult())

  summaryCollection: =>
    result = {}
    for propertyValue in @summary()
      for property,value of propertyValue
        result[property] = value if value?
    result

  summaryAsCSVString: =>
    _(@summary()).chain().map (summaryItem) ->
      "\"#{_(summaryItem).values()}\""
    .flatten().value().join(",") + "--EOR--<br/>"

  # These are properties that came from the index case
  caseSummaryProperties: {
    HouseholdLocationAccuracy:
      propertyName: "Household Location - Accuracy"
      functionName: "householdLocationAccuracy"
    HouseholdLocationLatitude:
      propertyName: "Household Location - Latitude"
      functionName: "householdLocationLatitude"
    HouseholdLocationLongitude:
      propertyName: "Household Location - Longitude"
      functionName: "householdLocationLongitude"
  }

  caseSummaryResult: =>
    for property,options of @caseSummaryProperties
      @case.summaryResult(property,options)

  householdMemberSummaryResult: =>
    #for property in @householdMemberSummaryProperties()
    #  {"#{@formatProperty(property)}": @data[property]}
    result = []
    for property, value of @data
      # continue actually means skip to the next value in the loop
      continue unless value?
      continue if value is ""

      continue if [ # Skip all of these
        "complete"
        "Age"
        "AgeInYearsMonthsDays"
        "Shehia"
        "DateOfPositiveResults"
        "CaseCategory"
        "FirstName"
        "MiddleName"
        "LastName"
        "collection"
        "question"
        "transferred"
        "_rev"
        "AgeInYearsOrMonths"
        "AgeInYearsMonthsDays"
        "AgeInMonthsOrYears"
        "SleptUnderLlinLastNight"
        "IndexCaseSleptUnderLlinLastNight"
      ].map( (propertyToSkip) => propertyToSkip.toLowerCase().replace(/\W/,"") ).includes(property.toLowerCase().replace(/\W/,""))

      continue if property.match(/^\d+Entry/)

      result.push {"#{@formatProperty(property)}": "#{value}".trim()}

    result

  calculatedProperties: [
    "ageInYears"
    "isUnder5"
    "relevantTravelOutsideZanzibar"
    "relevantTravelWithinZanzibar"
    "shehia" # Could require different focus
    "district" # Could require different focus
    "island" # Could require different focus

    "name" # Hand first Name, name, etc
    "dateOfPositiveResults"
    "classification"
    "sleptUnderLLINLastNight"
  ]

  calculatedPropertiesResult: =>
    for functionName in @calculatedProperties
      {"#{@formatProperty(functionName)}": @[functionName]()}

  findFirst: (propertyOrProperties, checkPermutations = false) =>
    if checkPermutations
    # Remove spaces and make lower case to check for any permutations of the property name. Once all possibilities that exist in the current data are found, call the function again with just the existing properties
      mapping = {}
      matchedProperties = []
      for key in Object.keys(@data)
        mapping[key.replace(/ /g,"").toLowerCase()] = key
      for property in propertyOrProperties
        propertyNoSpacesLowerCase = property.replace(/ /g,"").toLowerCase()
        if mapping[propertyNoSpacesLowerCase]
          matchedProperties.push mapping[propertyNoSpacesLowerCase]

      return @findFirst(matchedProperties, false)

    if _(propertyOrProperties).isArray()
      for property in propertyOrProperties
        value = @data[property]
        if value? and value isnt ""
          return value
    else
      @data[propertyOrProperties]

  ageInYears: =>
    age = @findFirst 'Age'
    ageinYearsMonthsDays = @findFirst([
      "Age In Years Months Days"
      "Age In Months Or Years"
    ], true)

    # This doesn't use any case data to do the calc
    @case.ageInYears(age, ageinYearsMonthsDays or "Years")

  isUnder5: =>
    @ageInYears() < 5

  relevantTravelOutsideZanzibar: =>
    # TODO add properties from old data - define relevant!
    if @data["Case Category"] is "Imported"
      return true
    for index in [0..5]
      if @data["Time Outside Zanzibar[#{index}].based-on-the-above-information-do-you-think-this-place-is-the-source-for-this-malaria-transmission"] is "Yes"
        return true

  relevantTravelWithinZanzibar: =>
    @data["OvernightTravelWithinZanzibar1030DaysBeforePositiveTestResult"] is "Yes"

  shehiaUnit: =>
    if (focus = @data["WhereCouldTheMalariaFocusBe"])
      focus = focus.trim()
      if focus is "Patient Shehia"
        @case.householdShehiaUnit()
      else if focus is "Other Shehia Within Zanzibar"
        otherDistrict = positiveIndividual["WhichOtherDistrictWithinZanzibar"]
        otherShehia = positiveIndividual["WhichOtherShehiaWithinZanzibar"]
        shehiaUnit = @shehiaUnit(otherShehia, otherDistrict)
        shehiaUnit or @case.householdShehiaUnit
    else if @data["HouseholdMemberType"] is "Index Case" and (odkData = @["ODK 2017-2019"])

      #TODO waiting to find out which ODK questions were used for this
      @case.householdShehiaUnit()
    else
      @case.householdShehiaUnit()

  shehia: =>
    @shehiaUnit()?.name

  district: =>
    @shehiaUnit()?.ancestorAtLevel("DISTRICT")?.name

  island: =>
    @shehiaUnit()?.ancestorAtLevel("ISLANDS")?.name


  name: =>
    "#{@data["FirstName"]} #{@data["MiddleName"] or ""} #{@data["LastName"]}" or @findFirst(["name"])

  dateOfPositiveResults: =>
    return null unless @data["Malaria Positive"] is true
    date = @findFirst([
      "DateOfPositiveResults"
      "createdAt"
      "date"
    ], true)
    # Clean up ill-formatted dates from a long time ago
    if match = date.match(/^(\d\d)-(\d\d)-(\d\d\d\d)$/)
      date = "#{match[3]}-#{match[2]}-#{match[1]}"
    if match = date.match(/^(\d\d\d\d-\d\d-\d\d) \d/)
      date = "#{match[1]}"
    date

  classification: =>
    return null unless @data["Malaria Positive"] is true
    # post-2019 with classification
    if @data.CaseCategory 
      @data.CaseCategory
    # pre-2019 so missing classification or in progress classification (not likely)
    # And return unclassified
    else if @data["IsCaseLostToFollowup"] is "Yes"
      "Lost to Followup"
    else
      # Is household member complete then "Unclassified"
      if @data.question is "Household Members" and (@data.complete is true or @data.complete is "true")
        "Unclassified"
      else
        # If we only have a household record, then it's a completed index case from from pre-2019 that wasn't classified
        if @data.question is "Household" and (@data.complete is true or @data.complete is "true") and moment(@data.createdAt).isBefore(moment("2020-01-01"))
          if odkClassification = @case.odkClassification()
            odkClassification
          else
            "Unclassified"
        # Or it's just an old case that won't ever be followed up
        else if moment().diff(moment(@data.createdAt), 'months') > 6
          "Lost to Followup"
        else
          "In Progress"

  sleptUnderLLINLastNight: =>
    result = @findFirst([
      "Slept Under LLIN Last Night"
      "Index Case Slept Under Llin Last Night"
    ], true)

  updateIndex: =>
    tertiaryIndex.indexDocsForCase(@case,false)

module.exports = Individual
