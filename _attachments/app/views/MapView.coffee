_ = require "underscore"
$ = require "jquery"
Backbone = require "backbone"
Case = require '../models/Case'
DateSelectorView = require '../views/DateSelectorView'
Backbone.$ = $
require('leaflet')
global.CenterOfPolygon = require 'polylabel'
#require('leaflet.heat')
HTMLHelpers = require '../HTMLHelpers'


class MapView extends Backbone.View

  events: =>
    "change .changeBoundary":"changeBoundary"
    "change #showLabels":"showLabels"
    "change .changeTileSet":"changeTiles"
    "change #showSprayedShehias":"showSprayedShehias"
    "click #zoomPemba":"zoomPemba"
    "click #zoomUnguja":"zoomUnguja"

  zoom: (target) =>
    target = target.toUpperCase()
    @map.fitBounds switch target
      when "UNGUJA" 
        [
          [-6.489983,39.130554]
          [-5.714380,39.633179]
        ]
      when "PEMBA" 
        [
          [-5.506640,39.549065]
          [-4.858022,39.889984]
        ]

  zoomPemba: =>
    @zoom "PEMBA"

  zoomUnguja: =>
    @zoom "UNGUJA"

  showSprayedShehias: =>
    if @$('#showSprayedShehias').is(":checked")
      @$(".sprayed-shehia").css("fill","lightgreen")
    else
      @$(".sprayed-shehia").css("fill","")

  changeTiles: =>
    @showTileSet @$('input[name=tileSet]:checked').val()

  changeBoundary: =>
    @showBoundary @$('input[name=boundary]:checked').val()

  showLabels: =>
    if @$('#showLabels').is(":checked")
      @addLabels @$('input[name=boundary]:checked').val()
    else
      @removeLabels()

  render: =>
    @initialBoundary or= "Districts"
    @initialTileSet or= "None"
    @$el.html "
      <style>
      .map-marker-labels{
        white-space:nowrap;
        color: black;
        font-size: 1em;
      }
      .labels-District{
        font-size: 2em;
      }
      .boundary{
        color: black;
        fill: white;
        stroke-width: 0.5;
        stroke: black;
        fill-opacity: 1;
      }
      .info {
        padding: 6px 8px;
        font: 14px/16px Arial, Helvetica, sans-serif;
        background: white;
        background: rgba(255,255,255,0.8);
        box-shadow: 0 0 15px rgba(0,0,0,0.2);
        border-radius: 5px;
      }
      .legend {
        line-height: 18px;
        color: #555;
      }
      .legend i {
        width: 18px;
        height: 18px;
        float: left;
        margin-right: 8px;
        opacity: 0.7;
      }
      .legend .circle {
        border-radius: 50%;
        width: 10px;
        height: 10px;
        margin-top: 3.6px;
        border: 0.3px black solid;
      }
      #mapElement{
        width: 100%;
        height: 95%;
        position: relative;
        background-color: #e6ffff;
      }
      .label{
        font-size: 1em
      }
      .leaflet-control-scale-line{
        border-color:#b0b0b0;
        color:#b0b0b0;
      }
      .controls .controlBox{
        padding-top: 15px;
        padding-bottom: 10px;
        border: 1px solid black;
      }
      </style>
      <div class='mdl-grid' style='height:100%'>
        <div class='mdl-cell mdl-cell--12-col' style='height:100%'>
          <div class='controls' style='float:right'>
            <span class='controlBox' id='sprayedOption' style='display:none;'>
              <input class='showSprayedShehias' id='showSprayedShehias' type='checkbox' style='margin-left:10px; margin-rght:10px;'></input>
              <label for='showSprayedShehias' class='label'>Sprayed Shehias</label>
            </span>
            <span class='controlBox'>
            #{
              (for boundary in [ "Districts", "Shehias", "Villages"]
                "
                  <input class='changeBoundary' id='select-boundary-#{boundary}' style='display:none; margin-left:10px' type='radio' value='#{boundary}' name='boundary' #{if boundary is @initialBoundary then 'checked' else ''}></input>
                  <span id='loading-boundary-#{boundary}'>Loading...</span>
                  <label for='select-boundary-#{boundary}' class='label'>#{boundary}</label>
                "
              ).join("")
            }
            </span>
            <span class='controlBox'>
            #{
              (for tileSet in [ "None", "RoadsBuildings", "Satellite"]
                "
                <input class='changeTileSet' id='select-tileSet-#{tileSet}' style='margin-left:10px' type='radio' value='#{tileSet}' name='tileSet' #{if tileSet is @initialTileSet then 'checked' else ''}></input>
                <label for='select-tileSet-#{tileSet}' class='label'>#{tileSet}</label>
                "
              ).join("")
            }
            </span>
            <span class='controlBox' style='padding-right: 10px'>
              <input id='showLabels' type='checkbox' style='margin-left:10px; margin-rght:10px;'></input>
              <label for='showLabels' class='label'>Labels</label>
            </span>
          </div>
          <div id='date-selector'></div>
          <div id='mapElement'></div>
        </div>
      </div>
    "

    @map = L.map @$('#mapElement')[0],
      zoomSnap: 0.2
    .fitBounds [
      [-4.8587000, 39.8772333],
      [-6.4917667, 39.0945000]
    ]

    @getCases()
    @createMapLegend()
    @createZoomUngujaPemba()
    promiseWhenBoundariesAreLoaded = @getBoundariesAndLabels
      load: @initialBoundary
    @initializeTileSets()
    L.control.scale().addTo(@map)

    promiseWhenBoundariesAreLoaded

  initializeTileSets: =>
    @tilesets =
      None: null
      RoadsBuildings:
        layer:  openStreetMapDefault = L.tileLayer 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
      Satellite:
        layer: satellite = L.tileLayer('https://{s}.google.com/vt/lyrs=s,h&x={x}&y={y}&z={z}',{ maxZoom: 20, subdomains:['mt0','mt1','mt2','mt3'] })
    #streets = L.tileLayer('https://{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}', { maxZoom: 20, subdomains: ['mt0', 'mt1', 'mt2', 'mt3'] })
    #outdoors = L.tileLayer('https://{s}.google.com/vt/lyrs=p&x={x}&y={y}&z={z}', { maxZoom: 20,subdomains:['mt0','mt1','mt2','mt3'] })

  showTileSet: (tileSetName) =>
    if @activeTileSet
      @activeTileSet.removeFrom(@map)
    if tileSetName is "None"
      @activeTileSet = null
      @$(".boundary").css("fill-opacity", 1)
    else
      @activeTileSet = @tilesets[tileSetName].layer
      @activeTileSet.addTo(@map).bringToBack()
      @$(".boundary").css("fill-opacity", 0)


  getBoundariesAndLabels: (options) =>
    @boundaries =
      Districts:
        labelsDocName: 'DistrictsCntrPtsWGS84'
        labelLayer: L.featureGroup()
        featureName: "District_N"
      Villages:
        labelsDocName: 'VillageCntrPtsWGS84'
        labelLayer: L.featureGroup()
        featureName: "Vil_Mtaa_N"
      Shehias:
        labelsDocName: 'ShehiaCntrPtsWGS84'
        labelLayer: L.featureGroup()
        featureName: "Ward_Name"

    for boundaryName, properties of @boundaries

      loadFeatureData = (feature, layer) =>
        if boundaryName is "Shehias"
          if _(@sprayedShehias).contains feature.properties["Ward_Name"]
            layer.setStyle className: "boundary sprayed-shehia"

        # Would be better to find the one with the largest area, but most vertices is close enough, easy and fast
        # Would also be better to save these into the geoJSON as a feature property but it seems fast enough
        polygonWithTheMostVertices = _(layer.feature.geometry.coordinates).max (polygon) => polygon.length
        labelPosition = CenterOfPolygon(polygonWithTheMostVertices).reverse()

        @boundaries[boundaryName].labelLayer.addLayer L.marker(labelPosition,
          icon: L.divIcon
            className: 'map-marker-labels labels-#{boundaryName}'
            html: feature.properties[@boundaries[boundaryName].featureName]
        )
 
      # Cache the maps data locally since the files are big - also kick off a replication to keep them up to date
      await Coconut.cachingDatabase.get "#{boundaryName}Adjusted"
      .catch (error) =>
        new Promise (resolve, reject) =>
          Coconut.cachingDatabase.replicate.from Coconut.database,
            doc_ids: ["#{boundaryName}Adjusted"]
          .on "complete", =>
            resolve(Coconut.cachingDatabase.get "#{boundaryName}Adjusted"
            .catch (error) => console.log error
            )
      .then (data) =>
        @boundaries[boundaryName].boundary = L.geoJSON data, 
          className: "boundary"
          onEachFeature: loadFeatureData

        @$("#select-boundary-#{boundaryName}").show()
        @$("#loading-boundary-#{boundaryName}").hide()

        @showBoundary(boundaryName) if options.load is boundaryName

    # Wait 5 seconds then check for updated to the maps
    _.delay =>
      Coconut.cachingDatabase.replicate.from Coconut.database,
        doc_ids: _(@boundaries).chain().keys().map( (boundaryName) => "#{boundaryName}Adjusted").value()
      .on "complete", => console.log "Map data updated"
    , 1000 * 5

  showBoundary: (boundaryName) =>
    if @activeBoundary
      @activeBoundary.removeFrom(@map)
    @activeBoundary = @boundaries[boundaryName].boundary
    if @activeLabels
      @removeLabels()
      @addLabels(boundaryName)
    @activeBoundary.addTo(@map).bringToBack()
    if boundaryName is "Shehias"
      @$("#sprayedOption").show()
    else
      @$("#sprayedOption").hide()
      @$('#showSprayedShehias').prop('checked', false);

  addLabels: (boundaryName) =>
    @removeLabels() if @activeLabels
    console.log boundaryName
    console.log @boundaries
    @activeLabels = @boundaries[boundaryName].labelLayer
    @activeLabels.addTo(@map).bringToBack()

  removeLabels: =>
    @activeLabels.removeFrom(@map)
    @activeLabels = null


  colorByClassification = {
    Indigenous: "red"
    Imported: "blue"
    Introduced: "darkgreen"
    Induced: "purple"
    Relapsing: "orange"
  }

  getCases: =>
    Coconut.reportingDatabase.query 'keyIndicatorsByDate',
      startkey: Coconut.router.reportViewOptions.startDate
      endkey: Coconut.router.reportViewOptions.endDate
    .then (result) =>
      for row in result.rows
        continue unless row.value.latLong?
        caseId = row.id.replace(/.*_/,"")
        L.circleMarker row.value.latLong,
          color: '#000000'
          weight: 0.3
          radius: 12
          fill: true
          fillOpacity: 0.8
          fillColor: if row.value.classification
              colorByClassification[row.value.classification]
            else
              "red"
        .addTo(@map)
        .bringToFront()
        .bindPopup "<a href='#show/case/#{caseId}'>#{caseId}</a>"
  
  createMapLegend: =>
    legend = L.control(position: 'bottomright')

    legend.onAdd = (map) =>
        div = L.DomUtil.create('div', 'info legend')
        for classification in Coconut.CaseClassifications
          div.innerHTML +=  "
            <i class='circle' style='background:#{colorByClassification[classification]}'></i>
            #{classification}<br/>
          "
        div

    legend.addTo(@map)


  createZoomUngujaPemba: =>
    legend = L.control({ position: 'topleft' })

    legend.onAdd = (map) =>
      div = L.DomUtil.create('div', 'zoom')
      div.innerHTML +=  "
          <button style='background-color:white' class='zoom' id='zoomUnguja'>Unguja</button><br/><br/>
          <button style='background-color:white' class='zoom' id='zoomPemba'>Pemba</button>
        "
      div

    legend.addTo(@map)
      


    @sprayedShehias= """
Mfenesini
Mihogoni
Mkokotoni
Mto wa Pwani
Mwakaje
Fuoni Kibondeni
Tondooni
Dole
Bumbwisudi
Shakani
Kiembesamaki
Chukwani
Fukuchani
Ndagoni
Fumba
Bweleo
Dimani
Kombeni
Nungwi
Mgelema
Magogoni
Pwani Mchangani
Gamba
Mtoni Kidatu
Moga
Fuoni Kijito Upele
Kinyasini
Kandwi
Mbuzini
Kisauni
Kinuni
Nyamanzi
Kigomani
Misufini
Makombeni
Makoba
Makoongwe
Mangapwani
Fujoni
Kiomba Mvua
Donge  Mchangani
Michenzani
Chokocho
Zingwe Zingwe
Kitope
Mahonda
Kinduni
Mizingani
Donge Mbiji
Donge Kipange
Upenja
Kiwengwa
Mbuyuni
Muwanda
Matetema
Kidanzini
Mbaleni
Mafufuni
Machui
Miwani
Kiboje Mkwajuni
Ghana
Koani
Mgeni Haji
Uzini
Mitakawani
Tunduni
Bambi
Pagali
Mtambwe Kaskazini
Umbuji
Fundo
Mchangani
Dunga Kiembeni
Ndijani Mseweni
Jendele
Chwaka
Marumbi
Uroa
Piki
Jumbi
Tunguu
Gando
Ukunjwi
Cheju
Bungi
Unguja Ukuu Kaepwani
Kikungwi
Mtambwe Kusini
Uzi
Charawe
Michamvi
Mpapa
Unguja Ukuu Kaebona
Junguni
Kiungoni
Jambiani Kikadini
Kizimkazi Dimbani
Kinowe
Kizimkazi Mkunguni
Muyuni A
Tumbe Mashariki
Muyuni B
Muyuni C
Shumba Viamboni
Pete
Paje
Jambiani Kibigija
Makangale
Bwejuu
Kitogani
Wingwi Njuguni
Mwera
Chimba
Bububu
Tumbe Magharibi
    """.split("\n")


module.exports = MapView
