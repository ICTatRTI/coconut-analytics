PouchDB = require 'pouchdb-core'
PouchDB.plugin(require('pouchdb-adapter-http'))
PouchDB.plugin(require('pouchdb-mapreduce'))
PouchDB.plugin(require('pouchdb-upsert'))
Request = require 'request-promise-native'
_ = require 'underscore'
moment = require 'moment'
fs = require 'fs'
exec = require('child_process').execSync

GeographicHierarchy =
  isApplicationDoc: true
  dateCreated: new moment().format("YYYY-MM-DD")
  levels: []
  groups: []
  units: []

privateGroupId = null

resultsById = {}


dhis2Request = (query) =>
  #apiUrl = "http://173.255.223.117/api/"
  apiUrl = "https://mohzn.go.tz/api/"
  console.error "#{apiUrl}#{query}"
  Request.get
    uri: "#{apiUrl}#{query}"
    auth:
      user: "coconut"
      pass: "Coconut@2019"
    json: true
    qs:
      paging: false

updateUnit = (unitId) =>
  unit = await dhis2Request "organisationUnits/#{unitId}"
  if unit.level is 7
    console.warn "Skipping: #{unit.name}"
    return
  console.warn unit.name
  result = 
    name: unit.name
    parentId: unit.parent?.id
    level: unit.level
    id: unit.id

  if resultsById[unit.id] # Not sure why we get duplicate units for the same ID, sometimes the names are the same sometimes they are variations

    if resultsById[unit.id].name is unit.name # If it's the same name for the same ID nothing left to do
      console.warn "Duplicate name: #{unit.name}"
    else if resultsById[unit].aliases.find (alias) => alias.name is unit.name # If we already have an alias for this name return
      console.warn "Duplicate alias: #{alias.name}"
    else
      resultsById[unit.id].aliases or= []
      resultsById[unit.id].aliases.push
        name: unit.shortName
        description: "Other name"
    return

  # Find private units and put them in the private group
  if _(unit.organisationUnitGroups).find (group) => group.id is privateGroupId
    privateGroup = GeographicHierarchy.groups.find (group) =>
      group.groupId is privateGroupId
    privateGroup.unitIds.push unit.id if privateGroup

  if unit.name isnt unit.shortName
    result.aliases or= []
    result.aliases.push
      name: unit.shortName
      description: "Short Name"

  resultsById[unit.id] = result


getLevels = =>
  # Get all Levels
  for level in await dhis2Request "filledOrganisationUnitLevels"
    GeographicHierarchy.levels.push
      name: level.name
      number: level.level
      id: level.id


getGroups = =>
  # Only interested in PRIVATE health facilities for now
  for group in (await dhis2Request "organisationUnitGroups.json").organisationUnitGroups
    console.error group.displayName
    if group.displayName is "Private"
      privateGroupId = group.id
      GeographicHierarchy.groups.push
        name: "PRIVATE"
        groupId: group.id
        unitIds: []


createGeographicHierarchy = =>

  console.warn "Messages appear on STDERR, while the actual result is on STDOUT, so use > out.json to capture the result of this script"
  console.warn "Getting Levels"
  await getLevels()

  console.warn "Getting Groups"
  await getGroups()

  console.warn "Getting Org Units"
  units = (await dhis2Request "organisationUnits.json").organisationUnits

  i=0
  numberToGetInParallel = 20

  while i < units.length
    console.warn "#{i}/#{units.length}"

    await Promise.all(units[i..i+=numberToGetInParallel].map (unitId) =>
      updateUnit(unitId.id)
    )

  GeographicHierarchy.units = _(resultsById).sortBy (result, id) => result.name # returns array of units sorted by name to make it easier to look through
  GeographicHierarchy



(=> 
  if process.argv[2] is "--update" and target = process.argv[3]
    console.warn "Creating new geographic hierarchy and then updating"
    splitTarget = target.split(/\//)
    docName = splitTarget.pop()
    db = splitTarget.join("/")
    database = new PouchDB(db)
    console.log await(database.info())
    console.log docName
    geographicHierarchy = await createGeographicHierarchy()
    await database.upsert docName, (doc) => geographicHierarchy
    .catch (error) => console.error error
    console.warn "#{docName} updated at #{db}."

  else if process.argv[2] is "--diff" and target = process.argv[3]
    fs.writeFileSync "/tmp/currentUnformatted.json", (await Request.get
      uri: target
    ), (error) -> console.error error
    exec "cat /tmp/currentUnformatted.json | /usr/bin/jq . > /tmp/current.json", (error) => console.error error
    console.warn "/tmp/current.json written"

    fs.writeFileSync "/tmp/newUnformatted.json", JSON.stringify(await createGeographicHierarchy()), (error) -> console.error error
    exec "cat /tmp/newUnformatted.json | jq . > /tmp/new.json"
    console.warn "/tmp/new.json written"
    console.warn "use diff or meld to compare, e.g. meld /tmp/current.json /tmp/new.json"

  else
    JSON.stringify createGeographicHierarchy()

)()
