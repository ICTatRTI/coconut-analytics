_ = require "underscore"
$ = require "jquery"
Backbone = require "backbone"
Backbone.$  = $

class MapView extends Backbone.View
  el: '#content'

  render: =>
    @$el.html "
        <h3>Mockup Map</h3>
        <div>Use + - buttons to zoom map. Click and drag to reposition the map. Circles with a darker have multiple cases. Red cases show households with additional positive malaria cases.<br> 
		<div>
		   <img src='images/sample-map.png' />
		</div>
    "

module.exports = MapView