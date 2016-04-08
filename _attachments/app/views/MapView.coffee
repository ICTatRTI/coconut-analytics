_ = require "underscore"
$ = require "jquery"
Backbone = require "backbone"
Backbone.$  = $


require 'mapbox.js'
materialControl = require 'leaflet-material-controls'
global.L = require 'leaflet'
Reports = require '../models/Reports'
leafletImage = require 'leaflet-image'

class MapView extends Backbone.View
  el: '#content'

  events:
    "click #pembaToggle, #ungugaToggle ": "buttonClick"
    "focus #map": "mapFocus"
    "blur #map": "mapBlur"
    "click #snapImage": "snapImage"
    
  buttonClick: (event)=>
    console.log event.toElement.id
    if event.toElement.id == "pembaToggle"
        $('#pembaToggle').toggleClass 'mdl-button--raised', true
        $('#ungugaToggle').toggleClass 'mdl-button--raised', false
        console.log "you're in pemba dawg"
        @map.setView([-6.1, 39.348], 10, {animate:true})
    else
        $('#pembaToggle').toggleClass 'mdl-button--raised', false
        $('#ungugaToggle').toggleClass 'mdl-button--raised', true
        console.log "you're in ugunga dawg"
        @map.setView([-5.187, 39.746], 10, {animate:true})
  mapFocus: =>
    console.log("scrolwheelStatus: "+@map.scrollWheelZoom.enabled())
    if @map.scrollWheelZoom.enabled() == false
      @map.scrollWheelZoom.enable()
      console.log('scrollwheeltrue')
    console.log("mapFocus")

  mapBlur: =>
    console.log("mapBlur")    
    if @map.scrollWheelZoom.enabled() == true
      @map.scrollWheelZoom.disable()
      console.log('scrollwheelfalse')
        
  snapImage: =>
    console.log "snapped"         
#    progressBar.showPleaseWait()

    console.log @map.scrollWheelZoom.enabled()
    leafletImage @map, (err, canvas) =>
      console.log("snapshot: "+ @snapshot)
      console.log 'image Snap'
      img = document.createElement('img') 
      dimensions = @map.getSize()
      console.log "dimensions: "+dimensions
      img.width = dimensions.x
      img.height = dimensions.y
      console.log "img.width: "+img.width
      img.src = canvas.toDataURL()
      @snapshot.innerHTML = ''
      @snapshot.appendChild img
      console.log "snapshot: "+snapshot.innerHTML
#      progressBar.hidePleaseWait()
      return
    return

  
    
  render: =>
    options = Coconut.router.reportViewOptions
    GeoJSONOb = 
      'type': 'FeatureCollection'
      'features': []
    console.log options.startDate
    console.log options.endDate
    Reports.getCases
      startDate: options.startDate
      endDate: options.endDate
      success: (results) ->
        GeoJSONOb.features =  _(results).chain().map (malariaCase) ->
          if malariaCase.Household?["HouseholdLocation-latitude"]
            { 
              type: 'Feature'
              properties:
                MalariaCaseID: malariaCase.caseID
                hasAdditionalPositiveCasesAtIndexHousehold: malariaCase.hasAdditionalPositiveCasesAtIndexHousehold()
                date: malariaCase.Household?.lastModifiedAt
              geometry:
                type: 'Point'
                coordinates: [
                  malariaCase.Household?["HouseholdLocation-longitude"]
                  malariaCase.Household?["HouseholdLocation-latitude"]
                ]
            }
        .compact().value()
    
#        console.log 'dataForMaps: ' + JSON.stringify GeoJSONOb

        updateMap GeoJSONOb


    @$el.html "
        <div class='mdl-grid'>
            <div class='mdl-cell mdl-cell--1-col'></div>
            <div class='mdl-cell mdl-cell--10-col'>
                <div id='dateSelector'></div>
<label for='pembeToggle'>Switch to: </label>
        <button id='pembaToggle' class='mdl-button mdl-js-button mdl-button--primary mdl-js-ripple-effect mdl-button--accent'>Pemba</button>
            <label for='ungugaToggle'>or</label>
        <button id='ungugaToggle' class='mdl-button mdl-js-button mdl-button--primary mdl-js-ripple-effect mdl-button--accent'>Unguga</button>
        
            </div>
            <div class='mdl-cell mdl-cell--1-col'></div>
        </div>
        <div class='mdl-grid'>
            <div class='mdl-cell mdl-cell--1-col'></div>
            <div class='mdl-cell mdl-cell--10-col'>
                <div style='width:100%;height:600px;' id='map'></div>
            </div>
            <div class='mdl-cell mdl-cell--1-col'></div>
        </div>
        <div class='mdl-grid'>
            <div class='mdl-cell mdl-cell--1-col'></div>
            <div class='mdl-cell mdl-cell--10-col'>
                <button id='snapImage' class='mdl-button mdl-js-button mdl-button--primary mdl-js-ripple-effect mdl-button--accent'>Snap Image</button>
                <div id = 'snapshot' style='width:100%;'>
                </div>
            </div>
            <div class='mdl-cell mdl-cell--1-col'></div>
        </div>
    "
    #working
    @snapshot = document.getElementById('snapshot') 
    L.mapbox.accessToken = 'pk.eyJ1Ijoid29ya21hcHMiLCJhIjoiY2lsdHBxNGx3MDA5eXVka3NvbDl2d2owbSJ9.OptFbCtSJblFz-qKgwp65A'
    @map = L.mapbox.map('map', 'mapbox.streets',
      zoomControl: false
      attributionControl: true).setView([-5.67, 39.489], 9)
    layers = 
      Streets: L.mapbox.tileLayer('mapbox.streets')
      Outdoors: L.mapbox.tileLayer('mapbox.outdoors')
      Satellite: L.mapbox.tileLayer('mapbox.satellite')
    @geojson = {}
    overlays = 
      Cases: L.geoJson().addTo(@map)
      Shahias: L.geoJson()
    materialOptions = 
      fab: true
      miniFab: true
      rippleEffect: true
      toolTips: false
      color: 'cyan'
    materialZoomControl = new (materialControl.Zoom)(
      position: 'topright'
      materialOptions: materialOptions).addTo(@map)
    materialLayerControl = new (materialControl.Layers)(layers, overlays,
      position: 'topright'
      materialOptions: materialOptions).addTo(@map)
#    materialLayerControl = new (materialControl.Layers)(layers, overlays,
#      position: 'topright'
#      materialOptions: materialOptions).addTo(@map)
    updateMap = (data) =>
        geojsonFeature = data
        geojsonMarkerOptions = 
          radius: 8
          fillColor: '#ff7800'
          color: '#000'
          weight: 1
          opacity: 1
          fillOpacity: 0.8
        @geojson = L.geoJson(geojsonFeature, onEachFeature: onEachFeature, pointToLayer: (feature, latlng) =>
          L.circleMarker latlng, geojsonMarkerOptions
        ).addTo(@map)
        console.log "updateFinished"
        return
    onEachFeature = (feature, layer) ->
      console.log "feature: "+JSON.stringify feature
      console.log "layer: "+JSON.stringify layer
      layer.bindPopup "caseID: " + feature.properties.MalariaCaseID + "<br />\n Household Cases: " + feature.properties.hasAdditionalPositiveCasesAtIndexHousehold + "<br />\n Date: "+feature.properties.date 
      return

module.exports = MapView
