_ = require "underscore"
$ = require "jquery"
Backbone = require "backbone"
Backbone.$  = $
L = require 'leaflet'

class MapView extends Backbone.View
  el: '#content'

  events:
    "click #foo": "buttonClick"

  buttonClick: =>
    @map.setView([40, 74.5], 3)

  render: =>
    
    @$el.html "
        <button id='foo'>Click me</button>
        <h3>Mockup Rap</h3>
        <div>Use + - buttons to zoom map. Click and drag to reposition the map. Circles with a darker have multiple cases. Red cases show households with additional positive malaria cases.<br> 
    <!--
		<div>
		   <img src='images/sample-map.png' />
		</div>
    -->
    <div style='width:200px;height:200px;' id='map'></div>
    "
    
    @map = L.map('map')
    @map.setView([40, -74.5], 3)
    L.tileLayer('http://{s}.tile.osm.org/{z}/{x}/{y}.png', { attribution: '&copy; <a href="http://osm.org/copyright">OpenStreetMap</a> contributors' }).addTo(@map)
    




module.exports = MapView
