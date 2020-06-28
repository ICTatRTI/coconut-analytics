_ = require 'underscore'

levelMappings =
  "MINISTRY OF HEALTH":"NATIONAL"
  "ZONE":"ISLANDS"
  "REGION":"REGIONS"
  "DISTRICT":"DISTRICTS"
  "FACILITY":"HEALTH FACILITIES"
  "SHEHIA": "SHEHIAS"


class Unit

  constructor: (data, @levelName) ->
    @name = data.name.toUpperCase()
    @parentId = data.parentId
    @level = data.level
    @id = data.id
    @aliases = for alias in (data.aliases or [])
      alias.name = alias.name.toUpperCase()
      alias
    @phoneNumber = data.phoneNumber

  parent: =>
    return null unless @parentId
    global.GeoHierarchy.unitsById[@parentId]

  children: ->
    _(global.GeoHierarchy.units).filter (unit) => unit.parentId is @id

  ancestors: =>
    parent = @parent()
    return [] if parent is null
    return [parent].concat(parent.ancestors())

  ancestorAtLevel: (levelName) =>
    levelName = levelMappings[levelName] or levelName
    _(@ancestors()).find (ancestor) ->
      ancestor.levelName is levelName

  descendants: =>
    children = @children()
    return [] if children is null
    return children.concat(_(children).chain().map (child) ->
      child.descendants()
    .flatten().compact().value())

  descendantsAtLevel: (levelName) =>
    allUnitsAtLevel = 
    _(global.GeoHierarchy.units).chain()
    .filter (unit) => 
      unit.levelName is levelName
    .filter (unit) => 
      _(unit.ancestors()).contains(@)
    .value()
    # This is slower than above which only loops through entire set of units once
    #_(@descendants()).filter (descendant) -> descendant.levelName is levelName

class GeoHierarchy

  loadAliases: (data) =>
    aliasesByCurrentName = {}
    for alias in data
      aliasesByCurrentName[alias.officialName] or= []
      aliasesByCurrentName[alias.officialName].push alias.alias

    @externalAliases = _(@externalAliases or= {}).extend aliasesByCurrentName

  loadData: (data) =>
    @units = []
    @unitsById = {}
    @unitsByName = {}
    @unitsByLevel = {
      1:[]
      2:[]
      3:[]
      4:[]
      5:[]
      6:[]
    }
    @unitsByLevelName = {}
    @levels = for level in data.levels
      level.name = level.name.toUpperCase()
      level
    @levelNamesForNumber = {}

    for level in @levels
      @levelNamesForNumber[level.number] = level.name

    for unitData in data.units
      unit = new Unit(unitData, @levelNamesForNumber[unitData.level])
      @units.push unit
      @unitsById[unit.id] = unit
      @unitsByLevel[unit.level].push unit
      @unitsByLevelName[unit.levelName] or= []
      @unitsByLevelName[unit.levelName].push unit
      @unitsByName[unit.name] or= []
      @unitsByName[unit.name].push unit
      if unit.aliases
        for alias in unit.aliases
          @unitsByName[alias.name] or= []
          @unitsByName[alias.name].push(unit) unless _(@unitsByName[alias.name]).contains(unit)

      if @externalAliases?[unit.name]
        for alias in @externalAliases[unit.name]
          @unitsByName[alias] or= []
          @unitsByName[alias].push(unit) unless _(@unitsByName[alias]).contains(unit)

    @groups = data.groups

  load: =>
    @loadAliases (await Coconut.database.get("Geographic Hierarchy Aliases")
      .catch (error) => console.error error
    ).data
    @loadData (await Coconut.database.get("Geographic Hierarchy")
      .catch (error) => console.error error
    )

  addAlias: (officialName, alias) =>
    aliases = await Coconut.database.get("Geographic Hierarchy Aliases")
    aliases.data.push
      officialName: officialName
      alias: alias
    await Coconut.database.put(aliases)

  # function from legacy version #

  ###
  Note done:
  findInNodes
  update: (region,district,shehias) =>
  ###

  find: (name, levelName) =>

    name = name.toUpperCase()
    levelName = levelName.toUpperCase()

    # When Coconut adopted DHIS2 units, we had to map old level names to the DHIS2 ones

    levelName = levelMappings[levelName] or levelName

    return [] unless name? and levelName?
    _(@unitsByName[name]).filter (unit) ->
      unit.levelName is levelName

  findFirst: (name, levelName) =>
    result = @find(name,levelName)
    if result.length >= 1
      result[0]
    else
      undefined

  findOneMatchOrUndefined: (targetName, levelName) =>
    matches = @find(targetName, levelName)
    switch matches.length
      when 0 then return null
      when 1 then return matches[0]
      else
        return undefined

  findWithParent: (name, levelName) =>
    for unit in @find(name,levelName)
      console.log unit.parent()
      name: unit.name
      parentName: unit.parent().name

  findAllForLevel: (levelName) =>
    levelName = levelName.toUpperCase()
    levelName = levelMappings[levelName] or levelName
    @unitsByLevelName[levelName]

  findChildrenNames: (targetLevelName, parentName) =>
    parentNode = @find(parentName, targetLevelName)
    console.error "More than one match" if parentNode.length >= 2
    _(parentNode[0].children()).pluck "name"

  findAllDescendantsAtLevel: (name, sourceLevelName, targetLevelName) =>
    targetLevelName = targetLevelName.toUpperCase()
    targetLevelName = levelMappings[targetLevelName] or targetLevelName
    @findFirst(name, sourceLevelName)?.descendantsAtLevel(targetLevelName)

  findAllAncestorsAtLevel: (name, sourceLevelName, targetLevelName) =>
    targetLevelName = targetLevelName.toUpperCase()
    targetLevelName = levelMappings[targetLevelName] or targetLevelName
    ancestors = @findFirst(name, sourceLevelName)?.ancestors()
    _(ancestors).filter (ancestor) -> ancestor.levelName is targetLevelName

  availableLevelsAscending: ->
    levelNames = []
    levelNumber = 0
    while levelNumber+=1 < 10 and @levelNamesForNumber[levelNumber]
      levelNames.push(@levelNamesForNumber[levelNumber])
    levelNames

  allUnitsInGroup: (name) =>
    name = name.toUpperCase()
    group = _(@groups).find (group) => group.name is name
    console.error "Can't find group #{name}" unless group
    _(group.unitIds).map (unitId) =>
      @unitsById[unitId]


  getAncestorAtLevel: (sourceName, sourceLevel, targetLevel) =>
    @findFirst(sourceName, sourceLevel.toUpperCase()).ancestorAtLevel(targetLevel.toUpperCase())?.name



  ###
    Zanzibar Specific Functions - should have generic equivalent above
  ###

  swahiliDistrictName: (districtName) =>
    @findFirst(districtName, "DISTRICT")?.name

  districtNameEnglishIfPossible: (districtName) => 
    districtUnit = @findFirst(districtName, "DISTRICT")
    _(districtUnit?.aliases).findWhere({description:"English"})?.name or districtUnit?.name

  findShehia: (shehiaName) => @find(shehiaName, "SHEHIA")

  findOneShehia: (shehiaName) => @findOneMatchOrUndefined(shehiaName, "SHEHIA")

  validShehia: (shehiaName) =>  @findShehia(shehiaName)?.length > 0

  validDistrict: (districtName) =>  
    try
      @find(districtName, "DISTRICT")?.length > 0
    catch
      return false

  findAllShehiaNamesFor: (name, level) => _(@findAllDescendantsAtLevel(name, level, "SHEHIA")).pluck "name"

  findAllDistrictsFor: (name, level) => _(@findAllDescendantsAtLevel(name, level, "DISTRICT")).pluck "name"

  allZones: => _.pluck @findAllForLevel("ZONE"), "name"

  allRegions: => _.pluck @findAllForLevel("REGION"), "name"

  allDistricts: => _.pluck @findAllForLevel("DISTRICT"), "name"

  allShehias: => _.pluck @findAllForLevel("SHEHIA"), "name"

  allUniqueShehiaNames: => _(@allShehias()).uniq()

  all: (levelName) => _.pluck @findAllForLevel(levelName.toUpperCase()), "name"


  getZoneForDistrict: (districtName) =>
    district = @findOneMatchOrUndefined(districtName,"DISTRICT")
    return null unless district
    _(district.ancestors()).find (unit) ->
      unit.levelName is "ISLANDS" or unit.levelName is "ZONE" # Added ISLANDS for DHIS2 unit merge
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

  allFacilities: => _(@findAllForLevel("FACILITY")).chain().pluck("name").unique().value()

  # Warning facilityNames may not be unique
  getDistrict: (facilityName) =>
    ancestors = @findAllAncestorsAtLevel(facilityName, "FACILITY", "DISTRICT")
    if ancestors.length > 0 then ancestors[0].name else null

  # Warning facilityNames may not be unique
  getZone: (facilityName) =>
    facility = @findFirst(facilityName, "FACILITY")
    unless facility
      console.error "Can't find facility: #{facilityName}"
      return null
    zoneForFacility = facility.ancestorAtLevel("ZONE")
    unless zoneForFacility
      console.error "No zone found for facility: #{facilityName}"
      return null
    zoneForFacility.name

  facilities: (districtName) => # Note this is note named well
    _(@findAllDescendantsAtLevel(districtName, "DISTRICT", "FACILITY")).pluck "name"

  facilitiesForDistrict: (districtName) => @facilities(districtName)

  facilitiesForZone: (zoneName) => @findAllDescendantsAtLevel(zoneName, "ZONE", "FACILITY")

  numbers: (districtName,facilityName) =>
    _(@find(facilityName, "FACILITY")).find (facility) ->
      facility.ancestorAtLevel("DISTRICT").name is districtName
    .phoneNumber

  facilityType: (facilityName) =>

    facilities = @find(facilityName, "FACILITY")
    if facilities.length isnt 1
      if facilities.length is 0
        console.warn "Unknown facility name: #{facilityName}. Returning UNKNOWN"
        "UNKNOWN"
      else
        console.warn "Non-unique facility name: #{facilityName}. Returning PUBLIC by default"
        "PUBLIC"
    else
      facilityId = facilities[0].id

      privateUnitIds = _(@groups).find((group) => group.name is "PRIVATE").unitIds
      if _(privateUnitIds).contains(facilityId)
        "PRIVATE"
      else
        "PUBLIC"

  allPrivateFacilities: =>
    group = _(@groups).find (group) => group.name is "PRIVATE"
    console.error "Can't find group #{name}" unless group
    _(group.unitIds).map (unitId) =>
      @unitsById[unitId].name


module.exports = GeoHierarchy
