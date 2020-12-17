# Originally used on the client, for validation I assume
class HouseholdMember

  constructor: (@docId) ->

  load: (@doc) =>
    @docId = @doc._id
    # TODO handle legacy docs

  fetch: =>
    Coconut.database.get(@docId)
    .catch (error) =>
      throw "Unable to load Household Member with docId: #{@docId}. Error: #{error}"
    .then (result) =>
      @load(result)

  parasiteType: =>
    if @doc["MalariaMrdtTestResults"] is "P.f"
      "P. falciparum"
    else if @doc["MalariaMrdtTestResults"] is  "P.f + Pan (Mixed)"
      "Mixed"
    else if (
      @doc["MalariaMicroscopyTestResults"] is "P. falciparum" or
      @doc["MalariaMicroscopyTestResults"] is "P. malariae" or
      @doc["MalariaMicroscopyTestResults"] is "P. vivax" or
      @doc["MalariaMicroscopyTestResults"] is "P. ovale" or
      @doc["MalariaMicroscopyTestResults"] is "Mixed"
    )
        @doc["MalariaMicroscopyTestResults"]
    else
      null

  isPositive: =>
    @parasiteType() isnt null

  dateFoundPositive: =>
    if (
      @doc["HouseholdMemberType"] is "Index Case" or 
      @doc["HouseholdMemberType"] is "Additional Index Case"
    )
        null # TODO either get from facility or add date to questions
    else
      @doc["LastModifiedAt"]
  
module.exports = HouseholdMember
