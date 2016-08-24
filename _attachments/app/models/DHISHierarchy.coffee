_ = require 'underscore'
chance = require('chance').Chance()

class DHISHierarchy

  loadExtendExport: (options) =>
    @loadDHISHierarchy
      dhisDocumentName: options.dhisDocumentName
      error: (error) ->
        console.error "Error loading DHIS hierarchy:"
        console.error error
      success: =>
        @loadDataToExtendWith
          error: (error) ->
            console.error "Error loading data to extend DHIS hierarchy:"
            console.error error
          success: =>
            options.success(@extend())

  loadDHISHierarchy: (options) =>
    console.log options
    Coconut.database.get options.dhisDocumentName
    .catch (error) ->
      console.error "Error loading Geo Hierarchy:"
      console.error error
      options.error?(error)
    .then (result) =>
      @rawData = result
      options.success()

  loadDataToExtendWith: (options) ->

      @dataToExtendWith = {
        organisationUnitLevels: [
          { name: "Shehia", level: 6 }
          { name: "Village", level: 7 }
        ]

        organisationUnitGroups: [
        ]

        organisationUnits: [] # Set by calling getShehiasAsOrganizationUnits below
        ###
        [
          { name: "BOPWE", type: "Shehia", parentName: "WETE", parentType: "District"}
          { name: "CHAMBANI", type: "Shehia", parentName: "MKOANI", parentType: "District"}
          { name: "AMANI", type: "Shehia", parentName: "MJINI", parentType: "District"}
        ]
        ###
      }

      @getShehiasAsOrganizationUnits
        success: (result) =>
          @dataToExtendWith.organisationUnits = result
          options?.success()



  # Things extend does:
  # Merges data with previously imported data
  # Converts parentName and parentType to a parentId
  # Creates an ID that is unique within the set
  # Adds a source = "coconutSurveillance" property
  # Converts type property to level, eg District -> 4
  extend: =>

    dataToExtendWith = @dataToExtendWith

    returnVal = @tidyDHISData()

    returnVal = @addDistrictAliases(returnVal)

    levelNumberForName = (levelName) ->
      level = _(returnVal.organisationUnitLevels.concat(dataToExtendWith.organisationUnitLevels)).find (level) ->
        levelName is level.name
      level.level # just want the number

    dataToExtendWith.organisationUnits = _(dataToExtendWith.organisationUnits).map (organisationUnit) ->

      # Fix up parents
      if not organisationUnit.parentId and organisationUnit.parentName and organisationUnit.parentType
        organisationUnitParentLevel = levelNumberForName(organisationUnit.parentType)

        # Look up parents for organisationUnits based on the existing data
        parentOrganizationUnit = _(returnVal.organisationUnits).filter (existingOrganisationUnit) ->
          existingOrganisationUnit.level is organisationUnitParentLevel and existingOrganisationUnit.name is organisationUnit.parentName
        if parentOrganizationUnit.length > 1
          console.log "Multiple parent matches for #{JSON.stringify organisationUnit}:\n #{JSON.stringify parentOrganizationUnit}"
          throw "Multiple parent matches for #{organisationUnit}"
        else if parentOrganizationUnit.length is 1
          organisationUnit.parentId = parentOrganizationUnit[0].id
          delete organisationUnit.parentName
          delete organisationUnit.parentType
        else
          console.log "No parent found for #{JSON.stringify organisationUnit}"

      if not organisationUnit.level and organisationUnit.type
        organisationUnit.level = levelNumberForName(organisationUnit.type)
        delete organisationUnit.type

      return organisationUnit

    arrayPropertiesToExtend = [
      "organisationUnitLevels"
      "organisationUnitGroups"
      "organisationUnits"
    ]

    existingIds = _(arrayPropertiesToExtend).chain().map (property) ->
      _(returnVal[property]).pluck "id"
    .flatten().value()

    _(arrayPropertiesToExtend).each (property) ->

      dataToExtendWith[property] = _(dataToExtendWith[property]).map (item) ->
        item['source'] = 'coconutSurveillance'
        unless item['id']
          newId = chance.string(length:11, pool:"ABCEFHKMNPRSTUVWXY") while not newId or _(existingIds).contains newId
          item['id'] = newId
          existingIds.push newId

        item


      returnVal[property] = returnVal[property].concat(dataToExtendWith[property])

    return returnVal

  getShehiasAndExtend: (options) =>
    @getShehiasAsOrganizationUnits
      error: (error) -> console.error error
      success: () =>
        options.success @extend()

  getShehiasAsOrganizationUnits: (options) =>
    Coconut.database.get "Geo Hierarchy"
    .catch (error) ->
      console.error "Error loading Geo Hierarchy:"
      console.error error
      options?.error(error)
    .then (result) =>
      shehias = _(result.hierarchy).chain().map (districts, region) ->
        _(districts).map (shehias, district) ->
          _(shehias).map (shehia) ->
            { name: shehia, type: "Shehia", parentName: district, parentType: "District"}
      .flatten().value()
      options.success(shehias)


  addDistrictAliases: (data) ->
    districtAliases = {
      'KASKAZINI A': 'NORTH A',
      'KASKAZINI B': 'NORTH B',
      KUSINI: 'SOUTH',
      MASHARIKI: 'EAST',
      MAGHARIBI: 'WEST',
      MJINI: 'URBAN',
      KATI: 'CENTRAL',
      'CHAKE CHAKE': 'CHAKECHAKE'
    }
    data.organisationUnits = _(data.organisationUnits).map (unit) ->
      unit.aliases = [districtAliases[unit.name]] if unit.level is 4 and districtAliases[unit.name]
      unit

    data

  tidyDHISData: =>
    # Tidy up the object

    dataForExport = @rawData

    propertiesToDelete = [
      "created"
      "lastUpdated"
      "externalAccess"
      "user"
      "shortName"
      "openingDate"
      "uuid"
      "publicAccess"
    ]

    dataForExport.organisationUnits = _(dataForExport.organisationUnits).map (organisationUnit) ->
      organisationUnit.name = organisationUnit.name.toUpperCase()
      _(propertiesToDelete).each (property) -> delete organisationUnit[property]
      if organisationUnit.parent
        organisationUnit.parentId = organisationUnit.parent.id
        organisationUnit.source = "dhis2"
        delete organisationUnit.parent
      if organisationUnit.phoneNumber
        organisationUnit.phoneNumber = organisationUnit.phoneNumber.split(/[ ,]+/)
      return organisationUnit

    delete dataForExport.organisationUnitGroupSets

    dataForExport.organisationUnitGroups =  _(dataForExport.organisationUnitGroups).map (organisationUnitGroup) ->
      _(propertiesToDelete).each (property) -> delete organisationUnitGroup[property]
      organisationUnitGroup.source = "dhis2"
      organisationUnitGroup.organisationUnits = _(organisationUnitGroup.organisationUnits).map (organisationUnit) ->
        organisationUnit.id
        organisationUnit.source = "dhis2"
        organisationUnit
      return organisationUnitGroup


    dataForExport.organisationUnitLevels =  _(dataForExport.organisationUnitLevels).map (organisationUnitLevel) ->
      _(propertiesToDelete).each (property) -> delete organisationUnitLevel[property]
      organisationUnitLevel.source = "dhis2"
      return organisationUnitLevel

    return dataForExport

module.exports = DHISHierarchy
