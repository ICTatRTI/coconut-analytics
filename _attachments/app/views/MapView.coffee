_ = require "underscore"
$ = require "jquery"
Backbone = require "backbone"
Case = require '../models/Case'
DateSelectorView = require '../views/DateSelectorView'
Backbone.$ = $
require('leaflet')
require('leaflet.heat')
HTMLHelpers = require '../HTMLHelpers'


class MapView extends Backbone.View
	districtBoundariesStyle = {
		color: 'red'
		weight: 1.5
		opacity: 1
		fillColor: '#B0BF1A'
		fillOpacity: 0.7 }

	villageBoundariesStyle = {
		color: 'green'
		weight: 1.5
		opacity: 1
		fillOpacity: 0 }

	shehiaBoundariesStyle = {
		color: 'blue'
		weight: 1.5
		opacity: 1
		fillOpacity: 0 }

	el: '#content'
	map = undefined
	districtBoundaries = undefined
	villageBoundaries = undefined
	shehiaBoundaries = undefined
	caseColorCodes = {
		ageUnderFive: { name: "Age under 5 Years (Local Case)", color: 'yellow' }
		overnightTravelPastYear: { name: "Imported Case", color: 'red' }
		default: { name: "Local Case", color: 'blue' }
	}

	administrativeLocationCenterPoint = [{ DB: 'DistrictsCntrPtsWGS84', layerName: 'Districts' },
	{ DB: 'VillageCntrPtsWGS84', layerName: 'Villages' },
	{ DB: 'ShehiaCntrPtsWGS84', layerName: 'Shehias' }]

	render: =>
		# $('#analysis-spinner').show()
		HTMLHelpers.ChangeTitle("Maps")
		@$el.html "
        <style>
        .map-marker-labels{
          white-space:nowrap;
          text-shadow: 0 0 0.1em black, 0 0 0.1em black,
                0 0 0.1em black,0 0 0.1em black,0 0 0.1em;
          color: #8dffd8;
          margin-left: -12px;
          margin-top: -41px;
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
        </style>
        <div class='mdl-grid' style='height:100%'>
            <div class='mdl-cell mdl-cell--12-col' style='height:100%'>
                <div id='date-selector'></div>
                <div style='width:100%;height:100%;position: relative;' id='map'></div>
            </div>
		</div>
    "
		dateSelectorView = new DateSelectorView()
		dateSelectorView.setElement('#date-selector')
		dateSelectorView.reportType = 'maps'
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
					return
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
		@getBoundaries()
		@createMapLegend(map)
		
		createAdministrativeLocationsLayers = (DB, layerName) ->
			geojsonMarkerOptions = {
				radius: 8,
				color: "#000",
				weight: 1,
				opacity: 1,
				fillOpacity: 0.8
			}
			Coconut.database.get DB
			.catch (error) -> console.error error
			.then (data) ->
				layer = L.geoJSON(data, {
					pointToLayer: (feature, latlng) ->
						return L.marker latlng, { icon: L.divIcon({ className: 'map-marker-labels',
						html: feature.properties.NAME }) }
				})
				mapLayers.addOverlay(layer, layerName)
				return
		administrativeLocationCenterPoint.forEach (layer) ->
			createAdministrativeLocationsLayers(layer.DB, layer.layerName)
			return

	getBoundaries: ->
		Coconut.database.get 'DistrictsAdjusted'
		.catch (error) -> console.error error
		.then (data) ->
			districtBoundaries = L.geoJSON(data,
			{ style: districtBoundariesStyle })
		Coconut.database.get 'VillagesAdjusted'
			.catch (error) -> console.error error
			.then (data) ->
				villageBoundaries = L.geoJSON(data,
				{ style: villageBoundariesStyle })
		Coconut.database.get 'ShehiasAdjusted'
		.catch (error) -> console.error error
		.then (data) ->
			shehiaBoundaries = L.geoJSON(data,
			{ style: shehiaBoundariesStyle })

	getCases: ->
		Coconut.reportingDatabase.query 'keyIndicatorsByDate', {
			startkey: Coconut.router.reportViewOptions.startDate,
			endkey: Coconut.router.reportViewOptions.endDate }
		.then (result) ->

			for row in result.rows

				options = { color: '#000000',  weight: 0.3, radius: 3,
				fill: true, fillOpacity: 0.8 , fillColor: caseColorCodes.default.color }
				
				if row.value.overnightTravelPastYear
					options = { ...options, fillColor: caseColorCodes.overnightTravelPastYear.color }
				if row.value.ageUnderFive
					options = { ...options, fillColor: caseColorCodes.ageUnderFive.color }
				
				L.circleMarker(row.value.latLong, { ...options }).addTo(map)
	
	createMapLegend: (maps) ->
		legend = L.control({ position: 'bottomright' })

		legend.onAdd = (map) ->
			div = L.DomUtil.create('div', 'info legend')
			categories = Object.keys(caseColorCodes)
			i = 0
			while i < categories.length
				div.innerHTML += "<i class='circle' style='background:#{caseColorCodes[categories[i]]["color"]}'></i>" + (if categories[i] then caseColorCodes[categories[i]]["name"] + '<br>' else '+')
				i++
			div
		legend.addTo(maps)
			

module.exports = MapView
