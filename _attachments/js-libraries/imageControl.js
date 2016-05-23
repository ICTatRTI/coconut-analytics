'use strict'
var imageControl =  L.Control.extend({

  options: {
    position: 'topright'
  },

  onAdd: function (map) {
    var container, controlName, options;
    container = L.DomUtil.create('div', 'imageButton leaflet-control-zoom-mdl leaflet-bar-mdl');
    options = this.options;
    console.log(JSON.stringify(options))
      this._zoomHomeButton = this._createMaterialButton('leaflet-zoom-in-mdl ', '<i class="material-icons">photo_camera</i>', "Download Map Image", container); 
      
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
