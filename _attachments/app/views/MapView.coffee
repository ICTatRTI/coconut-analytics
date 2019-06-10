_ = require "underscore"
$ = require "jquery"
Backbone = require "backbone"
Case = require '../models/Case'
DateSelectorView = require '../views/DateSelectorView'
Backbone.$  = $
L = require('leaflet')
map = undefined
HTMLHelpers = require '../HTMLHelpers'
districtBoundaries = undefined
villageBoundaries = undefined
shehiaBoundaries = undefined
layerDBs = [{ DB: 'DistrictsCntrPtsWGS84', layerName: 'Districts' },
              { DB: 'VillageCntrPtsWGS84', layerName: 'Villages' },
              { DB: 'ShehiaCntrPtsWGS84', layerName: 'Shehias' }]
class MapView extends Backbone.View
  districtBoundariesStyle =
    color: '#8BC34A'
    weight: 1.5
    opacity: 1
    fillOpacity: 0
  
  villageBoundariesStyle =
    color: 'green'
    weight: 1.5
    opacity: 1
    fillOpacity: 0
  
  shehiaBoundariesStyle =
    color: 'yellow'
    weight: 1.5
    opacity: 1
    fillOpacity: 0
  el: '#content'
  
  invisibleMarkerOptions = { radius: 0
  fillColor: '#f44e03'
  opacity: 0
  fillOpacity: 0 }
  
  render: =>
    # $('#analysis-spinner').show()
    HTMLHelpers.ChangeTitle("Maps")
    @$el.html "
        <style>
        .villageLabels{
          white-space:nowrap;
          text-shadow: 0 0 0.1em black, 0 0 0.1em black,
                0 0 0.1em black,0 0 0.1em black,0 0 0.1em;
          color: #8dffd8;
          margin-left: -12px;
          margin-top: -41px;
        }
        </style>
        <div class='mdl-grid' style='height:85%'>
            <div class='mdl-cell mdl-cell--12-col' style='height:100%'>
                <div id='date-selector'></div>
                <div style='width:100%;height:100%;position: relative;' id='map'></div>
            </div>
        </div>
    "
    dateSelectorView = new DateSelectorView()
    dateSelectorView.setElement('#date-selector')
    dateSelectorView.render()

    openStreetMapDefault = L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
        })
    streets = L.tileLayer('https://{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}', { maxZoom: 20, subdomains: ['mt0', 'mt1', 'mt2', 'mt3'] })
    outdoors = L.tileLayer('https://{s}.google.com/vt/lyrs=p&x={x}&y={y}&z={z}', { maxZoom: 20,subdomains:['mt0','mt1','mt2','mt3'] })
    satellite = L.tileLayer('https://{s}.google.com/vt/lyrs=s,h&x={x}&y={y}&z={z}',{ maxZoom: 20, subdomains:['mt0','mt1','mt2','mt3'] })
    map = L.map('map', { center: [-5.67, 39.49], zoom: 9, layers: [openStreetMapDefault, streets, outdoors, satellite] })
   
    onOverlayAdd = (e) ->
      switch e.name
        when 'Districts'
          map.addLayer(districtBoundaries)
        when 'Villages'
          map.addLayer(villageBoundaries)
        when 'Shehias'
          map.addLayer(shehiaBoundaries)
    
    onOverlayRemove = (e) ->
      switch e.name
        when 'Districts'
          map.removeLayer(districtBoundaries)
        when 'Villages'
          map.removeLayer(villageBoundaries)
        when 'Shehias'
          map.removeLayer(shehiaBoundaries)
    
    map.on('overlayadd', onOverlayAdd)
    map.on('overlayremove', onOverlayRemove)

    baseMaps =
    'Default': openStreetMapDefault
    'Outdoors': outdoors
    'Satellite': satellite
    'Streets': streets
    mapLayers = L.control.layers(baseMaps).addTo(map)

    @getCases()

    Coconut.database.get 'DistrictsAdjusted'
      .catch (error) -> console.error error
      .then (data) ->
        districtBoundaries =  L.geoJSON(data,
        { style: districtBoundariesStyle })
    Coconut.database.get 'VillagesAdjusted'
      .catch (error) -> console.error error
      .then (data) ->
        villageBoundaries =  L.geoJSON(data,
        { style: villageBoundariesStyle })
    Coconut.database.get 'ShehiasAdjusted'
      .catch (error) -> console.error error
      .then (data) ->
        shehiaBoundaries =  L.geoJSON(data,
        { style: shehiaBoundariesStyle })

    createMapLayers = (DB, layerName) ->
      Coconut.database.get DB
      .catch (error) -> console.error error
      .then (data) ->
          layer =  L.geoJSON(data, {
            pointToLayer: (feature, latlng) ->
              return L.marker latlng, {icon:L.divIcon({className: 'villageLabels', html:feature.properties.NAME})}
          })
          mapLayers.addOverlay(layer, layerName)
          return
    layerDBs.forEach (layer) ->
      createMapLayers(layer.DB, layer.layerName)
      return
  
  getCases: =>
    Coconut.reportingDatabase.query 'caseIDsByDate', 
      startkey: Coconut.router.reportViewOptions.startDate,
      endkey: Coconut.router.reportViewOptions.endDate,
      include_docs: true
    .then(results) =>
      console.log results.rows
module.exports = MapView