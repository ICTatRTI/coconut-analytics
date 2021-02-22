moment = require 'moment'
humanize = require 'underscore.string/humanize'
titleize = require 'underscore.string/titleize'

class Individual
  constructor: (@data, @case) ->

  updateIndex: =>
    @case.updatedIndividualIndex()

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

  # This is what is called to create the individual index document
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
        "TypeOfTreatmentProvided"
        "TypeOfTreatmentPrescribed"
        "TreatmentProvided"
      ].map( (propertyToSkip) => propertyToSkip.toLowerCase().replace(/\W/,"") ).includes(property.toLowerCase().replace(/\W/,""))

      continue if property.match(/^\d+Entry/)

      result.push {"#{@formatProperty(property)}": "#{value}".trim()}

    result

  calculatedProperties: [
    "ageInYears"
    "isUnder5"
    "relevantTravelOutsideZanzibar"
    "relevantTravelWithinZanzibar"
    "householdShehia"
    "householdDistrict"
    "householdIsland"
    "focalShehia"
    "focalDistrict"
    "focalIsland"
    "administrativeLevels"
    "name" # Hand first Name, name, etc
    "dateOfPositiveResults"
    "yearWeekOfPositiveResults"
    "classification"
    "sleptUnderLLINLastNight"
    "parasiteSpecies"
    "treatment"
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

  malariaFocus: =>
    @data["WhereCouldTheMalariaFocusBe"]?.trim()

  focalShehiaUnit: =>
    if focus = @malariaFocus()
      if focus is "Patient Shehia"
        @case.householdShehiaUnit()
      else if focus is "Other Shehia Within Zanzibar"
        otherDistrict = positiveIndividual["WhichOtherDistrictWithinZanzibar"]
        otherShehia = positiveIndividual["WhichOtherShehiaWithinZanzibar"]
        shehiaUnit = @shehiaUnit(otherShehia, otherDistrict)
        shehiaUnit or @case.householdShehiaUnit
      # If outside Zanzibar will return null since there are no units outside Zanzibar
    else if @data["HouseholdMemberType"] is "Index Case" and (odkData = @["ODK 2017-2019"])

      #TODO waiting to find out which ODK questions were used for this
      @householdShehiaUnit()
    else
      @householdShehiaUnit()

  # This uses household shehia if the focal shehia is outside of Zanzibar
  # Nation, Island, Region, District, Shehia, Facility
  administrativeLevels: =>
    shehiaUnit = @focalShehiaUnit()
    unless shehiaUnit?
    # This uses household shehia if the focal shehia is outside of Zanzibar
      shehiaUnit = @householdShehiaUnit()

    if shehiaUnit

      shehiaAncestors = _(shehiaUnit?.ancestors()).pluck "name"
      result = shehiaAncestors.reverse().concat(shehiaUnit.name).concat(@case.facility())
      result.join(",")

  focalShehia: =>
    @focalShehiaUnit()?.name or @malariaFocus()

  focalDistrict: =>
    @focalShehiaUnit()?.ancestorAtLevel("DISTRICT")?.name or @malariaFocus()

  focalIsland: =>
    @focalShehiaUnit()?.ancestorAtLevel("ISLANDS")?.name or @malariaFocus()

  focalAdministrativeLevels: =>

  householdShehiaUnit: =>
    @case.householdShehiaUnit()

  householdShehia: =>
    @householdShehiaUnit()?.name

  householdDistrict: =>
    @householdShehiaUnit()?.ancestorAtLevel("DISTRICT")?.name

  householdIsland: =>
    @householdShehiaUnit()?.ancestorAtLevel("ISLANDS")?.name

  name: =>
    name = "#{@data["FirstName"] or ""} #{@data["MiddleName"] or ""} #{@data["LastName"] or ""}"
    name = name?.replace(/  /g," ").trim()
    if name is ""
      @findFirst(["name"])?.trim()
    else
      name

  dateOfPositiveResults: =>
    return null unless @data["Malaria Positive"] is true
    date = @findFirst([
      "DateAndTimeOfPositiveResults"
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

  yearWeekOfPositiveResults: =>
    dateOfPositiveResults = @dateOfPositiveResults()
    if dateOfPositiveResults?
      moment(@dateOfPositiveResults()).format("GGGG-WW")

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

  parasiteSpecies: =>
    result = @findFirst([
      "Malaria Microscopy Test Results"
      "Malaria mRDT Test Results"
      "Malaria Test Result"
    ], true)
    result?.replace(/P.f \+ Pan \(Mixed\)/, "P.f + (P. malariae and/or P. vivax and/or P. ovale)")
      .replace(/Mixed/, "P.f and/or P. malariae and/or P. vivax and/or P. ovale (at least 2)")
      .replace(/Pan/, "P. malariae and/or P. vivax and/or P. ovale")
      .replace(/P.f/, "P. falciparum")
      .replace(/P.f/, "P. falciparum")
      .replace(/NF/i, "No Parasite Found")
      .replace(/NPF/i, "No Parasite Found")

  isIndexCase: =>
    @data["HouseholdMemberType"] is "Index Case"

  treatment: =>
    treatment = @findFirst("Type of Treatment Provided")
    if treatment
      treatmentDoseAndStrengthFromHouseholdRecord = for property, value of @data
        if property.match(/DoseAndStrength/)
          treatment += " #{value}"
          break

    # Check for treatment at facility if index case
    else if @isIndexCase()
      treatment = @case.Facility?.TypeOfTreatmentPrescribed
      if treatment
        treatmentDoseAndStrengthFromHouseholdRecord = for property, value of @case.Facility
          if property.match(/DoseAndStrength/)
            treatment += " #{value}"
            break

    primaquineDose = @findFirst("Primaquine Dose")
    if not primaquineDose and @isIndexCase()
      primaquineDose = @case.Facility?.PrimaquineDose

    primaquineDose = if primaquineDose is "Not given" or primaquineDose is "Not Applicable" or not primaquineDose?
      ""
    else if primaquineDose
      "Primaquine #{primaquineDose}"

    if treatment and primaquineDose
      "#{treatment} #{primaquineDose}"
    else if treatment
      treatment
    else if primaquineDose
      primaquineDose
    else
      ""

  updateIndex: =>
    tertiaryIndex.indexDocsForCase(@case,false)

module.exports = Individual
