_ = require 'underscore'
titleize = require 'underscore.string/titleize'

GeoJsonLookup = require 'geojson-geometries-lookup'

#Fuse = require 'fuse.js'


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
    _([@].concat(@ancestors())).find (ancestor) -> # include this in the list to check
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

    #@fuse = new Fuse(_(@unitsByName).keys(), includeScore: true)

    @groups = data.groups

  loadPolygonBoundaries: =>
    @boundaries =
      Villages:
        labelsDocName: 'VillageCntrPtsWGS84'
        featureName: "Vil_Mtaa_N"
      Shehias:
        labelsDocName: 'ShehiaCntrPtsWGS84'
        featureName: "Shehia_Nam"
      Districts:
        labelsDocName: 'DistrictsCntrPtsWGS84'
        featureName: "District_N"

    for boundaryName, properties of @boundaries
      await Coconut.cachingDatabase.get "#{boundaryName}Adjusted"
      .catch (error) =>
        new Promise (resolve, reject) =>
          Coconut.cachingDatabase or= new PouchDB("coconut-zanzibar-caching")
          Coconut.cachingDatabase.replicate.from Coconut.database,
            doc_ids: ["#{boundaryName}Adjusted"]
          .on "complete", =>
            resolve(Coconut.cachingDatabase.get "#{boundaryName}Adjusted"
            .catch (error) => console.log error
            )
      .then (data) =>
        @boundaries[boundaryName]["query"] = new GeoJsonLookup(data)
        console.info "GeoHierarchy loadPolygonBoundaries complete"
        Promise.resolve()

  load: =>
    @loadAliases (await Coconut.database.get("Geographic Hierarchy Aliases")
      .catch (error) => console.error error
    ).data
    @loadData (await Coconut.database.get("Geographic Hierarchy")
      .catch (error) => console.error error
    )
    await @loadPolygonBoundaries()

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

  findAll: (name) =>
    name = name?.trim().toUpperCase()
    return [] unless name?
    @unitsByName[name]

  findAllNameAndLevel: (name) =>
    for unit in @findAll(name)
      "#{unit.name}: #{unit.levelName}"

  find: (name, levelName) =>
    return [] unless levelName?
    levelName = levelName.trim().toUpperCase()
    # When Coconut adopted DHIS2 units, we had to map old level names to the DHIS2 ones
    levelName = levelMappings[levelName] or levelName

    _(@findAll(name)).filter (unit) ->
      unit.levelName is levelName

    ###
    if result.length > 0
      return result
    else
      _(@fuse.search(name)).chain().map (fuseResult) =>
        console.log fuseResult
        @unitsByName[fuseResult.item]
      .flatten()
      .filter (unit) ->
        unit.levelName is levelName
      .value()
    ###

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

  findHavingAncestor: (name, levelName, ancestorUnit) =>
    _(@find(name, levelName)).filter (unit) =>
      _(unit.ancestors()).includes ancestorUnit

  findWithParent: (name, levelName) =>
    for unit in @find(name,levelName)
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

  findShehiaWithAncestor: (shehiaName,ancestorName, ancestorLevel) => 
    shehias = @findShehia(shehiaName)
    targetAncestors = @find(ancestorName, ancestorLevel) # most likely just 1

    for shehia in shehias
      for ancestor in shehia.ancestors()
        if _(targetAncestors).contains ancestor
          return shehia

  findOneShehia: (shehiaName) => @findOneMatchOrUndefined(shehiaName, "SHEHIA")

  valid: (type,name) =>
    if type.match(/shehia/i)
      @validShehia(name)
    else if type.match(/district/i)
      @validDistrict(name)
    else if type.match(/facility/i)
      @validFacility(name)

  validShehia: (shehiaName) =>  @findShehia(shehiaName)?.length > 0

  validDistrict: (districtName) =>  
    try
      @find(districtName, "DISTRICT")?.length > 0
    catch
      return false

  validFacility: (facilityName) => @find(facilityName,"HEALTH FACILITIES")?.length > 0

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

  boundaryPropertiesFromGPS: (longitude, latitude) =>
    throw "Longitude or latitude missing for locationFromGPS" unless longitude? and latitude?

    properties = {}

    for boundaryName of @boundaries
      for feature in @boundaries[boundaryName].query.getContainers(
        type: "Point"
        coordinates: [longitude, latitude]
      ).features
        for property, value of feature.properties
          if properties[property] and property[property] is value
            console.log "Confliciting property: #{property}: #{properties[property]} and #{value}"
          else
            properties[property] = value
            
    properties

  mostPreciseUnitFromGPS: (longitude, latitude) =>
    locationProperty = {
      "VILLAGE": "Vil_Mtaa_N"
      "WARD": "Ward_Name"
      "SHEHIA": "Shehia_Nam"
      "DISTRICT": "District_N"
      "REGION": "Region_Nam"
    }

    # Use the district or region if need be eliminate more precise place names that are not unique
    properties = @boundaryPropertiesFromGPS(longitude, latitude)
    #Shehia names are unique by district, so first try and get the district
    unless properties[locationProperty.DISTRICT]?
      console.log "No district for #{longitude} #{latitude}, here are the properties: #{JSON.stringify(properties)}"
      return null
    ancestor = if properties[locationProperty.DISTRICT] is "Magharibi"
      @findFirst("MJINI MAGHARIBI", "REGION")
    else
      @findFirst(properties[locationProperty.DISTRICT], "DISTRICT")

    console.log "Can't find district for #{properties[locationProperty.DISTRICT]}" unless ancestor?

    for locationType, locationTypeProperty of locationProperty
      unit = @findHavingAncestor(properties[locationTypeProperty], locationType, ancestor)
      if unit.length is 1
        return unit[0]
      if unit.length > 1
        console.error "Multiple units for GPS location with ancestor: #{ancestor.name}\n #{JSON.stringify unit}"

  findByGPS: (longitude, latitude, levelName) =>
    unit = @mostPreciseUnitFromGPS(longitude,latitude)
    if unit?.levelName is levelName
      unit
    else
      unit?.ancestorAtLevel(levelName)

module.exports = GeoHierarchy
