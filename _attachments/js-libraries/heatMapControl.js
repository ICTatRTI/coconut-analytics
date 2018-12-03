'use strict'
var heatMapControl =  L.Control.extend({

  options: {
    position: 'topright'
  },

  onAdd: function (map) {
    var container, controlName, options;
    container = L.DomUtil.create('div', 'heatMapButton leaflet-control-zoom-mdl leaflet-bar-mdl');
    options = this.options;
    this._zoomHomeButton = this._createMaterialButton('leaflet-zoom-in-mdl ', '<i class="material-icons">whatshot</i>', "turn on heat map", container); 
      
    return container;
  },
  _toggleState: false,
  get toggleState(){
    return this._toggleState;
  },
  set toggleState(val){
    this._toggleState = val;
  }
});
