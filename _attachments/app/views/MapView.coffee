_ = require "underscore"
$ = require "jquery"
Backbone = require "backbone"
Backbone.$  = $
d3 = require 'd3'

require 'mapbox.js'
require 'leaflet'
materialControl = require 'leaflet-material-controls'
#global.L = require 'leaflet'
Reports = require '../models/Reports'
leafletImage = require 'leaflet-image'
Case = require '../models/Case'
HTMLHelpers = require '../HTMLHelpers'

class MapView extends Backbone.View
  map = undefined
  layerTollBooth = undefined
  clustersLayer = undefined
  clustersTimeLayer = undefined
  timeFeatures = []
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
#  admin0PolyOptions =
#    color: 'red'
#    weight: 4
#    opacity: 1
#    fillOpacity: 0
  admin1PolyOptions =
    color: 'red'
    weight: 3
    opacity: 1
    fillOpacity: 0
  admin2PolyOptions =
    color: 'blue'
    weight: 1.5
    opacity: 1
    fillOpacity: 0
  admin3PolyOptions =
    color: 'green'
    weight: 0.5
    opacity: 1
    fillOpacity: 0
  heatMapCoords = [] 
  heatMapCoordsTime = []
  heatMapOn = false
  heatLayer = undefined
  heatTimeLayer = undefined
  startDate = undefined
  endDate = undefined
  overlays = {}
  materialHeatMapControl = undefined
  materialClusterControl = undefined
  materialTimeControl = undefined
  materialLayersControl = undefined
  casesLayer = undefined
  casesGeoJSON = undefined
  turnCasesLayerOn = false
  timeCasesGeoJSON = undefined
  districtsData = undefined
  shahiasData = undefined
  villagesData = undefined
  textE = undefined
  textW = undefined
  casesTimeLayer = undefined
  timeScale = undefined
  formatDate = d3.time.format('%b %d')
  outFormat = d3.time.format("%Y-%m-%d")
  legend = undefined
  svg = undefined
  svgXAxis = undefined
  svgMargin = undefined
  svgHeight = undefined
  svgWidth = undefined
  winWidth = undefined
  el: '#content'

  events:
    "click button#pembaToggle": "pembaClick"
    "click button#ungujaToggle": "ungujaClick"
    "click .heatMapButton, #heatMapToggle": "heatMapToggle"
    "click .timeButton": "timeToggle"
    "click .clusterButton": "clusterToggle"
#    "click .layersButton": "layersToggle"
    "click .imageButton": "snapImage"
    "focus #map": "mapFocus"
    "blur #map": "mapBlur"
#    "overlayadd #map": "mapOnLayerAdd"
    "click #snapImage": "snapImage"
    "click button.caseBtn": "showCaseDialog"
    "click button#closeDialog": "closeDialog"
  
  showCaseDialog: (e) ->
    caseID = $(e.target).parent().attr('id') || $(e.target).attr('id')
    Coconut.case = new Case
      caseID: caseID
    Coconut.case.fetch
      success: ->
        Case.createCaseView
          case: Coconut.case
          success: ->
            $('#caseDialog').html(Coconut.caseview)
            if (Env.is_chrome)
               caseDialog.showModal()
            else
               caseDialog.show()

  closeDialog: () ->
    caseDialog.close()
      
  pembaClick: (event)=>
        $('#pembaToggle').toggleClass 'mdl-button--raised', true
        $('#ungujaToggle').toggleClass 'mdl-button--raised', false
        map.setView([-5.187, 39.746], 10, {animate:true})

  ungujaClick: (event)=>
        $('#pembaToggle').toggleClass 'mdl-button--raised', false
        $('#ungujaToggle').toggleClass 'mdl-button--raised', true
        map.setView([-6.1, 39.348], 10, {animate:true})
  
  heatMapToggle: =>
    if heatMapCoords.length>0
        console.log 'layerTollBooth.heatLayerOn: ' + layerTollBooth.heatLayerOn
        if !layerTollBooth.heatLayerOn
            console.log('heatMaPToggle heatLayerOff')
            layerTollBooth.setHeatLayerStatus true
            layerTollBooth.handleActiveState $('.heatMapButton button'), 'on'
            heatLayer = L.heatLayer(heatMapCoords, radius: 10) 
            heatTimeLayer = L.heatLayer(heatMapCoordsTime, radius: 10) 
            layerTollBooth.handleHeatMap(map, heatLayer, heatTimeLayer, casesLayer, casesTimeLayer, )
        else
            console.log('heatMapToggle heatLayerOn')
            layerTollBooth.setHeatLayerStatus false
            layerTollBooth.handleActiveState $('.heatMapButton button'), 'off'
            if map.hasLayer casesTimeLayer
                casesTimeLayer.clearLayers()
                casesTimeLayer.addData(timeFeatures) 
            layerTollBooth.handleHeatMap(map, heatLayer, heatTimeLayer, casesLayer, casesTimeLayer)
  clusterToggle: =>
    if !layerTollBooth.clustersOn
      layerTollBooth.setClustersStatus true
      layerTollBooth.handleActiveState $('.clusterButton button'), 'on'
      layerTollBooth.handleClusters(map, clustersLayer, clustersTimeLayer, casesLayer, casesTimeLayer)
      clustersLayer.addTo map
    else
      layerTollBooth.setClustersStatus false
      layerTollBooth.handleActiveState $('.clusterButton button'), 'off'
      layerTollBooth.handleClusters(map, clustersLayer, clustersTimeLayer, casesLayer, casesTimeLayer)
      map.removeLayer clustersLayer
#  layersToggle: =>
#    if !legend._map
#      console.log 'not in map'
#      legend.addTo map
#    else
#      console.log 'in map'
#      legend.removeFrom map
  
  timeToggle: =>
    dateRange = [outFormat(timeScale.brush.extent()[0]), outFormat(timeScale.brush.extent()[1])]
#    if map.hasLayer casesLayer 
#      updateFeaturesByDate(dateRange)
#    if map.hasLayer heatLayer
#      updateFeaturesByDate(dateRange)
    updateFeaturesByDate(dateRange)
    if !layerTollBooth.timeOn
      $("#sliderControls").toggle()
      layerTollBooth.handleActiveState $('.timeButton button'), 'on'
      layerTollBooth.setTimeStatus true
      layerTollBooth.handleTime(map, heatLayer, heatTimeLayer, casesLayer, casesTimeLayer)
#      if map.hasLayer casesLayer
#        map.removeLayer casesLayer
#        turnCasesLayerOn = true
#      if map.hasLayer heatLayer
#        map.removeLayer heatLayer
    else
      layerTollBooth.setTimeStatus false
      $("#sliderControls").toggle()
      layerTollBooth.handleActiveState $('.timeButton button'), 'off'
      console.log('timeToggle casesTimeLayer: ' + casesTimeLayer)
      layerTollBooth.handleTime(map, heatLayer, heatTimeLayer, casesLayer, casesTimeLayer)
#      if turnCasesLayerOn == true
#        map.addLayer casesLayer
#        turnCasesLayerOn = false          
    
  setUpTypeAheadData = (geojson) -> 
    typeAheadAdminNames = {}
    typeAheadAdminNames.islands = ['Pemba', 'Unguja']
    districts = []
    shehias = []
    villages = []
    for fCount of geojson.features
      feature = geojson.features[fCount]
      district = feature.properties.District_N
      districts.indexOf(district)
      if districts.indexOf(district) == -1
        districts.push district    
      shehia = feature.properties.Ward_Name
      if shehias.indexOf(shehia) == -1
        shehias.push shehia 
      village = feature.properties.Vil_Mtaa_N
      if villages.indexOf(village) == -1
        villages.push village
      else
        villages.push village + ': ' + shehia
    
    typeAheadAdminNames.districts = districts
    typeAheadAdminNames.shehias = shehias
    typeAheadAdminNames.villages = villages
    
#    console.log 'typeaheadnames districts: ' + JSON.stringify typeAheadAdminNames.districts
#    console.log 'typeaheadnames Shehias: ' + JSON.stringify typeAheadAdminNames.shehias
#    console.log 'typeaheadnames Villages: ' + JSON.stringify typeAheadAdminNames.villages
    return typeAheadAdminNames 
        
  updateFeaturesByDate = (dateRange) ->
#    console.log 'dateRange: ' + dateRange
    timeFeatures = []
    count = 0
    heatMapCoordsTime = []
    for fCount of casesGeoJSON.features
      count++
      feature = casesGeoJSON.features[fCount]
      fDate = feature.properties.date.substring(0,10)
      if fDate >= dateRange[0] and fDate <= dateRange[1]
        timeFeatures.push feature
        coords = [
          feature.geometry.coordinates[1]
          feature.geometry.coordinates[0]
          15000/casesGeoJSON.features.length   #adjust with slider
        ]
        heatMapCoordsTime.push coords
    
    timeCasesGeoJSON.features = timeFeatures
    if layerTollBooth.heatLayerOn
#        console.log 'heatmapcontrolOn'
        if !map.hasLayer heatTimeLayer
#          console.log 'FirstHeatmapLayerCoords: ' + heatMapCoordsTime
          heatTimeLayer = L.heatLayer(heatMapCoordsTime, radius: 10).addTo(map)
          heatTimeLayer.redraw()
          casesTimeLayer.clearLayers()
          casesTimeLayer.addData(timeFeatures) 
        else
#          console.log 'UpdateHeatmapLayerCoords: ' + heatMapCoordsTime
          heatTimeLayer.setLatLngs(heatMapCoordsTime)
          heatTimeLayer.redraw()
          casesTimeLayer.clearLayers()
          casesTimeLayer.addData(timeFeatures) 
    else    
        if !map.hasLayer casesTimeLayer
              #create time features for clusters, heatmap and cases. Let the visualization toggles control the layers that are visible for time. 
              clustersTimeLayer = L.markerClusterGroup()
              casesTimeLayer = L.geoJson(timeCasesGeoJSON, 
              onEachFeature: (feature, layer) =>
    #            coords = [
    #              feature.geometry.coordinates[1]
    #              feature.geometry.coordinates[0]
    #              5000/timeCasesGeoJSON.features.length#adjust with slider
    #            ]
    #            heatMapCoordsTime.push coords
                layer.bindPopup "caseID: " + feature.properties.MalariaCaseID + "<br />\n Household Cases: " + feature.properties.numberOfCasesInHousehold + "<br />\n Date: "+feature.properties.date 
                clustersTimeLayer.addLayer layer
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
          casesTimeLayer.clearLayers()
          casesTimeLayer.addData(timeFeatures) 
    #if heatmap is on:
    
        
  mapFocus: =>
    if map.scrollWheelZoom.enabled() == false
      map.scrollWheelZoom.enable()
  
  mapBlur: =>
    if map.scrollWheelZoom.enabled() == true
      map.scrollWheelZoom.disable()
  
  mapOnLayerAdd: =>
    console.log 'mapOnLayerAdd'
    
  snapImage: =>
#    progressBar.showPleaseWait()
    console.log('snapImage')
    leafletImage map, (err, canvas) =>
#      TODO - add and subtract analysis spinner when file starts and finsihes downloading
#      $('#analysis-spinner').show()
#      http://stackoverflow.com/questions/1106377/detect-when-browser-receives-file-download
      a = document.createElement('a')
      a.href = canvas.toDataURL('image/jpeg').replace('image/jpeg', 'image/octet-stream')
      a.download = 'coconutMap.jpg'
      a.click()
      #@snapshot.innerHTML = ''
      return
    return
    
  render: =>
    console.log 'render fired'
    $('#analysis-spinner').show()
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
        console.log 'success'
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
        console.log 'casesGeoJSON.features: ' + casesGeoJSON.features.length
#        LayerTollBooth = ->
#          @CasesLoaded = false
#          return
        layerTollBooth = new LayerTollBooth(map, casesLayer)
        if casesGeoJSON.features.length > 0
            console.log('set true: ')
            layerTollBooth.setCasesStatus true
            layerTollBooth.enableDisableButtons 'enable'
        else
            console.log('set false')
            layerTollBooth.setCasesStatus false
            layerTollBooth.enableDisableButtons 'disable' 
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
        #sliderControls{
            display: flex;
            align-items: center;
            justify-content: center;
            display: none; 
        }
        #playDiv{
            padding-top: 25px;
            float: left;
            padding-left: 25px;
        }
        #sliderContainer{
            background-color: #393939;
            height: 90px;
            font-size: 14px;
            font-family: 'Raleway', sans-serif;
        }
        .theSVG{
            padding-left: 7px;
        }
        .demo-card-square.mdl-card {
           width: 320px;
           height: 320px;
        }
        .demo-card-square > .mdl-card__title {
           color: #fff;
           background: url('../assets/demos/dog.png') bottom right 15% no-repeat #46B6AC;
        }
        button.caseBtn {font-size: 1.0em}
        </style>
        <dialog id='caseDialog'></dialog>
        <div id='dateSelector'></div>
        <div class='mdl-grid'>
            <div class='mdl-cell mdl-cell--12-col'>
                    <div style='display: inline-block'>
                        <label for='pembaToggle'>Switch to: </label>
                        <button id='pembaToggle' class='mdl-button mdl-js-button mdl-button--primary mdl-js-ripple-effect mdl-button--accent'>Pemba</button>
                        <label for='ungujaToggle'>or</label>
                        <button id='ungujaToggle' class='mdl-button mdl-js-button mdl-button--primary mdl-js-ripple-effect mdl-button--accent'>Unguja</button>
                        
                        <!--<form style='display: inline-flex'>
                          <div class='mui-select'>
                            <select style='padding-right:20px'>
                              <option value='island'>Islands</option>
                              <option value='district'>Districts</option>
                              <option value='shehias'>Shahias</option>
                              <option value='villages'>Villages</option>
                            </select>
                          </div>
                          <div class='mui-textfield' style='padding-left:20px'>
                            <input type='text' class='typeahead' placeholder='Input 1'>
                          </div>
                        </form>-->
                    </div>
                </div>
            <div class='mdl-cell mdl-cell--1-col'></div>
        </div>
        <div class='mdl-grid' style='height:80%'>                
            <div class='mdl-cell mdl-cell--12-col' style='height:100%'>
                <div style='width:100%;height:100%;position: relative;' id='map'></div>
            </div>
        </div>
        <div class='mdl-grid' style='height:20%'>
            <div class='mdl-cell mdl-cell--12-col' id='sliderCell' style='height:20%'>
                <div id='sliderControls'>
                    <div id='playDiv'>
                        <button name='play' id='play'>Play</button>
                    </div>
                    <div id = 'sliderContainer'>
                    </div>
                </div>
            </div>
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
    layerTollBooth = new LayerTollBooth
    map = L.map('map',
      center: [
        -5.67, 39.489
      ]
      zoom: 9
      layers: [
        streets
      ]
      zoomControl: false
      attributionControl: false
      )
    map.lat = -5.67
    map.lng = 39.489
    map.zoom = 9
    map.scrollWheelZoom.disable()
    

 #   typeAheadNames = setUpTypeAheadData(villagesData)
    
    
    
#    map.on 'overlayadd', (a) ->
#      console.log('bringToFront')
#      map.eachLayer (layer) ->
##        console.log(JSON.stringify(layer))
#        return
##      casesLayer.bringToFront
#      return
    materialOptions = 
      fab: true
      miniFab: true
      rippleEffect: true
      toolTips: false
      color: 'cyan'
    materialZoomControl = new (zoomControl)(
      position: 'topright'
      materialOptions: materialOptions).addTo(map)
    materialHeatMapControl = new (heatMapControl)(
      position: 'topleft'
      materialOptions: materialOptions).addTo(map)
#    $('.heatMapButton button').attr('disabled')
    materialClusterControl = new (clusterControl)(
      position: 'topleft'
      materialOptions: materialOptions).addTo(map)
    materialTimeControl = new (timeControl)(
      position: 'topleft'
      materialOptions: materialOptions).addTo(map)
    materialFullscreen = new (L.materialControl.Fullscreen)(
      position: 'topright'
      pseudoFullscreen: false
      materialOptions: materialOptions).addTo(map)
#    var materialLayerControl = new L.materialControl.Layers(layers, overlays, {position: 'bottomright', materialOptions: materialOptions}).addTo(map);

    materialLayersControl = new (myLayersControl)(layers, overlays,
      position: 'topright'
      materialOptions: materialOptions).addTo(map)
    
    materialImageControl = new (imageControl)(
      position: 'topright'
      materialOptions: materialOptions).addTo(map)
    layerTollBooth.enableDisableButtons 'disable'
    L.control.scale(position: 'bottomright').addTo map
    
    Coconut.database.get 'DistrictsWGS84'
    .catch (error) -> console.error error
    .then (data) ->
      districtsData = data
      console.log('districtsData: '+districtsData)
      districtsLayer = L.geoJson(districtsData,
        style: admin1PolyOptions
        onEachFeature: (feature, layer) ->
          layer.bindPopup 'District: ' + feature.properties.District_N
          return
      ).addTo map
      materialLayersControl.addOverlay(districtsLayer, 'Districts')
    
    Coconut.database.get 'ShahiasWGS84'
    .catch (error) -> console.error error
    .then (data) ->
      shahiasData = data
      shahiasLayer = L.geoJson(shahiasData,
        style: admin2PolyOptions
        onEachFeature: (feature, layer) ->
          layer.bindPopup 'Shehia: ' + feature.properties.Shehia
          return
      )
      materialLayersControl.addOverlay(shahiasLayer, 'Shahias')
    
    Coconut.database.get 'VillagesWGS84'
    .catch (error) -> console.error error
    .then ( data) ->
      villagesData = data
      villagesLayer = L.geoJson(villagesData,
        style: admin3PolyOptions
        onEachFeature: (feature, layer) ->
          #console.log 'villages feature.properties' + feature.properties.Vil_Mtaa_N
          layer.bindPopup 'Village: ' + feature.properties.Vil_Mtaa_N
          return
      )
      materialLayersControl.addOverlay(villagesLayer, 'Villages')

#    customLayers = L.control.layers(layers, overlays).addTo map
#
#    legend = L.control(position: 'topright')
#
#    legend.onAdd = (map) ->
#      div = L.DomUtil.create('div', '<div class="demo-card-square mdl-card mdl-shadow--2dp">')
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
#      div.innerHTML += '<div class="mdl-card__title mdl-card--expand">
#    <h2 class="mdl-card__title-text">Update</h2>
#  </div>
#  <div class="mdl-card__supporting-text">
#    Lorem ipsum dolor sit amet, consectetur adipiscing elit.
#    Aenan convallis.
#  </div>
#  <div class="mdl-card__actions mdl-card--border">
#    <a class="mdl-button mdl-button--colored mdl-js-button mdl-js-ripple-effect">
#      View Updates
#    </a>
#  </div>'
#        
#      i = 0
#      while i < grades.length
#        i++
#      div

    
#    legend.onAdd = (map) =>
#      console.log 'legend.onAdd'
#          categories = [
#            'Single Case'
#            'Multiple Cases'
#          ]
#          i = 0
#          while i < categories.length
#            div.innerHTML += '<i style="background:' + getColor(categories[i]) + '"></i> ' + (if categories[i] then categories[i] + '<br>' else '+')
#            i++
#          div  

    brushed = ->
#      console.log('brushed')
      actives = svg.filter((p) ->
        !timeScale.brush.empty()
      )
      extents = actives.map((p) ->
        timeScale.brush.extent()
      )
#      console.log 'extents: ' + extents
      brushEndDate = timeScale.brush.extent()[1]
      endFormat = outFormat(brushEndDate)
      brushStartDate = timeScale.brush.extent()[0]
      startFormat = outFormat(brushStartDate)
      dateRange = [startFormat, endFormat]
      dayMoFormat = d3.time.format("%b %d")
      textE.text(dayMoFormat(brushEndDate))
      textW.text(dayMoFormat(brushStartDate))
      if d3.event.sourceEvent
        updateFeaturesByDate(dateRange)
      return
    
    # initial value
    
    resize = ->
      console.log 'resize'
      render()
#      svgWidth = parseInt(d3.select('#sliderContainer').style('svgWidth'), 10);
#      svgWidth = svgWidth - svgMargin.left - svgMargin.right;
#      d3.select('.xaxis').attr('svgWidth', svgWidth + svgMargin.left + svgMargin.right)    
      return

    d3.select(window).on 'resize', resize
    
    render = ->
        console.log 'render'
        updateDimensions($('#sliderCell').width());
        
    
    updateDimensions = (winWidth) ->
        console.log 'winWidth: ' + winWidth
        svgMargin = 
          top: 20
          right: 50
          bottom: 20
          left: 50
        svgWidth = winWidth - (svgMargin.left) - (svgMargin.right) - 100
        svgHeight = 80 - (svgMargin.bottom) - (svgMargin.top)
        
        timeScale = d3.time.scale().domain([
          new Date(startDate)
          new Date(endDate)
        ]).range([
          0
          svgWidth
        ]).clamp(true)
        startValue = timeScale(new Date(startDate))
        startingValue = new Date(startDate)
        endValue = timeScale(new Date(endDate))
        endingValue = new Date(endDate)
        console.log('svgWidth & svgHeight: ' + svgWidth + ' & ' + svgHeight)
        d3.select('.theSVG').attr('width', svgWidth + svgMargin.left + svgMargin.right).attr('height', svgHeight + svgMargin.top + svgMargin.bottom)
        d3.select('.svgG').attr('transform', 'translate(' + svgMargin.left + ',' + svgMargin.top + ')')
        d3.select('.xaxis').attr('width',  svgWidth + svgMargin.left + svgMargin.right).attr('transform', 'translate(0,' + svgHeight / 2 + ')').call(d3.svg.axis().scale(timeScale).orient('bottom').tickFormat((d) ->
          formatDate d
        ).tickSize(0).tickPadding(12).tickValues([
          timeScale.domain()[0]
          timeScale.domain()[1]
        ]))
        d3.select('.brush').each((d) ->
          d3.select(this).call timeScale.brush = d3.svg.brush().x(timeScale).extent([
            startingValue
            endingValue
          ]).on('brush', brushed)
          return
        ).selectAll('rect').attr('y', 10).attr('height', 16)
        d3.select('.texte').text(formatDate(endingValue))
        d3.select('.textw').text(formatDate(startingValue))
        outFormat = d3.time.format("%Y-%m-%d")
        dateRange = [outFormat(startingValue), outFormat(endingValue)]
    
    running = false
    timer = undefined
    $('#play').on 'click', ->
      duration = 300
      maxstep = 201
      minstep = 200
      console.log('running: ' + running)
      if running == true
        $('#play').html 'Play'
        running = false
        clearInterval timer
      else if running == false
        $('#play').html 'Pause'
#        sliderValue = $('.theSVG').val()
        playEndTime = timeScale.brush.extent()[1]
#      console.log 'playEndTime1: ' + playEndTime
#      console.log 'playEndTime1: ' + playEndTime
        playStartTime = timeScale.brush.extent()[0]
        console.log('playEndTime: '+playEndTime)
        console.log('playStartTime: '+playStartTime)
#        console.log('sliderValue: '+sliderValue)
        timer = setInterval((->
#          if sliderValue < maxstep
#            sliderValue++
#            $('.theSVG').val sliderValue
#            $('#range').html sliderValue
#          $('.theSVG').val sliderValue
          update()
          return
        ), duration)
        running = true
      return

    update = ->
      playEndTime = timeScale.brush.extent()[1]
#      console.log 'playEndTime1: ' + playEndTime
      playEndTime.setDate playEndTime.getDate() + 1
#      console.log 'playEndTime1: ' + playEndTime
      playStartTime = timeScale.brush.extent()[0]
      playStartTime.setDate playStartTime.getDate() + 1
#      handle.attr 'transform', 'translate(' + timeScale(playStartTime) + ',0)' 
      d3.select('resizew').attr 'transform', 'translate(' + timeScale(playStartTime) + ',0)'
#      handle.select('text').text formatDate(playStartTime)
      d3.select('textw').text formatDate(playStartTime)
      
#      console.log 'playStartTime: ' + formatDate(playStartTime)
      
      d3.select('.brush').transition().call(timeScale.brush.extent [
        playStartTime
        playEndTime
      ]).call timeScale.brush.event
      
      playDateRange = [
        outFormat(playStartTime)
        outFormat(playEndTime)
      ]
      updateFeaturesByDate playDateRange
      return
    
    svg = d3.select('#sliderContainer').append('svg').attr('class', 'theSVG').append('g').attr('class','svgG')
    svg.append('g').attr('class', 'xaxis').select('.domain').select(->
        @parentNode.appendChild @cloneNode(true)
    ).attr 'class', 'halo'
#    Brush extents
    slider = svg.append('g').attr('class', 'brush')
    render()
    
    _brush = d3.select '.brush'
    resizes = d3.selectAll '.resize'
    resizeE = resizes[0][0]
    resizeE.id = 'resizee'
    resizeW = resizes[0][1]
    resizeW.id = 'resizew'
    textE = d3.select('#resizee').append('text').attr('class', 'texte')
    textE.id = 'texte'
    textW = d3.select('#resizew').append('text').attr('class', 'textw').attr('transform', 'translate(-48,0)')
    textW.id = 'textw'
    rectE = d3.select('#resizee rect').attr('class', 'recte').style('visibility','visible').attr('width', 3)
    rectW = d3.select('#resizew rect').attr('class', 'rectw').style('visibility','visible').attr('width', 3)
    rects = _brush.selectAll('rect')
    rects3 = rects[0][3]
    
    updateMap = (data) =>
#        console.log "data: "+JSON.stringify data
        if data.features.length == 0
#            disable heatmap button else enable it
            heatMapCoords = []
        clustersLayer = L.markerClusterGroup()
        casesLayer = L.geoJson(data, 
          onEachFeature: (feature, layer) =>
            coords = [
              feature.geometry.coordinates[1]
              feature.geometry.coordinates[0]
              5000/data.features.length#adjust with slider
            ]
            
            heatMapCoords.push coords
            caselink = "
              <button class='mdl-button mdl-js-button mdl-button--primary caseBtn' id='#{feature.properties.MalariaCaseID}'>
              #{feature.properties.MalariaCaseID}</button>
            "
            layer.bindPopup "caseID: #{caselink} <br />\n Household Cases: " + feature.properties.numberOfCasesInHousehold + "<br />\n Date: "+feature.properties.date 
            clustersLayer.addLayer layer
            return
          pointToLayer: (feature, latlng) =>
            # household markers with secondary cases
            #clusering as well
            if feature.properties.hasAdditionalPositiveCasesAtIndexHousehold == false
                L.circleMarker latlng, caseMarkerOptions
            else
                L.circleMarker latlng, casesMarkerOptions
          ).addTo(map)
#        if heatMapCoords.length == 0
#          $('.heatMapButton button').toggleClass 'mdl-button--disabled', true
#          $('.clusterButton button').toggleClass 'mdl-button--disabled', true
#          $('.timeButton button').toggleClass 'mdl-button--disabled', true
#        else
#          $('.heatMapButton button').toggleClass 'mdl-button--disabled', false
#          $('.clusterButton button').toggleClass 'mdl-button--disabled', false
#          $('.timeButton button').toggleClass 'mdl-button--disabled', false
        
        casesTimeLayer = L.geoJson(data, 
          onEachFeature: (feature, layer) =>
            
            layer.bindPopup "caseID: " + feature.properties.MalariaCaseID + "<br />\n Household Cases: " + feature.properties.numberOfCasesInHousehold + "<br />\n Date: "+feature.properties.date,
                closeButton: true
            #clustersLayer.addLayer layer
            return
          pointToLayer: (feature, latlng) =>
            # household markers with secondary cases
            #clusering as well
            if feature.properties.hasAdditionalPositiveCasesAtIndexHousehold == false
                L.circleMarker latlng, caseMarkerOptions
            else
                L.circleMarker latlng, casesMarkerOptions
          )
        if data.features.length > 0
#          console.log('multiCase')
          materialLayersControl.addOverlay casesLayer, 'Cases'

        $('#analysis-spinner').hide()
        
    return
   
module.exports = MapView
    