_ = require "underscore"
$ = require "jquery"
Backbone = require "backbone"
Backbone.$  = $


require 'mapbox.js'
materialControl = require 'leaflet-material-controls'
#global.L = require 'leaflet'
Reports = require '../models/Reports'
leafletImage = require 'leaflet-image'
class MapView extends Backbone.View
  
  heatMapCoords = []
  
  casesGeoJSON = 
    'type': 'FeatureCollection'
    'features': []
    
  el: '#content'

  events:
    "click #pembaToggle, #ungugaToggle ": "buttonClick"
    "click #heatMapToggle": "heatMapToggle"
#    "focus #map": "mapFocus"
#    "blur #map": "mapBlur"
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
  
  heatMapToggle: =>
#    coords = [
#      [
#        -5.178
#        39.808
#        5000
#      ]
#      [
#        -5.18
#        39.81
#        5000
#      ]
#    ]
    console.log("@map.scrollWheelZoom.enabled() = "+@map.scrollWheelZoom.enabled())
#    console.log("coords: "+coords);
    console.log("@heatmapcoords: "+heatMapCoords)
    heat = L.heatLayer(heatMapCoords, radius: 25) 
    heat.addTo(@map)
    
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

    leafletImage @map, (err, canvas) =>
      console.log("snapshot: "+ @snapshot)
      console.log 'image Snap'
#      img = document.createElement('img') 
#      dimensions = @map.getSize()
#      console.log "dimensions: "+dimensions
#      img.width = dimensions.x
#      img.height = dimensions.y
#      console.log "img.width: "+img.width
#      img.src = canvas.toDataURL()
      a = document.createElement('a')
      a.href = canvas.toDataURL('image/jpeg').replace('image/jpeg', 'image/octet-stream')
      a.download = 'coconutMap.jpg'
      a.click()

      @snapshot.innerHTML = ''
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
        console.log JSON.stringify GeoJSONOb
        

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
                <label for='heatMapToggle'>Turn Heat Map</label>
                <button id='heatMapToggle' class='mdl-button mdl-js-button mdl-button--primary mdl-js-ripple-effect mdl-button--accent'>ON</button>
        
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
      attributionControl: false).setView([-5.67, 39.489], 9)
    layers = 
      Streets: L.mapbox.tileLayer('mapbox.streets')
      Outdoors: L.mapbox.tileLayer('mapbox.outdoors')
      Satellite: L.mapbox.tileLayer('mapbox.satellite')
#    overlays = 
#      'Bike Stations': L.geoJson(
#        'type': 'Feature'
#        'properties':
#          'name': 'Coors Field'
#          'amenity': 'Baseball Stadium'
#          'popupContent': 'This is where the Rockies play!'
#        'geometry':
#          'type': 'Point'
#          'coordinates': [
#            -104.99404
#            39.75621
#          ]).addTo(@map)
#      'Bike Lanes': L.geoJson({
#        "type": "Feature",
#        "properties": {
#            "name": "Coors Field",
#            "amenity": "Baseball Stadium",
#            "popupContent": "This is where the Rockies play!"
#        },
#        "geometry": {
#            "type": "Point",
#            "coordinates": [-104.99404, 39.75621]
#        }
#    })
    overlays = null
    materialOptions = 
      fab: true
      miniFab: true
      rippleEffect: true
      toolTips: false
      color: 'cyan'
    materialZoomControl = new (materialControl.Zoom)(
      position: 'topright'
      materialOptions: materialOptions).addTo(@map)
    materialFullscreen = new (L.materialControl.Fullscreen)(position: 'topright',
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
        @geojson = L.geoJson(geojsonFeature, 
          onEachFeature: (feature, layer) =>
            coords = [
              feature.geometry.coordinates[1]
              feature.geometry.coordinates[0]
              10000/data.features.length#adjust with slider
            ]
            heatMapCoords.push coords
            console.log "heatmapCoords: "+heatMapCoords
            layer.bindPopup "caseID: " + feature.properties.MalariaCaseID + "<br />\n Household Cases: " + feature.properties.hasAdditionalPositiveCasesAtIndexHousehold + "<br />\n Date: "+feature.properties.date 
            return
          pointToLayer: (feature, latlng) =>
            
            # household markers with secondary cases
            #clusering as well
            L.circleMarker latlng, geojsonMarkerOptions
          ).addTo(@map)
        console.log "updateFinished"
        return
#    onEachFeature = (feature, layer) ->
#      coords = [
#        feature.geometry.coordinates[1]
#        feature.geometry.coordinates[0]
#        100
#      ]
#      heatMapCoords.push coords
#      console.log "heatmapCoords: "+heatMapCoords
#      layer.bindPopup "caseID: " + feature.properties.MalariaCaseID + "<br />\n Household Cases: " + feature.properties.hasAdditionalPositiveCasesAtIndexHousehold + "<br />\n Date: "+feature.properties.date 
#      return
   
module.exports = MapView
    