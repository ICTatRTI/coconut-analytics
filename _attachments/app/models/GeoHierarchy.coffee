_ = require 'underscore'

class GeoHierarchy

  constructor: (options) ->

    @levels = ["REGION","DISTRICT","SHEHIA"]
    Coconut.database.get "Geo Hierarchy"
    .catch (error) ->
      console.error "Error loading Geo Hierarchy:"
      console.error error
      options.error(error)
    .then (result) =>

      @hierarchy = result.hierarchy
      @root = {parent: null}

      # Adds properties region, district, shehia, etc to node
      addLevelProperties = (node) ->
        levelClimber = node
        node[levelClimber.level] = levelClimber.name
        while levelClimber.parent isnt null
          levelClimber = levelClimber.parent
          node[levelClimber.level] = levelClimber.name
        return node

      # builds the tree
      addChildren = (node,values, levelNumber) =>
        if _(values).isArray()
          node.children = for value in values
            result = {
              parent: node
              level: @levels[levelNumber]
              name: value
              children: null
            }
            result = addLevelProperties(result)
          node
        else
          node.children = for key, value of values
            result = {
              parent:node
              level: @levels[levelNumber]
              name:key
            }
            result = addLevelProperties(result)
            addChildren result, value, levelNumber+1
          return node

      addChildren(@root, @hierarchy, 0)

      # Load up the district translation mapping
      Coconut.database.get "district_language_mapping"
      .catch (error) ->
        console.error "Error loading district_language_mapping:"
        console.error error
        options.error(error)
      .then (result) =>
        @englishToSwahiliDistrictMapping = result.english_to_swahili
        options.success()

  swahiliDistrictName: (district) =>
    @englishToSwahiliDistrictMapping[district] or district
      
  englishDistrictName: (district) =>
    _(@englishToSwahiliDistrictMapping).invert()[district] or district


  findInNodes: (nodes, requiredProperties) =>
    results = _(nodes).where requiredProperties

    if _(results).isEmpty()
      results = (for node in nodes
        @findInNodes(node.children, requiredProperties)
      ) if nodes?
      results = _.chain(results).flatten().compact().value()
      return [] if _(results).isEmpty()

    return results

  find: (name,level) =>
    @findInNodes(@root.children, {name: name.toUpperCase() if name, level:level.toUpperCase() if level})

  findFirst: (name,level) ->
    result = @find(name,level)
    if result? then result[0] else {}

  findAllForLevel: (level) =>
    @findInNodes(@root.children, {level: level})

  findChildrenNames: (targetLevel, parentName) =>
    indexOfTargetLevel = _(@levels).indexOf(targetLevel)
    parentLevel = @levels[indexOfTargetLevel-1]
    nodeResult = @findInNodes(@root.children, {name:parentName, level:parentLevel})
    return [] if _(nodeResult).isEmpty()
    console.error "More than one match" if nodeResult.length > 2
    return _(nodeResult[0].children).pluck "name"

  # I think this is redundant-ish
  findAllDescendantsAtLevel: (name, sourceLevel, targetLevel) =>

    getLevelDescendants = (node) ->
      return node if node.level is targetLevel
      return (for childNode in node.children
        getLevelDescendants(childNode)
      )

    sourceNode = @find(name, sourceLevel)
    _.flatten(getLevelDescendants sourceNode[0])

  findShehia: (targetShehia) =>
    @find(targetShehia,"SHEHIA")

  findOneShehia: (targetShehia) =>
    shehia = @findShehia(targetShehia)
    switch shehia.length
      when 0 then return null
      when 1 then return shehia[0]
      else
        return undefined

  validShehia: (shehia) =>
    @findShehia(shehia)?.length > 0

  findAllShehiaNamesFor: (name, level) =>
    _.pluck @findAllDescendantsAtLevel(name, level, "SHEHIA"), "name"

  findAllDistrictsFor: (name, level) =>
    _.pluck @findAllDescendantsAtLevel(name, level, "DISTRICT"), "name"

  allRegions: =>
    _.pluck @findAllForLevel("REGION"), "name"

  allDistricts: =>
    _.pluck @findAllForLevel("DISTRICT"), "name"

  allShehias: =>
    _.pluck @findAllForLevel("SHEHIA"), "name"

  allUniqueShehiaNames: =>
    _(_.pluck @findAllForLevel("SHEHIA"), "name").uniq()

  all: (geographicHierarchy) =>
    _.pluck @findAllForLevel(geographicHierarchy.toUpperCase()), "name"

  # TODO This isn't going to work
  update: (region,district,shehias) =>
    @hierarchy[region][district] = shehias
    geoHierarchy = new GeoHierarchy()
    geoHierarchy.fetch
      error: (error) -> console.error JSON.stringify error
      success: (result) =>
        geoHierarchy.save "hierarchy", @hierarchy,
          error: (error) -> console.error JSON.stringify error
          success: () ->
            Coconut.debug "GeoHierarchy saved"
            @load

  @getZoneForDistrict: (district) ->
    districtHierarchy = @find(district,"DISTRICT")
    if districtHierarchy.length is 1
      region = @find(district,"DISTRICT")[0].REGION
      return @getZoneForRegion region
    return null

  @getZoneForRegion: (region) ->
    if region.match /PEMBA/
      return "PEMBA"
    else
      return "UNGUJA"

  @districtsForZone = (zone) =>
    _.chain(@allRegions())
      .map (region) =>
        if @getZoneForRegion(region) is zone
          @findAllDistrictsFor(region, "REGION")
      .flatten()
      .compact()
      .value()

module.exports = GeoHierarchy
