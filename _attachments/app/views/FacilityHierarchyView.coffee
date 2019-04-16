_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
PouchDB = require 'pouchdb'
global.jQuery = require 'jquery'
Dialog = require './Dialog'
humanize = require 'underscore.string/humanize'
Tabulator = require 'tabulator-tables'

# TODO Make this editable and save it back to Dhis2.json
class FacilityHierarchyView extends Backbone.View
  el: '#content'

  render: =>
    @$el.html "
      <h1>Facilities</h1>
      <div id='facility-table'></div>
    "
    privateFacilities = GeoHierarchy.allPrivateFacilities()
    facilities = _(GeoHierarchy.findAllForLevel("FACILITY")).map (facilityUnit) =>
      id: facilityUnit.id
      Region: facilityUnit.parent()?.parent()?.parent()?.name
      District: facilityUnit.parent().name
      Name: facilityUnit.name
      Aliases: facilityUnit.aliases
      "Phone Numbers": facilityUnit.phoneNumber?.join(",")
      Type: if _(privateFacilities).contains(facilityUnit.name) then "PRIVATE" else "PUBLIC"

    new Tabulator "#facility-table", 
      height: 400
      data: facilities
      columns: [
        {title: "Region", field: "Region", headerFilter: "select", headerFilterParams: {values:true}}
        {title: "District", field: "District", headerFilter: true}
        {title: "Name", field: "Name", headerFilter: true}
        {title: "Aliases", field: "Aliases", headerFilter: true}
        {title: "Phone Numbers", field: "Phone Numbers", headerFilter: true}
        {title: "Type", field: "Type", headerFilter: "select", headerFilterParams: {values:true}}
      ]

module.exports = FacilityHierarchyView
