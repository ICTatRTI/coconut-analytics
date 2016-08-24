_ = require 'underscore'

class GeoHierarchy
  # This property is accessible to the subclass, so Unit instances can always use the info in GeoHierarchy
  geohierarchy = undefined

  constructor: (@rawData) ->
    geohierarchy = this
    @units = _(@rawData.organisationUnits).map (rawUnit) -> new Unit(rawUnit)

  class Unit

    constructor: (rawUnit) ->
      @name = rawUnit.name
      @parentId = rawUnit.parentId
      @level = rawUnit.level
      @id = rawUnit.id
      levelData = _(geohierarchy.rawData.organisationUnitLevels).find (level) => level.level is @level
      @levelName = if levelData then levelData.name.toUpperCase() else null
      @aliases = rawUnit.aliases
      @phoneNumber = rawUnit.phoneNumber

    parent: =>
      return null unless @parentId
      _(geohierarchy.units).find (unit) => unit.id is @parentId

    children: ->
      _(geohierarchy.units).filter (unit) => unit.parentId is @id

    ancestors: =>
      parent = @parent()
      return [] if parent is null
      return [parent].concat(parent.ancestors())

    ancestorAtLevel: (levelName) =>
      _(@ancestors()).find (ancestor) ->
        ancestor.levelName is levelName

    descendants: =>
      children = @children()
      return [] if children is null
      return children.concat(_(children).chain().map (child) ->
        child.descendants()
      .flatten().compact().value())

    descendantsAtLevel: (levelName) =>
      _(@descendants()).filter (descendant) -> descendant.levelName is levelName

  # function from legacy version #

  ###
  Note done:
  findInNodes
  update: (region,district,shehias) =>
  ###

  find: (name, levelName) =>
    _(@units).filter (unit) ->
      unit.levelName is levelName.toUpperCase() and
      (unit.name is name.toUpperCase() or _(unit.aliases).contains name.toUpperCase())

  findFirst: (name, levelName) =>
    _(@units).find (unit) -> unit.levelName is levelName.toUpperCase() and (unit.name is name.toUpperCase() or _(unit.aliases).contains name.toUpperCase())

  findOneMatchOrUndefined: (targetName, levelName) =>
    matches = @find(targetName, levelName)
    switch matches.length
      when 0 then return null
      when 1 then return matches[0]
      else
        return undefined

  findAllForLevel: (levelName) =>
    _(@units).filter (unit) -> unit.levelName is levelName.toUpperCase()

  findChildrenNames: (targetLevelName, parentName) =>
    parentNode = @find(parentName, targetLevelName)
    console.error "More than one match" if parentNode.length >= 2
    _(parentNode[0].children()).pluck "name"

  findAllDescendantsAtLevel: (name, sourceLevelName, targetLevelName) =>
    descendants = @findFirst(name, sourceLevelName).descendants()
    _(descendants).filter (descendant) -> descendant.levelName is targetLevelName

  findAllAncestorsAtLevel: (name, sourceLevelName, targetLevelName) =>
    ancestors = @findFirst(name, sourceLevelName).ancestors()
    _(ancestors).filter (ancestor) -> ancestor.levelName is targetLevelName


  ###
    Zanzibar Specific Functions - should have generic equivalent above
  ###
  
  swahiliDistrictName: (districtName) => @findFirst(districtName, "DISTRICT").name

  englishDistrictName: (districtName) => @findFirst(districtName, "DISTRICT").aliases?[0]

  findShehia: (shehiaName) => @find(shehiaName, "SHEHIA")

  findOneShehia: (shehiaName) => @findOneMatchOrUndefined(shehiaName, "SHEHIA")

  validShehia: (shehiaName) =>  @findShehia(shehiaName)?.length > 0

  findAllShehiaNamesFor: (name, level) => _(@findAllDescendantsAtLevel(name, level, "SHEHIA")).pluck "name"

  findAllDistrictsFor: (name, level) => _(@findAllDescendantsAtLevel(name, level, "DISTRICT")).pluck "name"

  allRegions: => _.pluck @findAllForLevel("REGION"), "name"

  allDistricts: => _.pluck @findAllForLevel("DISTRICT"), "name"

  allShehias: => _.pluck @findAllForLevel("SHEHIA"), "name"

  allUniqueShehiaNames: => _(@allShehias()).uniq()

  all: (levelName) => _.pluck @findAllForLevel(levelName), "name"

  getZoneForDistrict: (districtName) =>
    district = @findOneMatchOrUndefined(districtName,"DISTRICT")
    return null unless district
    _(district.ancestors()).find (unit) ->
      unit.levelName is "ZONE"
    .name

  getZoneForRegion: (regionName) ->
    if regionName.match /PEMBA/
      return "PEMBA"
    else
      return "UNGUJA"

  districtsForZone:  (zoneName) =>
    _(@findAllDescendantsAtLevel(zoneName,"ZONE","DISTRICT")).pluck "name"

  ## Functions from FacilityHierarchy ##
  # TODO refactor to not use these #

  allFacilities: => _.pluck @findAllForLevel("FACILITY"), "name"

  # Warning facilityNames may not be unique
  getDistrict: (facilityName) =>
    ancestors = @findAllAncestorsAtLevel(facilityName, "FACILITY", "DISTRICT")
    if ancestors.length > 0 then ancestors[0].name else null

  # Warning facilityNames may not be unique
  getZone: (facilityName) =>
    ancestors = @findAllAncestorsAtLevel(facilityName, "FACILITY", "ZONE")
    if ancestors.length > 0 then ancestors[0].name else null

  facilities: (districtName) =>
    _(@findAllDescendantsAtLevel(districtName, "DISTRICT", "FACILITY")).pluck "name"

  facilitiesForDistrict: (districtName) => @facilities(district)

  facilitiesForZone: (zoneName) => @findAllDescendantsAtLevel(zoneName, "ZONE", "FACILITY")

  numbers: (districtName,facilityName) =>
    _(@find(facilityName, "FACILITY")).find (facility) ->
      facility.ancestorAtLevel("DISTRICT").name is districtName
    .phoneNumber

  facilityType: (facilityName) =>
    facilityId = @findFirst(facilityName, "FACILITY").id
    group = _(@rawData.organisationUnitGroups).find (group) ->
      _(group.organisationUnits).find (unit) ->
        unit.id is facilityId

    group.name.toUpperCase()

  allPrivateFacilities: =>
    privateFacilities = _(@rawData.organisationUnitGroups).find (group) ->
      group.name is "Private"
    .organisationUnits

    _(privateFacilities).map (privateFacility) ->
      privateFacility.name.toUpperCase()



















module.exports = GeoHierarchy
