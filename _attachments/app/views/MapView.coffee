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
#    console.log "SetUpLegendCaseStyle: " + caseStyle

    theDiv = L.DomUtil.get('mapLegend')
    if theDiv
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
#  console.log('d: ' + d)



setCaseStyle = (styleType, feature) ->
#    console.log(styleType)
    if styleType == 'travelCases'
      if feature.feature.properties.RecentTravel == false
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
      if feature.properties.RecentTravel == false
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
#    console.dir("legend.getContainer().hidden: " + legend._map)
    if !legend._map
        legend.addTo map
        setUpLegend()
  else if toState == "off"
#    console.dir("legend.getContainer().hidden: " + legend._map)
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
        $('#play').html "<i class='mdi mdi-play mdi-24px'></i>"
        $('#play').removeClass( "mdl-color--red" ).addClass( "mdl-color--cyan" )
        running = false
        clearInterval timer
      materialLayersControl.removeLayer casesTimeLayer
      if !layerTollBooth.heatLayerOn
#        console.log("mapView.coffee addTimeLayer line:395")
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
        console.log(results)
        casesGeoJSON.features =  _(results.rows).chain().map (result) ->
          caseSummary = result.doc
#          console.log("caseSummary: " + JSON.stringify(caseSummary));
#            NumberofLLIN":"1","NumberofSleepingPlacesbedsmattresses":"1"
          Householdlocationlatitude = if caseSummary["Household Location Latitude"] then "Household Location Latitude" else "Household Location - Latitude"
          Householdlocationaccuracy = if caseSummary["Household Location Accuracy"] then "Household Location Accuracy" else "Household Location - Accuracy"
          if caseSummary[Householdlocationlatitude] and parseFloat(caseSummary[Householdlocationaccuracy]) <= parseFloat(Coconut.config.location_accuracy_threshold)

            {
              type: 'Feature'
              properties:
                MalariaCaseID: caseSummary["Malaria Case ID"]
                hasAdditionalPositiveCasesAtIndexHousehold: caseSummary["Number Positive Cases At Index Household"] > 0
                numberOfCasesInHousehold: caseSummary["Number Positive Cases At Index Household"]
                NumberofLLIN: if caseSummary["Number of LLIN"]? then caseSummary["Number of LLIN"] else caseSummary["Number Of LLIN"]
                SleepingSpaces: if caseSummary["Number of Sleeping Places (Beds/Mattresses)"]? then caseSummary["Number of Sleeping Places (Beds/Mattresses)"] else caseSummary["Number Of Sleeping Places (beds/mattresses)"]
                RecentTravel: caseSummary["Index Case Has Travel History"]
                date: caseSummary["Index Case Diagnosis Date"]
                dateIRS: if caseSummary["Last Date of IRS"]? then caseSummary["Last Date of IRS"] else caseSummary["Last Date Of IRS"]
              geometry:
                type: 'Point'
                coordinates: [
                  caseSummary["Household Location - Longitude"] or caseSummary["Household Location Longitude"]
                  caseSummary["Household Location - Latitude"] or caseSummary["Household Location Latitude"]
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
            if legend?.getContainer()
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
              100#adjust with slider
            ]

            heatMapCoords.push coords
            caselink = "
              <button class='mdl-button mdl-js-button mdl-button--primary caseBtn' id='#{feature.properties.MalariaCaseID}'>
              #{feature.properties.MalariaCaseID}</button>
            "
            layer.bindPopup "caseID: #{caselink} <br />\n Household Cases: " + (parseInt(feature.properties.numberOfCasesInHousehold) + 1) + "<br />\n Date: "+feature.properties.date + "<br />\n Recent Travel: "+feature.properties.RecentTravel + "<br />\n LLIN Count: "+ feature.properties.NumberofLLIN  + "<br />\n Sleeping Spaces: "+ (feature.properties.SleepingSpaces)  + "<br />\n Last Date of IRS: "+feature.properties.dateIRS
            clustersLayer.addLayer layer
            layer.on 'click', (e) ->
              layer.openPopup()
#              console.log("map.getPanes: " + JSON.stringify(map.getPanes()));
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
        casesLayer.on 'mouseover', ->
#          console.log 'casesLayer'
          return
#        casesLayer.on 'click', ->
#          casesLayer.openPopup()
#          console.log 'casesLaeyr Click'
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
            layer.bindPopup "<b>caseID: #{caselink} <br />\n Household Cases: " + (parseInt(feature.properties.numberOfCasesInHousehold) + 1) + "<br />\n Date: "+feature.properties.date + "<br />\n Recent Travel: "+feature.properties.RecentTravel + "<br />\n LLIN Count: "+feature.properties.NumberofLLIN + "<br />\n Sleeping Spaces: "+feature.properties.SleepingSpaces  + "<br />\n Last Date of IRS: "+feature.properties.dateIRS
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
          100   #adjust with slider
        ]
        heatMapCoordsTime.push coords

    #console.log("timeFeatures.length: " + timeFeatures.length)
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
#                  console.log 'Click CaseTime2'
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
    # $('#analysis-spinner').show()
    options = $.extend({},Coconut.router.reportViewOptions)
    HTMLHelpers.ChangeTitle("Maps")
    casesGeoJSON =
      'type': 'FeatureCollection'
      'features': []
    timeCasesGeoJSON =
      'type': 'FeatureCollection'
      'features': []
    startDate = options.startDate
    endDate = options.endDate
    # Coconut.database.query "caseIDsByDate",
    #   startkey: startDate
    #   endkey: endDate
    #   include_docs: true
    # .catch (error) -> console.error error
    # .then (result) -> reportResults(result)
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
        <div class='mdl-grid' style='height:85%'>
            <div class='mdl-cell mdl-cell--12-col' style='height:100%'>
                <div style='width:100%;height:100%;position: relative;' id='map'></div>
            </div>
        </div>
    "
    
    openStreetMapDefault = L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
        })
    streets = L.tileLayer('https://{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}', { maxZoom: 20, subdomains: ['mt0', 'mt1', 'mt2', 'mt3']})
    outdoors = L.tileLayer('https://{s}.google.com/vt/lyrs=p&x={x}&y={y}&z={z}', {maxZoom: 20,subdomains:['mt0','mt1','mt2','mt3']})
    satellite = L.tileLayer('https://{s}.google.com/vt/lyrs=s,h&x={x}&y={y}&z={z}',{maxZoom: 20, subdomains:['mt0','mt1','mt2','mt3']})
    map = L.map('map', {center: [-5.67, 39.49], zoom: 9, layers: [openStreetMapDefault,streets,outdoors,satellite]})
    baseMaps =
    'Default': openStreetMapDefault
    'Outdoors': outdoors
    'Satellite': satellite
    'Streets': streets
    
    invisibleMarkerOptions =
      radius: 0
      fillColor: '#f44e03'
      opacity: 0
      fillOpacity: 0
    Coconut.database.get 'ShehiasAdjusted'
      .catch (error) -> console.error error
      .then (data) ->
        new L.GeoJSON(data, { style: admin2PolyOptions }).addTo(map)

    shehiasCntrPtsJSON = undefined
    Coconut.database.get 'ShehiaCntrPtsWGS84'
    .catch (error) -> console.error error
    .then (data) ->
        shehiasCntrPtsJSON = new L.GeoJSON(data).addTo(map)
        return
        # for key of shehiasCntrPtFeatures
        #   if shehiasCntrPtFeatures.hasOwnProperty(key)
        #     val = shehiasCntrPtFeatures[key]
        #     divIcon = L.divIcon(className: "shehiaLabels", html: val.properties.NAME)
        #     marker = L.marker([val.geometry.coordinates[1], val.geometry.coordinates[0]], {icon: divIcon })
        #     shehiasLabelsLayerGroup.addLayer(marker)

        # L.geoJSON(shehiasCntrPtsJSON, pointToLayer: (feature, latlng) ->
        #     return L.circleMarker latlng, invisibleMarkerOptions
        # ).addTo(map)
        # shehiasLayer = L.geoJson(data,
        #   style: admin2PolyOptions
        #   onEachFeature: (feature, layer) ->
        #     # console.log feature ,layer
        #     layer.bindPopup 'District: ' + feature.properties.District_N + '<br />\n Shehia: ' + feature.properties.Shehia
        #     layer.on 'click', (e) ->
        #         alert e
        #     return
        # )
        # materialLayersControl.addOverlay(shehiasLayer, 'Shehias')
    overlayMaps = { "Shehias": shehiasCntrPtsJSON }
    L.control.layers(baseMaps).addTo(map)
module.exports = MapView