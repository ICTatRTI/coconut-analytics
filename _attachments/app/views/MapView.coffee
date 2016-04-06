_ = require "underscore"
$ = require "jquery"
Backbone = require "backbone"
Backbone.$  = $
L = require 'leaflet'
Reports = require '../models/Reports'

class MapView extends Backbone.View
  el: '#content'

  events:
    "click #foo": "buttonClick"

  buttonClick: =>
    @map.setView([40, 74.5], 3)

  render: =>

    options = Coconut.router.reportViewOptions

    Reports.getCases
      startDate: options.startDate
      endDate: options.endDate
      success: (results) ->
        console.log results

        dataForMaps = _(results).chain().map (malariaCase) ->
          if malariaCase.Household?["HouseholdLocation-latitude"]
            {
              MalariaCaseID: malariaCase.caseID
              latitude: malariaCase.Household?["HouseholdLocation-latitude"]
              longitude: malariaCase.Household?["HouseholdLocation-longitude"]
              hasAdditionalPositiveCasesAtIndexHousehold: malariaCase.hasAdditionalPositiveCasesAtIndexHousehold()
              date: malariaCase.Household?.lastModifiedAt
            }
        .compact().value()

        console.debug dataForMaps

    @$el.html "
        <div id='dateSelector'></div>
        <button id='foo'>Click me</button>
        <h3>Mockup Rap</h3>
        <div>Use + - buttons to zoom map. Click and drag to reposition the map. Circles with a darker have multiple cases. Red cases show households with additional positive malaria cases.<br> 
    <!--
		<div>
		   <img src='images/sample-map.png' />
		</div>
    -->
    <div style='width:200px;height:200px;' id='map'></div>
    "
    
    @map = L.map('map')
    @map.setView([40, -74.5], 3)
    L.tileLayer('http://{s}.tile.osm.org/{z}/{x}/{y}.png', { attribution: '&copy; <a href="http://osm.org/copyright">OpenStreetMap</a> contributors' }).addTo(@map)
    




module.exports = MapView
