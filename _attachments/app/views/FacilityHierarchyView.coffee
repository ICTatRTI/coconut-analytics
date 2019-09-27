_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
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
      <!--
      <div id='edit-facility'>
        <table>
        #{
          (for field in ["Region", "District","Name","Phone Numbers"]
            "
            <tr>
              <td>
                <label for='#{field}'>#{field}</lable>
              </td>
              <td>
                <input name='#{field}'></input>
              </td>
            </tr>
            "
          ).join("")
        }
          <tr>
            <td>
              <label for='Type'>Facility Type</lable>
            </td>
            <td>
              <select name='Type'>
                <option>Public</option>
                <option>Private</option>
              </select>
            </td>
          </tr>
          <tr>
            <td><button id='save'>Save</button></td>
          </tr>
        </table>
      </div>
      -->


    "
    privateFacilities = GeoHierarchy.allPrivateFacilities()
    facilities = _(GeoHierarchy.findAllForLevel("FACILITY")).map (facilityUnit) =>
      id: facilityUnit.id
      Region: facilityUnit.parent()?.parent()?.parent()?.name
      District: facilityUnit.parent().name
      Name: facilityUnit.name
      Aliases: facilityUnit.aliases
      "Phone Numbers": if _(facilityUnit.phoneNumber?).isArray() then facilityUnit.phoneNumber?.join(",") else facilityUnit.phoneNumber
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

  events:
    "click #save": "save"

module.exports = FacilityHierarchyView
