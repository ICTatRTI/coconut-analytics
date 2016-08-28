_ = require "underscore"
$ = require "jquery"
Backbone = require "backbone"
Backbone.$  = $
d3 = require 'd3'


map = undefined
casesLayer = undefined
casesTimeLayer = undefined
layerTollBooth = undefined
legend = undefined

singleCaseStyle = 
    radius: 4
    fillColor: '#FFA000'
    color: '#000'
    weight: 0.5
    opacity: 1
    fillOpacity: 0.8
multiCaseStyle = 
    radius: 6
    fillColor: '#D32F2F'
    color: '#000'
    weight: 0.5
    opacity: 1
    fillOpacity: 0.8 
noTravelCaseStyle = 
    radius: 4
    fillColor: '#303F9F'
    color: '#000'
    weight: 0.5
    opacity: 1
    fillOpacity: 0.8 
travelCaseStyle = 
    radius: 6
    fillColor: '#CDDC39'
    color: '#D32F2F'
    weight: 0.5
    opacity: 1
    fillOpacity: 0.8 
llinLTCaseStyle = 
    radius: 6
    fillColor: '#512DA8'
    color: '#FFA000'
    weight: 0.5
    opacity: 1
    fillOpacity: 0.8
llinGTCaseStyle = 
    radius: 4
    fillColor: '#FF4081'
    color: '#000'
    weight: 0.5
    opacity: 1
    fillOpacity: 0.8

#Style = (feature) ->
#  {
#    radius: getRadius(feature.properties[activeMeasure]),
#    fillColor: 'blue'
#    color: '#000'
#    weight: 1
#    opacity: 1
#    fillOpacity: 0.8
#  }
getRadius = (d) ->
  #TODO: Create the marker classes here for each
  radius = ''
  radius = 4
  if radius > 0
    radius
  else
    6
   
setUpLegend = () ->
    console.log "SetUpLegendCaseStyle: " + caseStyle
    
    theDiv = L.DomUtil.get('mapLegend')
    theDiv.innerHTML = ""
    if caseStyle == 'numberCases'
        theDiv.innerHTML += '<i class="smallCircle" style="background:#FFA000; border: 1px solid #000"></i><div class="legendLable">Single Case</div><br>'
        theDiv.innerHTML += '<i class="largeCircle" style="background:#D32F2F; border: 1px solid #000"></i><div class="legendLable">Multiple Cases</div>'
    if caseStyle == 'travelCases'
        theDiv.innerHTML += '<i class="smallCircle" style="background:#303F9F; border: 1px solid #000"></i><div class="legendLable">No Travel</div><br>'
        theDiv.innerHTML += '<i class="largeCircle" style="background:#CDDC39; border: 1px solid #D32F2F"></i><div class="legendLable">Recent Travel</div>'
    if caseStyle == 'llinCases'
        theDiv.innerHTML += '<i class="largeCircle" style="background:#512DA8; border: 1px solid #FFA000"></i><div class="legendLable">LLIN < Sleeping Spaces</div><br>'
        theDiv.innerHTML += '<i class="smallCircle" style="background:#FF4081; border: 1px solid #000"></i><div class="legendLable">LLIN >= Sleeping Spaces</div>'
    #    while i < categories.length
    #        $("#mapLegend").innerHTML += '<i class="caseCircle" style="background:' + getColor(categories[i]) + '"></i> ' + (if categories[i] then categories[i] + '<br>' else '+')
      

getColor = (d) ->
#  TODO: Create the marker classes here for each
  console.log('d: ' + d)
    


setCaseStyle = (styleType, feature) ->
    console.log(styleType)
    if styleType == 'travelCases'
      if feature.feature.properties.RecentTravel == 'No'
        feature.setStyle
          fillColor: '#303F9F'
          color: '#000'
        feature.setRadius 4
      else
        feature.setStyle
          fillColor: '#CDDC39'
          color: '#D32F2F'
        feature.setRadius 6
    else if styleType == 'numberCases'
      if feature.feature.properties.numberOfCasesInHousehold == 0
        feature.setStyle
          fillColor: '#FFA000'
          color: '#000'
        feature.setRadius 4
      else
        feature.setStyle
          fillColor: '#D32F2F'
          color: '#000'
        feature.setRadius 6
    else if styleType == 'llinCases'
      if feature.feature.properties.NumberofLLIN < feature.feature.properties.SleepingSpaces
        feature.setStyle
          fillColor: '#512DA8'
          color: '#FFA000'
        feature.setRadius 6 
      else
        feature.setStyle
          fillColor: '#FF4081'
          color: '#000'
        feature.setRadius 4  
        
getCaseStyle = (feature) -> 
    if caseStyle == 'travelCases'
      if feature.properties.RecentTravel == 'No'
        return noTravelCaseStyle
      else
        return travelCaseStyle
    else if caseStyle == 'numberCases'
      if feature.properties.numberOfCasesInHousehold == 0
        return singleCaseStyle
      else
        return multiCaseStyle
    else if caseStyle == 'llinCases'
      if feature.properties.NumberofLLIN < feature.properties.SleepingSpaces
        return llinLTCaseStyle
      else
        return llinGTCaseStyle
window.addEventListener 'caseStyleChange', ((e) ->
  styleType = e.detail.caseType
  setUpLegend()
  casesLayer.eachLayer (layer) ->
    setCaseStyle(styleType, layer)
  if typeof casesTimeLayer != 'undefined'
    casesTimeLayer.eachLayer (layer) ->
        setCaseStyle(styleType, layer)
  return
), false
wasFullScreen = false
window.addEventListener 'fullScreenChange', ((e) ->
  screenState = e.detail.screenState
  if screenState == "Fullscreen" and layerTollBooth.timeOn
    wasFullScreen = true
    $(".timeButton").click()
  else if screenState == "Screen" and wasFullScreen == true
    wasFullScreen = false
    $(".timeButton").click()
  
  return
), false

window.addEventListener 'toggleLegend', ((e) ->
  toState = e.detail.toState
  if toState == "on"
    console.dir("legend.getContainer().hidden: " + legend._map)
    if !legend._map
        legend.addTo map
        setUpLegend()
  else if toState == "off"
    console.dir("legend.getContainer().hidden: " + legend._map)
    legend.removeFrom map
  
  return
), false

districtsLabelsLayerGroup = "undefined"
shehiasLabelsLayerGroup = "undefined"
villagesLabelsLayerGroup = "undefined"
window.addEventListener 'labelsOnOff', ((e) ->
  layer = e.detail.layer
  onOff = e.detail.onOff
  if layer == "Districts"
      if onOff == "on" then districtsLabelsLayerGroup.addTo(map) else map.removeLayer(districtsLabelsLayerGroup)      
  else if layer == "Shehias"
      if onOff == "on" then shehiasLabelsLayerGroup.addTo(map) else map.removeLayer(shehiasLabelsLayerGroup)      
  else if layer == "Villages"
      if onOff == "on" then villagesLabelsLayerGroup.addTo(map) else map.removeLayer(villagesLabelsLayerGroup)
                                                
  return
), false

require 'mapbox.js'
require 'leaflet'
materialControl = require 'leaflet-material-controls'
#global.L = require 'leaflet'
Reports = require '../models/Reports'
leafletImage = require 'leaflet-image'
Case = require '../models/Case'
HTMLHelpers = require '../HTMLHelpers'
Dialog = require './Dialog'

class MapView extends Backbone.View
  clustersLayer = undefined
  clustersTimeLayer = undefined
  timeFeatures = []

#  admin0PolyOptions =
#    color: 'red'
#    weight: 4
#    opacity: 1
#    fillOpacity: 0
  admin1PolyOptions =
    color: '#03A9F4 '
    weight: 2.5
    opacity: 1
    fillOpacity: 0
  admin2PolyOptions =
    color: '#8BC34A'
    weight: 1.5
    opacity: 1
    fillOpacity: 0
  admin3PolyOptions =
    color: '#FF4081'
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
  queriedLayers = {}
  materialHeatMapControl = undefined
  materialClusterControl = undefined
  materialTimeControl = undefined
  casesGeoJSON = undefined
  turnCasesLayerOn = false
  timeCasesGeoJSON = undefined
  districtsData = undefined
  shehiasData = undefined
  villagesData = undefined
  textE = undefined
  textW = undefined
  timeScale = undefined
  formatDate = d3.time.format('%b %d')
  outFormat = d3.time.format("%Y-%m-%d")
  svg = undefined
  svgXAxis = undefined
  svgMargin = undefined
  svgHeight = undefined
  svgWidth = undefined
  winWidth = undefined
  timer = undefined    
  running = false
  materialLayersControl = undefined
  districtsLabelsLayerGroup = L.layerGroup()
  shehiasLabelsLayerGroup = L.layerGroup()
  villagesLabelsLayerGroup = L.layerGroup()
  el: '#content'

  events:
    "click button#pembaToggle": "pembaClick"
    "click button#ungujaToggle": "ungujaClick"
    "click button#testButton": "testButtonClick"
    "click .heatMapButton, #heatMapToggle": "heatMapToggle"
    "click .timeButton": "timeToggle"
    "click .clusterButton": "clusterToggle"
#    "click .layersButton": "layersToggle"
    "click .imageButton": "snapImage"
    "focus #map": "mapFocus"
    "blur #map": "mapBlur"
    "click button.caseBtn": "showCaseDialog"
    "click button#closeDialog": "closeDialog"
  
  showCaseDialog: (e) ->
    caseID = $(e.target).parent().attr('id') || $(e.target).attr('id')
    Case.showCaseDialog
      caseID: caseID
      success: ->
    return false

  closeDialog: () ->
    caseDialog.close() if caseDialog.open
      
  pembaClick: (event)=>
        $('#pembaToggle').toggleClass 'mdl-button--raised', true
        $('#ungujaToggle').toggleClass 'mdl-button--raised', false
        map.setView([-5.187, 39.746], 10, {animate:true})

  ungujaClick: (event)=>
        $('#pembaToggle').toggleClass 'mdl-button--raised', false
        $('#ungujaToggle').toggleClass 'mdl-button--raised', true
        map.setView([-6.1, 39.348], 10, {animate:true})
  
  testButtonClick: (event)=>
    if map.hasLayer(districtsLabelsLayerGroup)
        map.removeLayer(districtsLabelsLayerGroup) 
    else
        map.addLayer(districtsLabelsLayerGroup)
  heatMapToggle: =>
    if heatMapCoords.length>0
#        console.log 'layerTollBooth.heatLayerOn: ' + layerTollBooth.heatLayerOn
        if !layerTollBooth.heatLayerOn
            layerTollBooth.setHeatLayerStatus true
            layerTollBooth.handleActiveState $('.heatMapButton button'), 'on'
            Coconut.router.reportViewOptions['heatMap'] = 'on'
            url = "#{Coconut.dateSelectorView.reportType}/"+("#{option}/#{value}" for option,value of Coconut.router.reportViewOptions).join("/")
            Coconut.router.navigate(url,{trigger: false})
            heatLayer = L.heatLayer(heatMapCoords, radius: 10) 
            heatTimeLayer = L.heatLayer(heatMapCoordsTime, radius: 10) 
            layerTollBooth.handleHeatMap(map, heatLayer, heatTimeLayer, casesLayer, casesTimeLayer, materialLayersControl)
        else
            layerTollBooth.setHeatLayerStatus false
            layerTollBooth.handleActiveState $('.heatMapButton button'), 'off'
            Coconut.router.reportViewOptions['heatMap'] = 'off'
            url = "#{Coconut.dateSelectorView.reportType}/"+("#{option}/#{value}" for option,value of Coconut.router.reportViewOptions).join("/")
            Coconut.router.navigate(url,{trigger: false})
            if map.hasLayer casesTimeLayer
                casesTimeLayer.clearLayers()
                casesTimeLayer.addData(timeFeatures) 
            layerTollBooth.handleHeatMap(map, heatLayer, heatTimeLayer, casesLayer, casesTimeLayer, materialLayersControl)
  clusterToggle: =>
    if !layerTollBooth.clustersOn
      layerTollBooth.setClustersStatus true
      layerTollBooth.handleActiveState $('.clusterButton button'), 'on'
      Coconut.router.reportViewOptions['clusterMap'] = 'on'
      url = "#{Coconut.dateSelectorView.reportType}/"+("#{option}/#{value}" for option,value of Coconut.router.reportViewOptions).join("/")
      Coconut.router.navigate(url,{trigger: false})
      layerTollBooth.handleClusters(map, clustersLayer, clustersTimeLayer, casesLayer, casesTimeLayer)
      clustersLayer.addTo map
    else
      layerTollBooth.setClustersStatus false
      layerTollBooth.handleActiveState $('.clusterButton button'), 'off'
      Coconut.router.reportViewOptions['clusterMap'] = 'off'
      url = "#{Coconut.dateSelectorView.reportType}/"+("#{option}/#{value}" for option,value of Coconut.router.reportViewOptions).join("/")
      Coconut.router.navigate(url,{trigger: false})
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
      layerTollBooth.handleTime(map, heatLayer, heatTimeLayer, casesLayer, casesTimeLayer, materialLayersControl)
      Coconut.router.reportViewOptions['timeMap'] = 'on'
      url = "#{Coconut.dateSelectorView.reportType}/"+("#{option}/#{value}" for option,value of Coconut.router.reportViewOptions).join("/")
      Coconut.router.navigate(url,{trigger: false})
                
#      if map.hasLayer casesLayer
#        map.removeLayer casesLayer
#        turnCasesLayerOn = true
#      if map.hasLayer heatLayer
#        map.removeLayer heatLayer
    else
      layerTollBooth.setTimeStatus false
      $("#sliderControls").toggle()
      layerTollBooth.handleActiveState $('.timeButton button'), 'off'
      if running == true
        $('#play').html "<i class='material-icons'>play_arrow</i>"
        $('#play').removeClass( "mdl-color--red" ).addClass( "mdl-color--cyan" )
        running = false
        clearInterval timer
      materialLayersControl.removeLayer casesTimeLayer
      if !layerTollBooth.heatLayerOn 
        console.log("mapView.coffee addTimeLayer line:395")
        materialLayersControl.addTimeLayer casesLayer, 'Cases'    
#      console.log('timeToggle casesTimeLayer: ' + casesTimeLayer)
      layerTollBooth.handleTime(map, heatLayer, heatTimeLayer, casesLayer, casesTimeLayer, materialLayersControl)
      Coconut.router.reportViewOptions['timeMap'] = 'off'
      url = "#{Coconut.dateSelectorView.reportType}/"+("#{option}/#{value}" for option,value of Coconut.router.reportViewOptions).join("/")
      Coconut.router.navigate(url,{trigger: false})
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
   
  reportResults = (results) ->
        casesGeoJSON.features =  _(results).chain().map (malariaCase) ->
#            NumberofLLIN":"1","NumberofSleepingPlacesbedsmattresses":"1"
          if malariaCase.Household?["HouseholdLocation-latitude"] and malariaCase.Household["HouseholdLocation-accuracy"] <= Coconut.config.location_accuracy_threshold
            
            { 
              type: 'Feature'
              properties:
                MalariaCaseID: malariaCase.caseID
                hasAdditionalPositiveCasesAtIndexHousehold: malariaCase.hasAdditionalPositiveCasesAtIndexHousehold()
                numberOfCasesInHousehold: malariaCase.positiveCasesAtIndexHousehold().length
                NumberofLLIN: malariaCase.Household.NumberofLLIN
                SleepingSpaces: malariaCase.Household.NumberofSleepingPlacesbedsmattresses
                RecentTravel: malariaCase.Facility?.TravelledOvernightinpastmonth
                date: malariaCase.indexCaseDiagnosisDate() or malariaCase.householdMembersDiagnosisDates() #malariaCase.householdMembersDiagnosisDates() malariaCase.indexCaseDiagnosisDate() malariaCase.Household?.lastModifiedAt
                dateIRS: malariaCase.Household.LastdateofIRS
              geometry:
                type: 'Point'
                coordinates: [
                  malariaCase.Household?["HouseholdLocation-longitude"]
                  malariaCase.Household?["HouseholdLocation-latitude"]
                ]
            }
        .compact().value()
#        console.log 'casesGEoJSON: '+JSON.stringify casesGeoJSON
#        LayerTollBooth = ->
#          @CasesLoaded = false
#          return
        layerTollBooth = new LayerTollBooth(map, casesLayer)
#        myLayerContromaterialLayersControl.setLayerTollBooth layerTollBooth
        if casesGeoJSON.features.length > 0
            layerTollBooth.setCasesStatus true
            layerTollBooth.enableDisableButtons 'enable'
            if !legend._map    
                legend.addTo map
                setUpLegend()
            
        else
            layerTollBooth.setCasesStatus false
            layerTollBooth.enableDisableButtons 'disable'
            if legend.getContainer()
              legend.removeFrom map
        updateMap casesGeoJSON
        return
  
  updateMap = (data) =>
#        console.log "data: "+JSON.stringify data
#        console.log('updateMap MapZoom: '+map.getZoom())
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
            layer.bindPopup "caseID: #{caselink} <br />\n Household Cases: " + (parseInt(feature.properties.numberOfCasesInHousehold) + 1) + "<br />\n Date: "+feature.properties.date + "<br />\n Recent Travel: "+feature.properties.RecentTravel + "<br />\n LLIN Count: "+feature.properties.NumberofLLIN + "<br />\n Sleeping Spaces: "+feature.properties.SleepingSpaces  + "<br />\n Last Date of IRS: "+feature.properties.dateIRS      
            clustersLayer.addLayer layer
            layer.on 'click', (e) ->
              console.log 'Click Cases'
              return
            
            return
          pointToLayer: (feature, latlng) =>
            # household markers with secondary cases
            #clusering as well
#            if feature.properties.hasAdditionalPositiveCasesAtIndexHousehold == false
#                L.circleMarker latlng, singleCaseStyle
#            else
#                L.circleMarker latlng, multiCaseStyle
            L.circleMarker latlng, getCaseStyle(feature)
          )
        casesLayer.addTo(map)
        
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
            
            caselink = "
              <button class='mdl-button mdl-js-button mdl-button--primary caseBtn' id='#{feature.properties.MalariaCaseID}'>
              #{feature.properties.MalariaCaseID}</button>
            "
            layer.bindPopup "caseID: #{caselink} <br />\n Household Cases: " + (parseInt(feature.properties.numberOfCasesInHousehold) + 1) + "<br />\n Date: "+feature.properties.date + "<br />\n Recent Travel: "+feature.properties.RecentTravel + "<br />\n LLIN Count: "+feature.properties.NumberofLLIN + "<br />\n Sleeping Spaces: "+feature.properties.SleepingSpaces  + "<br />\n Last Date of IRS: "+feature.properties.dateIRS
            layer.on 'click', (e) ->
              return   
            #clustersLayer.addLayer layer
#            dateIRS
            return
          pointToLayer: (feature, latlng) =>
            # household markers with secondary cases
            #clusering as well
#            if feature.properties.hasAdditionalPositiveCasesAtIndexHousehold == false
#                L.circleMarker latlng, singleCaseStyle
#            else
#                L.circleMarker latlng, multiCaseStyle
            L.circleMarker latlng, getCaseStyle(feature)
          )
        if data.features.length > 0 && layerTollBooth.heatLayerOn == false
          console.log("Mapview.Coffee addCasesLayer line:549")
          materialLayersControl.addQueriedLayer casesLayer, 'Cases'
        
        heatMap = getURLValue 'heatMap'
        if heatMap == 'on' then $('.heatMapButton').trigger "click"
        clusterMap = getURLValue 'clusterMap'
        if clusterMap == 'on' then $('.clusterButton').trigger "click"
        timeMap = getURLValue 'timeMap'
        if timeMap == 'on' then $('.timeButton').trigger "click"
        
        $('#analysis-spinner').hide()
        
        return    
  
  getURLValue = (value) ->
    url = window.location.href    
#    console.log('getUTLValue: ' + value + ' ; ' + url )
    urlAry = url.split('/')
    valueIndex = urlAry.indexOf(value)
    if valueIndex > -1
        return urlAry[valueIndex + 1]
    else
        return undefined
    
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
        if !map.hasLayer(casesTimeLayer) and !layerTollBooth.timeOn
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
                caselink = "
                  <button class='mdl-button mdl-js-button mdl-button--primary caseBtn' id='#{feature.properties.MalariaCaseID}'>
                  #{feature.properties.MalariaCaseID}</button>
                "
                layer.bindPopup "caseID: #{caselink} <br />\n Household Cases: " + (parseInt(feature.properties.numberOfCasesInHousehold) + 1) + "<br />\n Date: "+feature.properties.date + "<br />\n Recent Travel: "+feature.properties.RecentTravel + "<br />\n LLIN Count: "+feature.properties.NumberofLLIN + "<br />\n Sleeping Spaces: "+feature.properties.SleepingSpaces  + "<br />\n Last Date of IRS: "+feature.properties.dateIRS      
                clustersTimeLayer.addLayer layer 
                layer.on 'click', (e) ->
                  console.log 'Click CaseTime2'
                  return
                return
              pointToLayer: (feature, latlng) =>
                # household markers with secondary cases
                #clusering as well
#                if feature.properties.hasAdditionalPositiveCasesAtIndexHousehold == false
#                    L.circleMarker latlng, singleCaseStyle
#                else
#                    L.circleMarker latlng, multiCaseStyle
                L.circleMarker latlng, getCaseStyle(feature)
              ).addTo(map)

              materialLayersControl.removeLayer casesLayer 
              if !document.getElementById('timeInput')
                materialLayersControl.addTimeLayer casesTimeLayer, 'Cases (time)'
#              materialLayersControl.addTimeLayer casesTimeLayer, 'Cases (time)'    
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
    
  snapImage: =>
#    progressBar.showPleaseWait()
    $('#analysis-spinner').show()
    blDistrictsLayerOn = false
    blShehiasLayerOn = false
    blVillagesLayerOn = false
    if map.hasLayer districtsLabelsLayerGroup
        map.removeLayer districtsLabelsLayerGroup
        blDistrictsLayerOn = true
    if map.hasLayer shehiasLabelsLayerGroup
        map.removeLayer shehiasLabelsLayerGroup
        blShehiasLayerOn = true
    if map.hasLayer villagesLabelsLayerGroup
        map.removeLayer villagesLabelsLayerGroup
        blVillagesLayerOn = true
    leafletImage map, (err, canvas) =>
      if (err)
        console.log(err)
      else
        a = document.createElement('a')
        a.href = canvas.toDataURL('image/jpeg').replace('image/jpeg', 'image/octet-stream')
        a.download = 'coconutMap.jpg'
        a.click()
        #@snapshot.innerHTML = ''
        $('#analysis-spinner').hide()
        if blDistrictsLayerOn == true
            map.addLayer districtsLabelsLayerGroup
        if blShehiasLayerOn == true
            map.addLayer shehiasLabelsLayerGroup
        if blVillagesLayerOn == true
            map.addLayer villagesLabelsLayerGroup
        Dialog.createDialogWrap()
        Dialog.confirm("Map download successfully completed...", "Success",["Ok"])

  
        
  render: =>
    $('#analysis-spinner').show()
    options = $.extend({},Coconut.router.reportViewOptions)
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
      success: reportResults
#        console.log 'success'
##        console.log "results: " + JSON.stringify results
#        casesGeoJSON.features =  _(results).chain().map (malariaCase) ->
#          if malariaCase.Household?["HouseholdLocation-latitude"]
#            { 
#              type: 'Feature'
#              properties:
#                MalariaCaseID: malariaCase.caseID
#                hasAdditionalPositiveCasesAtIndexHousehold: malariaCase.hasAdditionalPositiveCasesAtIndexHousehold()
#                numberOfCasesInHousehold: malariaCase.positiveCasesAtIndexHousehold().length
#                numberOfCasesInHousehold: malariaCase.positiveCasesAtIndexHousehold().length
#                date: malariaCase.Household?.lastModifiedAt
#              geometry:
#                type: 'Point'
#                coordinates: [
#                  malariaCase.Household?["HouseholdLocation-longitude"]
#                  malariaCase.Household?["HouseholdLocation-latitude"]
#                ]
#            }
#        .compact().value()
##        console.log 'casesGEoJSON: '+JSON.stringify casesGeoJSON
#        console.log 'casesGeoJSON.features: ' + casesGeoJSON.features.length
##        LayerTollBooth = ->
##          @CasesLoaded = false
##          return
#        layerTollBooth = new LayerTollBooth(map, casesLayer)
#        if casesGeoJSON.features.length > 0
#            console.log('set true: ')
#            layerTollBooth.setCasesStatus true
#            layerTollBooth.enableDisableButtons 'enable'
#        else
#            console.log('set false')
#            layerTollBooth.setCasesStatus false
#            layerTollBooth.enableDisableButtons 'disable' 
#        updateMap casesGeoJSON

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
            width: 38px;
            height: 18px;
            float: left;
            margin-right: 8px;
            opacity: 0.7;
        }
        .legend .smallCircle {
          border-radius: 50%;
          width: 8px;
          height: 8px;
          margin-top: 4px;
          margin-left: 2px;
        }
        .legend .largeCircle {
          border-radius: 50%;
          width: 12px;
          height: 12px;
        }
        .legend .legendLabel {
          display: inline;    
        }
        .districtLabels{
          white-space:nowrap;
          text-shadow: 0 0 0.1em black, 0 0 0.1em black,
                0 0 0.1em black,0 0 0.1em black,0 0 0.1em;
          color: #feb493
        }
        .shehiaLabels{
          white-space:nowrap;
          text-shadow: 0 0 0.1em black, 0 0 0.1em black,
                0 0 0.1em black,0 0 0.1em black,0 0 0.1em;
          color: #d1bce9
        }
        .villageLabels{
          white-space:nowrap;
          text-shadow: 0 0 0.1em black, 0 0 0.1em black,
                0 0 0.1em black,0 0 0.1em black,0 0 0.1em;
          color: #8dffd8
        }
        .info {
            padding: 6px 8px;
            font: 14px/16px Arial, Helvetica, sans-serif;
            background: white;
            background: rgba(255,255,255,0.8);
            box-shadow: 0 0 15px rgba(0,0,0,0.2);
            border-radius: 5px;
        }
        .info h4 {
            margin: 0 0 5px;
            color: #777;
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
            height: 85px;
            font-size: 14px;
            font-family: 'Raleway', sans-serif;
            padding-top: 7px;
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
        <!--<div class='mdl-grid' style='height:5%'>
            <div class='mdl-cell mdl-cell--12-col'>
                    <div style='display: inline-block'>
                        <label for='pembaToggle'>Switch to: </label>
                        <button id='pembaToggle' class='mdl-button mdl-js-button mdl-button--primary mdl-js-ripple-effect mdl-button--accent'>Pemba</button>
                        <label for='ungujaToggle'>or</label>
                        <button id='ungujaToggle' class='mdl-button mdl-js-button mdl-button--primary mdl-js-ripple-effect mdl-button--accent'>Unguja</button>
                        
                        <button id='testButton' class='mdl-button mdl-js-button mdl-button--primary mdl-js-ripple-effect mdl-button--accent'>TEST</button>
                        
                        <form style='display: inline-flex'>
                          <div class='mui-select'>
                            <select style='padding-right:20px'>
                              <option value='island'>Islands</option>
                              <option value='district'>Districts</option>
                              <option value='shehias'>Shehias</option>
                              <option value='villages'>Villages</option>
                            </select>
                          </div>
                          <div class='mui-textfield' style='padding-left:20px'>
                            <input type='text' class='typeahead' placeholder='Input 1'>
                          </div>
                        </form>
                    </div>
                </div>
            <div class='mdl-cell mdl-cell--1-col'></div>
        </div>-->
        <div class='mdl-grid' style='height:80%'>                
            <div class='mdl-cell mdl-cell--12-col' style='height:100%'>
                <div style='width:100%;height:100%;position: relative;' id='map'></div>
            </div>
        </div>
        <div class='mdl-grid' style='height:10%'>
            <div class='mdl-cell mdl-cell--12-col' id='sliderCell' style='height:20%'>
                <div id='sliderControls'>
                    <div id='playDiv'>
                        <button name='play' id='play' class='mdl-button mdl-js-button mdl-button--fab mdl-js-ripple-effect mdl-button--mini-fab mdl-color--cyan'>
                            <i class='material-icons'>play_arrow</i>
                        </button>
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
    satellite = L.tileLayer('https://api.mapbox.com/styles/v1/mapbox/satellite-streets-v9/tiles/256/{z}/{x}/{y}?access_token=pk.eyJ1IjoicHVua21hcCIsImEiOiJjaWw5eWV4dzUwMGZwdHJsemN2b2tlN3kzIn0.8hX6wwKsggKXU2FBK4voOw')
    
    
    #Check map for url settings. 
    zoom = getURLValue 'mapZoom'
    if zoom == undefined then zoom = 9
    lat = getURLValue 'mapLat'
    if lat == undefined then lat = -5.567
    lng =  getURLValue 'mapLng'
    if lng == undefined then lng = 39.489
    
    layers = 
      Streets: streets
      Outdoors: outdoors
      Satellite: satellite
    layerTollBooth = new LayerTollBooth
    map = L.map('map',
      center: [
        lat, lng
      ]
      zoom: zoom
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
    
    map.on 'moveend', (e) ->
      Coconut.router.reportViewOptions['mapZoom'] = map.getZoom()
      Coconut.router.reportViewOptions['mapLat'] = map.getCenter().lat.toFixed(3) 
      Coconut.router.reportViewOptions['mapLng'] = map.getCenter().lng.toFixed(3)
      url = "#{Coconut.dateSelectorView.reportType}/"+("#{option}/#{value}" for option,value of Coconut.router.reportViewOptions).join("/")
      Coconut.router.navigate(url,{trigger: false})
      return
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
#    heatMapControl = $('.heatMapButton')
#    heatMapControl.onclick.apply(heatMapControl);
    
    

    materialClusterControl = new (clusterControl)(
      position: 'topleft'
      materialOptions: materialOptions).addTo(map)
    materialTimeControl = new (timeControl)(
      position: 'topleft'
      materialOptions: materialOptions).addTo(map)
    materialFullscreen = new (fullScreenControl)(
      position: 'topright'
      pseudoFullscreen: false
      materialOptions: materialOptions).addTo(map)
#    var materialLayerControl = new L.materialControl.Layers(layers, overlays, {position: 'bottomright', materialOptions: materialOptions}).addTo(map);

    materialLayersControl = new (myLayersControl)(layers, overlays, queriedLayers,
      position: 'topright'
      materialOptions: materialOptions).addTo(map)
#    materialLayersControl.setLayerTollBooth layerTollBooth
    materialImageControl = new (imageControl)(
      position: 'topright'
      materialOptions: materialOptions).addTo(map)
    layerTollBooth.enableDisableButtons 'disable'
    L.control.scale(position: 'bottomright').addTo map
    
    legend = L.control(position: 'bottomleft')

    legend.onAdd = (map) ->
      console.log("legendOnAdd")
      div = L.DomUtil.create('div', 'info legend')
      div.id = "mapLegend"
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
      labels = []
      # loop through our density intervals and generate a label with a colored square for each interval
      categories = [
        'Single Case'
        'Multiple Cases'
      ]
#      div.innerHTML = "Legend"
      

#        div.innerHTML += '<i style="background:' + getColor(grades[i] + 1) + '"></i> ' + grades[i] + (if grades[i + 1] then '&ndash;' + grades[i + 1] + '<br>' else '+')
#        i++
      div
       
    
    
    
    Coconut.database.get 'DistrictsAdjusted'
    .catch (error) -> console.error error
    .then (data) ->
      districtsData = data
      #console.log('districtsData: '+districtsData)
      districtsLayer = L.geoJson(districtsData,
        style: admin1PolyOptions
        onEachFeature: (feature, layer) ->
          layer.bindPopup 'District: ' + feature.properties.District_N
          layer.on 'click', (e) ->
              return
          return
      ).addTo map
      materialLayersControl.addOverlay(districtsLayer, 'Districts')

    invisibleMarkerOptions = 
      radius: 0
      fillColor: '#f44e03'
      opacity: 0
      fillOpacity: 0
    
    districtsCntrPtsJSON = undefined
    Coconut.database.get 'DistrictsCntrPtsWGS84'
    .catch (error) -> console.error error
    .then (data) ->
        districtsCntrPtsJSON = data
        districtsCntrPtFeatures = districtsCntrPtsJSON.features
        for key of districtsCntrPtFeatures
          if districtsCntrPtFeatures.hasOwnProperty(key)
            val = districtsCntrPtFeatures[key]
            divIcon = L.divIcon(className: "districtLabels", html: val.properties.NAME)
            marker = L.marker([val.geometry.coordinates[1], val.geometry.coordinates[0]], {icon: divIcon })
            districtsLabelsLayerGroup.addLayer(marker)

        L.geoJson(districtsCntrPtsJSON, pointToLayer: (feature, latlng) ->
            L.circleMarker latlng, invisibleMarkerOptions
        )    

    shehiasCntrPtsJSON = undefined
    Coconut.database.get 'ShehiaCntrPtsWGS84'
    .catch (error) -> console.error error
    .then (data) ->
        shehiasCntrPtsJSON = data
        shehiasCntrPtFeatures = shehiasCntrPtsJSON.features
        for key of shehiasCntrPtFeatures
          if shehiasCntrPtFeatures.hasOwnProperty(key)
            val = shehiasCntrPtFeatures[key]
            divIcon = L.divIcon(className: "shehiaLabels", html: val.properties.NAME)
            marker = L.marker([val.geometry.coordinates[1], val.geometry.coordinates[0]], {icon: divIcon })
            shehiasLabelsLayerGroup.addLayer(marker)

        L.geoJson(shehiasCntrPtsJSON, pointToLayer: (feature, latlng) ->
            L.circleMarker latlng, invisibleMarkerOptions
        )

    villagesCntrPtsJSON = undefined
    Coconut.database.get 'VillageCntrPtsWGS84'
    .catch (error) -> console.error error
    .then (data) ->
        villagesCntrPtsJSON = data
        villagesCntrPtFeatures = villagesCntrPtsJSON.features
        for key of villagesCntrPtFeatures
          if villagesCntrPtFeatures.hasOwnProperty(key)
            val = villagesCntrPtFeatures[key]
            divIcon = L.divIcon(className: "villageLabels", html: val.properties.NAME)
            marker = L.marker([val.geometry.coordinates[1], val.geometry.coordinates[0]], {icon: divIcon })
            villagesLabelsLayerGroup.addLayer(marker)

        L.geoJson(villagesCntrPtsJSON, pointToLayer: (feature, latlng) ->
            L.circleMarker latlng, invisibleMarkerOptions
        )

#
#    shehiasCntrPtsJSON = undefined
#    $.ajax
#      url: '../../mapdata/ShehiaCntrPtsWGS84.json?V=2'
#      dataType: 'json'
#      type: 'GET'
#      async: false
#      success: (data) ->
#        console.log "shahias: " + JSON.stringify data
#        shehiasCntrPtsJSON = data
#        return
#    console.log "districtsCntrPtsJSON: " + shehiasCntrPtsJSON.features.length
#    
#    shehiasCntrPtFeatures = shehiasCntrPtsJSON.features
#    for key of shehiasCntrPtFeatures
#      if shehiasCntrPtFeatures.hasOwnProperty(key)
#        val = shehiasCntrPtFeatures[key]
#        divIcon = L.divIcon(className: "shehiaLabels", html: val.properties.NAME)
#        marker = L.marker([val.geometry.coordinates[1], val.geometry.coordinates[0]], {icon: divIcon })
#        shehiasLabelsLayerGroup.addLayer(marker)
#    
#    L.geoJson(shehiasCntrPtsJSON, pointToLayer: (feature, latlng) ->
#        console.log "pointToLayerShahiaCntrPt"
#        L.circleMarker latlng, invisibleMarkerOptions
#    )

#      console.log('districtsData: '+districtsData)
#      districtsCntrPtsLayer = L.geoJson(districtsData,
#        style: cntrpts
#      )
#    districtsCntrPtsJSON = undefined
#    $.ajax
#      url: '../../mapdata/DistrictsCntrPtsWGS84.json?V=1'
#      dataType: 'json'
#      type: 'GET'
#      async: false
#      success: (data) ->
#        districtsCntrPtsJSON = data
#        return
#    console.log "districtsCntrPtsJSON: " + districtsCntrPtsJSON.features.length
#    


#
#    villagesCntrPtsJSON = undefined
#    $.ajax
#      url: '../../mapdata/VillageCntrPtsWGS84.json?V=2'
#      dataType: 'json'
#      type: 'GET'
#      async: false
#      success: (data) ->
#        villagesCntrPtsJSON = data
#        return
#    
#    villagesCntrPtFeatures = villagesCntrPtsJSON.features
#    for key of villagesCntrPtFeatures
#      if villagesCntrPtFeatures.hasOwnProperty(key)
#        val = villagesCntrPtFeatures[key]
#        divIcon = L.divIcon(className: "villageLabels", html: val.properties.NAME)
#        marker = L.marker([val.geometry.coordinates[1], val.geometry.coordinates[0]], {icon: divIcon })
#        villagesLabelsLayerGroup.addLayer(marker)
#    
#    L.geoJson(villagesCntrPtsJSON, pointToLayer: (feature, latlng) ->
#        console.log "pointToLayerVillageCntrPt"
#        L.circleMarker latlng, invisibleMarkerOptions
#    )



      
    
    Coconut.database.get 'ShehiasAdjusted'
    .catch (error) -> console.error error
    .then (data) ->
      shehiasData = data
      shehiasLayer = L.geoJson(shehiasData,
        style: admin2PolyOptions
        onEachFeature: (feature, layer) ->
          layer.bindPopup 'Shehia: ' + feature.properties.Shehia         
          layer.on 'click', (e) ->
              return
            
          return
      )
      materialLayersControl.addOverlay(shehiasLayer, 'Shehias')
    
    Coconut.database.get 'VillagesAdjusted'
    .catch (error) -> console.error error
    .then ( data) ->
      villagesData = data
      villagesLayer = L.geoJson(villagesData,
        style: admin3PolyOptions
        onEachFeature: (feature, layer) ->
          #console.log 'villages feature.properties' + feature.properties.Vil_Mtaa_N
          layer.bindPopup 'Village: ' + feature.properties.Vil_Mtaa_N     
          layer.on 'click', (e) ->
              return
          return
      )
      materialLayersControl.addOverlay(villagesLayer, 'Villages')

    
    
#    customLayers = L.control.layers(layers, overlays).addTo map
#
#    legend = L.control(position: 'bottomleft')
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
        
#    i = 0
#    while i < grades.length
#      i++
#    div
#
#    
#    legend.onAdd = (map) =>
#      console.log 'legend.onAdd'
#      categories = [
#        'Single Case'
#        'Multiple Cases'
#      ]
#      i = 0
#      while i < categories.length
#        div.innerHTML += '<i style="background:' + getColor(categories[i]) + '"></i> ' + (if categories[i] then categories[i] + '<br>' else '+')
#        i++
#      div 
        
#    legend.addTo(map)
    
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
      resizeRender()
#      svgWidth = parseInt(d3.select('#sliderContainer').style('svgWidth'), 10);
#      svgWidth = svgWidth - svgMargin.left - svgMargin.right;
#      d3.select('.xaxis').attr('svgWidth', svgWidth + svgMargin.left + svgMargin.right)    
      return

    d3.select(window).on 'resize', resize
    
    resizeRender = ->
        updateDimensions($('#sliderCell').width());
        
    
    updateDimensions = (winWidth) ->
        svgMargin = 
          top: 20
          right: 50
          bottom: 20
          left: 50
        svgWidth = winWidth - (svgMargin.left) - (svgMargin.right) - 100
        svgHeight = 80 - (svgMargin.bottom) - (svgMargin.top)
        inputStartDate = new Date(startDate)
        inputStartDate.setDate inputStartDate.getDate() + 1
        inputEndDate = new Date(endDate)
        inputEndDate.setDate inputEndDate.getDate() + 1
        timeScale = d3.time.scale().domain([
          inputStartDate
          inputEndDate
        ]).range([
          0
          svgWidth
        ]).clamp(true)
        startValue = timeScale(inputStartDate)
        startingValue = inputStartDate
        endValue = timeScale(inputEndDate)
        endingValue = inputEndDate
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
    
    $('#play').on 'click', ->
      duration = 300
      maxstep = 201
      minstep = 200
      if running == true
        $('#play').html "<i class='material-icons'>play_arrow</i>"
        $('#play').removeClass( "mdl-color--red" ).addClass( "mdl-color--cyan" )
        running = false
        clearInterval timer
      else if running == false
        $('#play').html "<i class='material-icons'>pause</i>"
        $('#play').removeClass( "mdl-color--cyan" ).addClass( "mdl-color--red" )
        playEndTime = timeScale.brush.extent()[1]
        playStartTime = timeScale.brush.extent()[0]
        timer = setInterval((->
          if timeScale.brush.extent()[1] < timeScale.domain()[1]
              update()
          else
              oneDay = 24*60*60*1000
              diffDays = Math.round(Math.abs((timeScale.brush.extent()[1] - timeScale.brush.extent()[0])/(oneDay)));
              lowerExtent = new Date(timeScale.domain()[0])
              upperExtent = new Date(timeScale.domain()[0])
              upperExtent.setDate(upperExtent.getDate() + diffDays)
              d3.select('resizew').attr 'transform', 'translate(' + timeScale.domain()[0] + ',0)'
        #      handle.select('text').text formatDate(playStartTime)
              d3.select('textw').text formatDate(timeScale.domain()[0])
              d3.select('resizee').attr 'transform', 'translate(' + upperExtent + ',0)'
        #      handle.select('text').text formatDate(playStartTime)
              d3.select('texte').text formatDate(upperExtent)
              d3.select('.brush').transition().call(timeScale.brush.extent [
                lowerExtent
                upperExtent
              ]).call timeScale.brush.event
#              update()
              
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
    resizeRender()
    
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
   
module.exports = MapView
    