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
    heat = L.heatLayer(heatMapCoords, radius: 10) 
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
    casesOb = 
      'type': 'FeatureCollection'
      'features': []
    console.log options.startDate
    console.log options.endDate
    Reports.getCases
      startDate: options.startDate
      endDate: options.endDate
      success: (results) ->
#        console.log "results: " + JSON.stringify results
        casesOb.features =  _(results).chain().map (malariaCase) ->
          if malariaCase.Household?["HouseholdLocation-latitude"]
            { 
              type: 'Feature'
              properties:
                MalariaCaseID: malariaCase.caseID
                hasAdditionalPositiveCasesAtIndexHousehold: malariaCase.hasAdditionalPositiveCasesAtIndexHousehold()
                numberOfCasesInHousehold: malariaCase.positiveCasesAtIndexHousehold().length
                numberOfCasesInHousehold: malariaCase.positiveCasesAtIndexHousehold().length
                date: malariaCase.Household?.lastModifiedAt
              geometry:
                type: 'Point'
                coordinates: [
                  malariaCase.Household?["HouseholdLocation-longitude"]
                  malariaCase.Household?["HouseholdLocation-latitude"]
                ]
            }
        .compact().value()
        
        updateMap casesOb

    @$el.html "
        <style>
        .legend {
            line-height: 18px;
            color: #555;
            background: white
            padding: 6px 8px;
			font: 14px/16px Arial, Helvetica, sans-serif;
			background: white;
			background: rgba(255,255,255,0.8);
			box-shadow: 0 0 15px rgba(0,0,0,0.2);
			border-radius: 5px;
        }
        .legend i {
            width: 18px;
            height: 18px;
            float: left;
            margin-right: 8px;
            opacity: 0.7;
        }
        .legend .caseCircle {
          border-radius: 50%;
          width: 10px;
          height: 10px;
          margin-top: 8px;
        }
        .legend .caseCircle {
          border-radius: 50%;
          width: 10px;
          height: 10px;
          margin-top: 8px;
        }
        </style>
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
        <div id='results' class='result'>
      
    "
    #working
    @snapshot = document.getElementById('snapshot') 
    L.mapbox.accessToken = 'pk.eyJ1Ijoid29ya21hcHMiLCJhIjoiY2lsdHBxNGx3MDA5eXVka3NvbDl2d2owbSJ9.OptFbCtSJblFz-qKgwp65A'
    streets = L.mapbox.tileLayer('mapbox.streets')
    outdoors = L.mapbox.tileLayer('mapbox.outdoors')
    satellite = L.mapbox.tileLayer('mapbox.satellite')
    layers = 
      Streets: streets
      Outdoors: outdoors
      Satellite: satellite
    overlays = undefined
    @map = L.map('map',
      center: [
        -5.67, 39.489
      ]
      zoom: 9
      layers: [
        streets
      ]
      zoomControl: false
      attributionControl: false)
    @map.lat = -5.67
    @map.lng = 39.489
    @map.zoom = 9
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
    layerControl = L.control.layers(layers, overlays).addTo @map
#    $('.leaflet-control-layers').addClass 'mdl-button mdl-js-button mdl-button--fab mdl-button--mini-fab mdl-js-ripple-effect mdl-color--cyan'
    #    materialLayerControl = new (materialControl.Layers)(layers, overlays,
#      position: 'topright'
#      materialOptions: materialOptions).addTo(@map)
#    materialLayerControl = new (materialControl.Layers)(layers, overlays,
#      position: 'topright'
#      materialOptions: materialOptions).addTo(@map)
    updateMap = (data) =>
        console.log "data: "+JSON.stringify data
        caseMarkerOptions = 
          radius: 4
          fillColor: '#ff7800'
          color: '#000'
          weight: 0.5
          opacity: 1
          fillOpacity: 0.8
        casesMarkerOptions = 
          radius: 6
          fillColor: 'red'
          color: '#000'
          weight: 0.5
          opacity: 1
          fillOpacity: 0.8    
        casesGeoJSON = L.geoJson(data, 
          onEachFeature: (feature, layer) =>
            coords = [
              feature.geometry.coordinates[1]
              feature.geometry.coordinates[0]
              5000/data.features.length#adjust with slider
            ]
            heatMapCoords.push coords
            layer.bindPopup "caseID: " + feature.properties.MalariaCaseID + "<br />\n Household Cases: " + feature.properties.numberOfCasesInHousehold + "<br />\n Date: "+feature.properties.date 
            return
          pointToLayer: (feature, latlng) =>
            # household markers with secondary cases
            #clusering as well
            if feature.properties.hasAdditionalPositiveCasesAtIndexHousehold == false
                L.circleMarker latlng, caseMarkerOptions
            else
                L.circleMarker latlng, casesMarkerOptions
          ).addTo(@map)
        console.log "updateFinished"
        layerControl.addOverlay casesGeoJSON, 'Cases'
        
        legend = L.control(position: 'topleft')

        legend.onAdd = (@map) =>
          div = L.DomUtil.create('div', 'legend')
          div.innerHTML 'Legend'
          categories = [
            'Single Case'
            'Multiple Cases'
          ]
          i = 0
          while i < categories.length
            div.innerHTML += '<i style="background:' + getColor(categories[i]) + '"></i> ' + (if categories[i] then categories[i] + '<br>' else '+')
            i++
          div

        legend.addTo @map
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
    