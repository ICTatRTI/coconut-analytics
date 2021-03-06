###
Backbone = require 'backbone'


class FacilityHierarchy extends Backbone.Model

  initialize: ->
    console.error "Facility hierarchy is deprecated!! Features here should all be available in GeoHierarchy"
    
    @set
      _id: "Facility Hierarchy"

  url: "/facilityHierarchy"

  #Note that the facilities after the line break are hospitals


  FacilityHierarchy.load = (options) ->
    facilityHierarchy = new FacilityHierarchy()
    facilityHierarchy.fetch
      success: ->
        FacilityHierarchy.hierarchy = facilityHierarchy.get("hierarchy")
        options.success()
      error: (error) ->
        console.error "Error loading Facility Hierarchy: #{JSON.stringify(error)}"
        options.error(error)

  FacilityHierarchy.allDistricts = ->
    _.keys(FacilityHierarchy.hierarchy).sort()

  FacilityHierarchy.allFacilities = ->
    _.chain(FacilityHierarchy.hierarchy).values().flatten().pluck("facility").value()


  # Need this for handling aliases
  FacilityHierarchy.getFacility = (facility) ->
    facility = facility.trim() if facility
    if _(FacilityHierarchy.allFacilities()).contains facility
      return facility

    # Still no match? - check aliases
    result = null
    _.each FacilityHierarchy.hierarchy, (districtFacilities) ->
      return if result?

      matchedFacilityData =  _(districtFacilities).find (facilityData) ->
        _(facilityData.aliases).contains(facility)

      result = matchedFacilityData.facility if matchedFacilityData

    return result

  FacilityHierarchy.getDistrict = (facility) ->
    facility = facility.trim() if facility
    result = null
    _.each FacilityHierarchy.hierarchy, (facilityData,district) ->
      if _.chain(facilityData).pluck("facility").contains(facility).value()
        result = district
    return result if result

    # Still no match? - check aliases
    _.each FacilityHierarchy.hierarchy, (facilityData,district) ->
      if _.chain(facilityData).pluck("aliases").flatten().compact().contains(facility).value()
        result = district
    return result

  FacilityHierarchy.getZone = (facility) ->
    district = FacilityHierarchy.getDistrict facility
    districtHierarchy = GeoHierarchy.find(district,"DISTRICT")
    zone = null
    if districtHierarchy.length is 1
      region = GeoHierarchy.find(district,"DISTRICT")[0].REGION
      if region.match /PEMBA/
        zone = "PEMBA"
      else
        zone = "UNGUJA"

    return zone

  FacilityHierarchy.facilities = (district) ->
    _.pluck FacilityHierarchy.hierarchy[district], "facility" if FacilityHierarchy.hierarchy?

  FacilityHierarchy.facilitiesForDistrict = (district) ->
    FacilityHierarchy.facilities(district)

  FacilityHierarchy.facilitiesForZone = (zone) ->
    districtsInZone = GeoHierarchy.districtsForZone(zone)
    _.chain(districtsInZone)
      .map (district) ->
        FacilityHierarchy.facilities(district)
      .flatten()
      .value()

  FacilityHierarchy.numbers = (district,facility) ->
    foundFacility =  _(FacilityHierarchy.hierarchy[district]).find (result) ->
      result.facility is facility
    foundFacility["mobile_numbers"]

  FacilityHierarchy.update = (district,targetFacility,numbers, options) ->
    console.log numbers

    facilityIndex = -1
    _(FacilityHierarchy.hierarchy[district]).find (facility) ->
      facilityIndex++
      facility['facility'] is targetFacility

    if facilityIndex is -1
      FacilityHierarchy.hierarchy[district].push {
        facility: targetFacility
        mobile_numbers: numbers
      }

    else
      FacilityHierarchy.hierarchy[district][facilityIndex] =
        facility: targetFacility
        mobile_numbers: numbers

    facilityHierarchy = new FacilityHierarchy()
    facilityHierarchy.fetch
      error: (error) -> console.error JSON.stringify error
      success: (result) ->
        facilityHierarchy.save "hierarchy", FacilityHierarchy.hierarchy,
          error: (error) -> console.error JSON.stringify error
          success: () ->
            Coconut.debug "FacilityHierarchy saved"
            FacilityHierarchy.load
              error: (error) -> console.error JSON.stringify error
              success: () -> options?.success()

  FacilityHierarchy.facilityType = (facilityName) ->
    result = null
    _.each FacilityHierarchy.hierarchy, (facilities,district) ->
      if result is null
        facility = _.find facilities, (facility) ->  facility.facility is facilityName
        result = facility.type.toUpperCase() if facility
    return result

  FacilityHierarchy.allPrivateFacilities = ->
    _.chain(FacilityHierarchy.hierarchy).values().flatten().filter( (facility) -> facility.type is "private" ).pluck("facility").value()

module.exports = FacilityHierarchy
###
