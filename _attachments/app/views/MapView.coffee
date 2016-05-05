_ = require "underscore"
$ = require "jquery"
Backbone = require "backbone"
Backbone.$  = $


require 'mapbox.js'
materialControl = require 'leaflet-material-controls'
#global.L = require 'leaflet'
Reports = require '../models/Reports'
leafletImage = require 'leaflet-image'
require '../../mapdata/DistrictsWGS84.json'
require '../../mapdata/ShahiasWGS84.json'
require '../../mapdata/VillagesWGS84.json'
class MapView extends Backbone.View
  map = undefined
  clusters = undefined
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
  adminPolyOptions =
    fillColor: '#4292C6'
    color: '#ffffff'
    weight: 0.2
    opacity: 1
    fillOpacity: 0.8
  heatMapCoords = [] 
  heatMapCoordsTime = []
  heatMapOn = false
  heat = undefined
  heatTime = undefined
  startDate = undefined
  endDate = undefined
  timeInterval = '2014-09-30/2014-10-30'
  materialHeatMapControl = undefined
  materialClusterControl = undefined
  materialTimeControl = undefined
  casesLayer = undefined
  casesGeoJSON = undefined
  turnCasesLayerOn = false;
  timeCasesGeoJSON = undefined
  districtsData = undefined
  shahiasData = undefined
  villagesData = undefined
  textE = undefined
  textW = undefined
  timeLayer = undefined
  timeHeatMapLayer = undefined
  timeScale = undefined
  outFormat = d3.time.format("%Y-%m-%d")
  el: '#content'

  events:
    "click #pembaToggle, #ungugaToggle ": "buttonClick"
    "click .heatMapButton, #heatMapToggle": "heatMapToggle"
    "click .timeButton": "timeToggle"
    "click .clusterButton": "clusterToggle"
    "focus #map": "mapFocus"
    "blur #map": "mapBlur"
    "click #snapImage": "snapImage"
    
  buttonClick: (event)=>
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
    if heatMapCoords.length>0
        if !materialHeatMapControl.toggleState
            materialHeatMapControl.toggleState = true
            $('.heatMapButton button').removeClass( "mdl-color--cyan" ).addClass( "mdl-color--red" );
            heat = L.heatLayer(heatMapCoords, radius: 10) 
            @map.addLayer(heat)
            if @map.hasLayer casesLayer
              console.log('remove')
              @map.removeLayer casesLayer
              turnCasesLayerOn = true
        else
            materialHeatMapControl.toggleState = false
            $('.heatMapButton button').removeClass( "mdl-color--red" ).addClass( "mdl-color--cyan" );
            @map.removeLayer(heat)
            if turnCasesLayerOn == true
              @map.addLayer casesLayer
              turnCasesLayerOn = false
  timeToggle: =>
    dateRange = [outFormat(timeScale.brush.extent()[0]), outFormat(timeScale.brush.extent()[1])]
    if map.hasLayer casesLayer 
      updateFeaturesByDate(dateRange)         
    if !materialTimeControl.toggleState
      $("#sliderContainer").toggle()
      $('.timeButton button').removeClass( "mdl-color--cyan" ).addClass( "mdl-color--red" );
      materialTimeControl.toggleState = true
      if @map.hasLayer casesLayer
        @map.removeLayer casesLayer
        turnCasesLayerOn = true
      if @map.hasLayer heat
        @map.removeLayer heat
    else
      materialTimeControl.toggleState = false
      $("#sliderContainer").toggle()
      $('.timeButton button').removeClass( "mdl-color--red" ).addClass( "mdl-color--cyan" );
      if turnCasesLayerOn == true
        @map.addLayer casesLayer
        turnCasesLayerOn = false          
    
  clusterToggle: =>
    if !materialClusterControl.toggleState
      materialClusterControl.toggleState = true
      $('.clusterButton button').removeClass( "mdl-color--cyan" ).addClass( "mdl-color--red" );
      if @map.hasLayer casesLayer
        @map.removeLayer casesLayer
        turnCasesLayerOn = true
      clusters.addTo map
    else
      materialClusterControl.toggleState = false
      $('.clusterButton button').removeClass( "mdl-color--red" ).addClass( "mdl-color--cyan" );
      @map.removeLayer clusters
      if turnCasesLayerOn == true
        @map.addLayer casesLayer
        turnCasesLayerOn = false
  updateFeaturesByDate = (dateRange) ->
    timeFeatures = []
    count = 0
    heatMapCoordsTime = []
    for fCount of casesGeoJSON.features
      count++
      feature = casesGeoJSON.features[fCount]
      fDate = feature.properties.date.substring(0,10)
      console.log fDate + ' >= ' + dateRange[0] + ' and ' + fDate + ' <= ' + dateRange[1]
      if fDate >= dateRange[0] and fDate <= dateRange[1]
        timeFeatures.push feature
        coords = [
          feature.geometry.coordinates[1]
          feature.geometry.coordinates[0]
          5000/casesGeoJSON.features.length#adjust with slider
        ]
        heatMapCoordsTime.push coords
    timeCasesGeoJSON.features = timeFeatures
    
    if materialHeatMapControl.toggleState
        console.log 'heatmapcontrolOn'
        if !map.hasLayer timeHeatMapLayer
          console.log 'FirstHeatmapLayerCoords: ' + heatMapCoordsTime
          timeHeatMapLayer = L.heatLayer(heatMapCoordsTime, radius: 10).addTo(map)
        else
          console.log 'UpdateHeatmapLayerCoords: ' + heatMapCoordsTime
          timeHeatMapLayer.setLatLngs(heatMapCoordsTime)
          timeHeatMapLayer.redraw()
    else    
        if !map.hasLayer timeLayer
              #create time features for clusters, heatmap and cases. Let the visualization toggles control the layers that are visible for time. 
              timeLayer = L.geoJson(timeCasesGeoJSON, 
              onEachFeature: (feature, layer) =>
    #            coords = [
    #              feature.geometry.coordinates[1]
    #              feature.geometry.coordinates[0]
    #              5000/timeCasesGeoJSON.features.length#adjust with slider
    #            ]
    #            heatMapCoordsTime.push coords
                layer.bindPopup "caseID: " + feature.properties.MalariaCaseID + "<br />\n Household Cases: " + feature.properties.numberOfCasesInHousehold + "<br />\n Date: "+feature.properties.date 
                return
              pointToLayer: (feature, latlng) =>
                # household markers with secondary cases
                #clusering as well
                if feature.properties.hasAdditionalPositiveCasesAtIndexHousehold == false
                    L.circleMarker latlng, caseMarkerOptions
                else
                    L.circleMarker latlng, casesMarkerOptions
              ).addTo(map)
        else
          timeLayer.clearLayers()
          timeLayer.addData(timeFeatures) 
    #if heatmap is on:
    
        
  mapFocus: =>
    if @map.scrollWheelZoom.enabled() == false
      @map.scrollWheelZoom.enable()
  
  mapBlur: =>
    if @map.scrollWheelZoom.enabled() == true
      @map.scrollWheelZoom.disable()
        
  snapImage: =>
#    progressBar.showPleaseWait()

    leafletImage @map, (err, canvas) =>
      a = document.createElement('a')
      a.href = canvas.toDataURL('image/jpeg').replace('image/jpeg', 'image/octet-stream')
      a.download = 'coconutMap.jpg'
      a.click()
      @snapshot.innerHTML = ''
      return
    return

  
    
  render: =>
    options = Coconut.router.reportViewOptions
    casesGeoJSON = 
      'type': 'FeatureCollection'
      'features': []
    timeCasesGeoJSON =  
      'type': 'FeatureCollection'
      'features': []
    startDate = options.startDate
    endDate = options.endDate
    Reports.getCases
      startDate: startDate
      endDate: endDate
      success: (results) ->
#        console.log "results: " + JSON.stringify results
        casesGeoJSON.features =  _(results).chain().map (malariaCase) ->
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
#        console.log 'casesGEoJSON: '+JSON.stringify casesGeoJSON
        updateMap casesGeoJSON

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
        #sliderContainer{
            background-color: #393939;
            font-size: 14px;
            font-family: 'Raleway', sans-serif;
            display: none;
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
                <div id = 'sliderContainer'></div>
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
    
    @map = L.map('map',
      center: [
        -5.67, 39.489
      ]
      zoom: 9
      layers: [
        streets
      ]
      zoomControl: false
      attributionControl: false
#      timeDimension: true
#      timeDimensionOptions:
#        timeInterval: timeInterval
#        period: 'PT1H'
      )
    
    @map.lat = -5.67
    @map.lng = 39.489
    @map.zoom = 9
    map = @map
    $.ajax
      url: '../../mapdata/DistrictsWGS84.json'
      dataType: 'json'
      type: 'GET'
      async: false
      success: (data) ->
        console.log 'district data loadeds'
        districtsData = data
        return
    districtsLayer = L.geoJson(districtsData,
      style: adminPolyOptions
      onEachFeature: (feature, layer) ->
        layer.bindPopup 'test'
        return
    ).addTo @map
    $.ajax
      url: '../../mapdata/ShahiasWGS84.json'
      dataType: 'json'
      type: 'GET'
      async: false
      success: (data) ->
        console.log 'district data loadeds'
        shahiasData = data
        return
    shahiasLayer = L.geoJson(shahiasData,
      style: adminPolyOptions
      onEachFeature: (feature, layer) ->
        layer.bindPopup 'test'
        return
    )
    $.ajax
      url: '../../mapdata/VillagesWGS84.json'
      dataType: 'json'
      type: 'GET'
      async: false
      success: (data) ->
        console.log 'district data loadeds'
        villagesData = data
        return
    villagesLayer = L.geoJson(villagesData,
      style: adminPolyOptions
      onEachFeature: (feature, layer) ->
        layer.bindPopup 'test'
        return
    )
    overlays =
      Districts: districtsLayer
      Shahias: shahiasLayer
      Villages: villagesLayer
    materialOptions = 
      fab: true
      miniFab: true
      rippleEffect: true
      toolTips: false
      color: 'cyan'
    materialZoomControl = new (zoomControl)(
      position: 'topright'
      materialOptions: materialOptions).addTo(@map)
    materialHeatMapControl = new (heatMapControl)(
      position: 'topleft'
      materialOptions: materialOptions).addTo(@map)
#    $('.heatMapButton button').attr('disabled')
    materialClusterControl = new (clusterControl)(
      position: 'topleft'
      materialOptions: materialOptions).addTo(@map)
    materialTimeControl = new (timeControl)(
      position: 'topleft'
      materialOptions: materialOptions).addTo(@map)
    console.log 'materialClusterControlToggleState: '+materialClusterControl.toggleState
    materialFullscreen = new (L.materialControl.Fullscreen)(position: 'topright',
      materialOptions: materialOptions).addTo(@map)
    customLayers = L.control.layers(layers, overlays).addTo @map
#
#    legend = L.control(position: 'topleft')
#
#    legend.onAdd = (map) ->
#      div = L.DomUtil.create('div', 'info legend')
#      grades = [
#        0
#        10
#        20
#        50
#        100
#        200
#        500
#        1000
#      ]
#      labels = []
#      # loop through our density intervals and generate a label with a colored square for each interval
#      i = 0
#      while i < grades.length
#        div.innerHTML += 'LEGEND'
#        i++
#      div
#
#    legend.addTo map
#    legend.onAdd = (@map) =>
#      div = L.DomUtil.create('div', 'legend')
#      div.innerHTML 'Legend'
#          categories = [
#            'Single Case'
#            'Multiple Cases'
#          ]
#          i = 0
#          while i < categories.length
#            div.innerHTML += '<i style="background:' + getColor(categories[i]) + '"></i> ' + (if categories[i] then categories[i] + '<br>' else '+')
#            i++
#          div
#
#    legend.addTo @map    
    brushed = ->
      actives = svg.filter((p) ->
        !timeScale.brush.empty()
      )
      extents = actives.map((p) ->
        timeScale.brush.extent()
      )
      endDate = timeScale.brush.extent()[1]
      endFormat = outFormat(endDate)
      startDate = timeScale.brush.extent()[0]
      startFormat = outFormat(startDate)
      dateRange = [startFormat, endFormat]
      dayMoFormat = d3.time.format("%b %d")
      textE.text(dayMoFormat(endDate))
      textW.text(dayMoFormat(startDate))
      if d3.event.sourceEvent
        updateFeaturesByDate(dateRange)
      return
    formatDate = d3.time.format('%b %d')
    # parameters
    margin = 
      top: 50
      right: 50
      bottom: 50
      left: 50
    width = 1000 - (margin.left) - (margin.right)
    height = 137 - (margin.bottom) - (margin.top)
    # scale function
    timeScale = d3.time.scale().domain([
      new Date(startDate)
      new Date(endDate)
    ]).range([
      0
      width
    ]).clamp(true)
    # initial value
    
    startValue = timeScale(new Date(startDate))
    startingValue = new Date(startDate)
    endValue = timeScale(new Date(endDate))
    endingValue = new Date(endDate)
    svg = d3.select('#sliderContainer').append('svg').attr('width', width + margin.left + margin.right).attr('height', height + margin.top + margin.bottom).append('g').attr('transform', 'translate(' + margin.left + ',' + margin.top + ')')
    svg.append('g').attr('class', 'x axis').attr('transform', 'translate(0,' + height / 2 + ')').call(d3.svg.axis().scale(timeScale).orient('bottom').tickFormat((d) ->
      formatDate d
    ).tickSize(0).tickPadding(12).tickValues([
      timeScale.domain()[0]
      timeScale.domain()[1]
    ])).select('.domain').select(->
      console.log this
      @parentNode.appendChild @cloneNode(true)
    ).attr 'class', 'halo'


#    Brush extents
    slider = svg.append('g').attr('class', 'brush').each((d) ->
      d3.select(this).call timeScale.brush = d3.svg.brush().x(timeScale).extent([
        startingValue
        endingValue
      ]).on('brush', brushed)
      return
    ).selectAll('rect').attr('y', 10).attr('height', 16)
    
    _brush = d3.select '.brush'
    resizes = d3.selectAll '.resize'
    resizeE = resizes[0][0]
    resizeE.id = 'resizee'
    resizeW = resizes[0][1]
    resizeW.id = 'resizew'
    textE = d3.select('#resizee').append('text').text(formatDate(endingValue))
    textE.id = 'texte'
    textW = d3.select('#resizew').append('text').text(formatDate(startingValue))
    textW.id = 'textw'
    rects = _brush.selectAll('rect')
    rects3 = rects[0][3]
    outFormat = d3.time.format("%Y-%m-%d")
    dateRange = [outFormat(startingValue), outFormat(endingValue)]
    
    updateMap = (data) =>
#        console.log "data: "+JSON.stringify data
        if data.features.length == 0
#            disable heatmap button else enable it
            heatMapCoords = []
        clusters = L.markerClusterGroup()
        casesLayer = L.geoJson(data, 
          onEachFeature: (feature, layer) =>
            coords = [
              feature.geometry.coordinates[1]
              feature.geometry.coordinates[0]
              5000/data.features.length#adjust with slider
            ]
            
            heatMapCoords.push coords
            layer.bindPopup "caseID: " + feature.properties.MalariaCaseID + "<br />\n Household Cases: " + feature.properties.numberOfCasesInHousehold + "<br />\n Date: "+feature.properties.date 
            clusters.addLayer layer
            return
          pointToLayer: (feature, latlng) =>
            # household markers with secondary cases
            #clusering as well
            if feature.properties.hasAdditionalPositiveCasesAtIndexHousehold == false
                L.circleMarker latlng, caseMarkerOptions
            else
                L.circleMarker latlng, casesMarkerOptions
          ).addTo(@map)
        if heatMapCoords.length == 0
          $('.heatMapButton button').toggleClass 'mdl-button--disabled', true
          $('.timeButton button').toggleClass 'mdl-button--disabled', true
        else
          $('.heatMapButton button').toggleClass 'mdl-button--disabled', false
          $('.timeButton button').toggleClass 'mdl-button--disabled', false
        if data.features.length > 0
          console.log('multiCase')
          customLayers.addOverlay casesLayer, 'Cases'
        
    return
   
module.exports = MapView
    