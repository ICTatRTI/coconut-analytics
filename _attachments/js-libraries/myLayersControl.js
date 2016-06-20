'use strict'
var myLayersControl =  L.Control.extend({

  options: {
      position: 'topright'
  },
  onAdd: function (map) {
    console.log('onAdd');
    this._initLayout();
		this._update();

	map
	    .on('layeradd', this._onLayerChange, this)
	    .on('layerremove', this._onLayerChange, this);

    return this._container;
//    var container, controlName, options;
//    container = L.DomUtil.create('div', 'layersButton leaflet-control-zoom-mdl leaflet-bar-mdl');
//    options = this.options;
//      console.log('options: '+JSON.stringify(options))
//      this._zoomHomeButton = this._createMaterialButton('leaflet-zoom-in-mdl ', '<i class="material-icons">layers</i>', "layers control", container); 
//    for (var key in this._layers) {
//      if (this._layers.hasOwnProperty(key)) {
//        console.log(key + " -> " + this._layers[key]);
//      }
//    }  
//    return container;
  },
  onRemove: function (map) {
    map
		    .off('layeradd', this._onLayerChange, this)
		    .off('layerremove', this._onLayerChange, this);
  },
  addBaseLayer: function (layer, name) {
	this._addLayer(layer, name);
	this._update();
	return this;
  },

  addOverlay: function (layer, name) {
	this._addLayer(layer, name, true);
	this._update();
	return this;
  },
  initialize: function (baseLayers, overlays, options) {
    L.setOptions(this, options);
//    console.log('initialize options: ' + JSON.stringify(options))
    this._lastZIndex = 1;
    this._layers = baseLayers;
    this._overlays = overlays;
    for (var i in baseLayers) {
//	    console.log('baselayer._addLayer')
        this._addLayer(baseLayers[i], i);
	}

	for (i in overlays) {
//	    console.log('overlays._addLayer')
	    this._addLayer(overlays[i], i, true);
	}    
    
//    console.log ('initialize overlays: ' + overlays)
  },
//  _addItem: function (obj){
//    console.log('addItem obj: ' + JSON.stringify(obj))    
//  },
  _initLayout: function () {
		var className = 'leaflet-control-layers',
		    container = this._container = L.DomUtil.create('div', 'layersButton leaflet-control-myLayer-mdl leaflet-bar-mdl');
//        var options = this.options;
//      console.log('options: '+JSON.stringify(options))
      container.style.float = 'right'
      this._zoomHomeButton = this._createMaterialButton('leaflet-myLayerControl-mdl ', '<i class="material-icons">layers</i>', "layers control", container); 
      this._zoomHomeButton.style.float = 'right' 
		//Makes this work on IE10 Touch devices by stopping it from firing a mouseout event when the touch is released
		container.setAttribute('aria-haspopup', true);
        
    
		if (!L.Browser.touch) {
			L.DomEvent
				.disableClickPropagation(container)
				.disableScrollPropagation(container);
		} else {
			L.DomEvent.on(container, 'click', L.DomEvent.stopPropagation);
		}
//        L.DomEvent.on(this._zoomHomeButton, 'click', this._buttonClick());
        
//        div = L.DomUtil.create('div', '<div class="demo-card-square mdl-card mdl-shadow--2dp">')
//		div.innerHTML += '<div class="mdl-card__title mdl-card--expand">
//            <h2 class="mdl-card__title-text">Update</h2>
//          </div>
//          <div class="mdl-card__supporting-text">
//            Lorem ipsum dolor sit amet, consectetur adipiscing elit.
//            Aenan convallis.
//          </div>
//          <div class="mdl-card__actions mdl-card--border">
//            <a class="mdl-button mdl-button--colored mdl-js-button mdl-js-ripple-effect">
//              View Updates
//            </a>
//          </div>'
        var form = this._form = L.DomUtil.create('form', 'demo-card-square mdl-card mdl-shadow--2dp');
        L.DomEvent.on(this._zoomHomeButton, 'click', function() {
//            console.log('domeventCLick')
//            console.log('container.childnodes: ' + container.childNodes)
            L.DomUtil.addClass(form, 'mdl-menu--bottom-right');
            L.DomUtil.addClass(form, 'layerControlForm');
            

            var c = container.childNodes;
//            for (var i = 0; i < c.length; i++) {
//                console.log('nodeName: ' + c[i].nodeName);
//            }
            if (c.length == 1){
//                console.log('formsinthehouse')
                container.appendChild(form);
                
            }
            else{
                container.removeChild(form)
            }
        });
//		if (this.options.collapsed) {
//			if (!L.Browser.android) {
//				L.DomEvent
//				    .on(container, 'mouseover', this._expand, this)
//				    .on(container, 'mouseout', this._collapse, this);
//			}
//			var link = this._layersLink = L.DomUtil.create('a', className + '-toggle', container);
//			link.href = '#';
//			link.title = 'Layers';
//
//			if (L.Browser.touch) {
//				L.DomEvent
//				    .on(link, 'click', L.DomEvent.stop)
//				    .on(link, 'click', this._expand, this);
//			}
//			else {
//				L.DomEvent.on(link, 'focus', this._expand, this);
//			}
//			//Work around for Firefox android issue https://github.com/Leaflet/Leaflet/issues/2033
//			L.DomEvent.on(form, 'click', function () {
//				setTimeout(L.bind(this._onInputClick, this), 0);
//			}, this);
//
//			this._map.on('click', this._collapse, this);
//			// TODO keyboard accessibility
//		} else {
//			this._expand();
//		}

		this._baseLayersList = L.DomUtil.create('div', className + '-base', form);
		this._separator = L.DomUtil.create('div', className + '-separator', form);
		this._overlaysList = L.DomUtil.create('div', className + '-overlays', form);

		
	}, 
        
    _addLayer: function (layer, name, overlay) {
//	console.log('addLayer name: '+name)
    var id = L.stamp(layer);

	this._layers[id] = {
		layer: layer,
		name: name,
		overlay: overlay
	};
    
//    console.log('this._layers[id]: '+this._layers[id].layer+ ' ' + this._layers[id].name + ' ' + this._layers[id].overlay)
//	console.log('this.options.autoZIndex: '+this.options.autoZIndex)
    if (this.options.autoZIndex && layer.setZIndex) {
		this._lastZIndex++;
        //console.log('addLayer name: :'+name+":")
        
        if (name == 'Cases'){
          //console.log('ZIndex: '+0)
          layer.setZIndex(1);
        }
		else{
          layer.setZIndex(this._lastZIndex);
          //console.log('ZIndex: '+this._lastZIndex);
        }
        
	}
  },
  _update: function () {
    //console.log('update')
		if (!this._container) {
			return;
		}
//
		this._baseLayersList.innerHTML = '';
		this._overlaysList.innerHTML = '';

		var baseLayersPresent = false,
		    overlaysPresent = false,
		    i, obj;

		for (i in this._layers) {
//			console.log('this._layers[i]: '+this._layers[i])
//			console.log('this._layers[i].name: '+this._layers[i].name)
//			console.log('this._layers[i].layer: '+this._layers[i].layer)
            obj = this._layers[i];
//            console.log('update obj: '+obj)
//			console.log('update obj.name: '+obj.name)
//			console.log('update obj.layer: '+ obj.layer)
            if(obj.name){ this._addItem(obj)};
			overlaysPresent = overlaysPresent || obj.overlay;
			baseLayersPresent = baseLayersPresent || !obj.overlay;
		}

		this._separator.style.display = overlaysPresent && baseLayersPresent ? '' : 'none';
	},
    _onLayerChange: function (e) {
//		console.log('onLayerChange');
        var obj = this._layers[L.stamp(e.layer)];

		if (!obj) { return; }

		if (!this._handlingClick) {
			this._update();
		}

		var type = obj.overlay ?
			(e.type === 'layeradd' ? 'overlayadd' : 'overlayremove') :
			(e.type === 'layeradd' ? 'baselayerchange' : null);

		if (type) {
			this._map.fire(type, obj);
		}
	},
    _addItem: function (obj) {
//        console.log('addItem obj.name: '+obj.name)
//        console.log('addItem obj.layer: '+obj.layer)
        var label = document.createElement('label'),
		    input,
		    checked = this._map.hasLayer(obj.layer);
//        console.log('obj.overlay: '+obj.overlay);
		if (obj.overlay) {
			input = document.createElement('input');
			input.type = 'checkbox';
			input.className = 'leaflet-control-layers-selector';
			input.defaultChecked = checked;
		} else {
			input = this._createRadioElement('leaflet-base-layers', checked);
		}

		input.layerId = L.stamp(obj.layer);
//        console.log('input: '+input)
        
		L.DomEvent.on(input, 'click', this._onInputClick, this);

		var name = document.createElement('span');
		name.innerHTML = ' ' + obj.name;

		label.appendChild(input);
		label.appendChild(name);

		var container = obj.overlay ? this._overlaysList : this._baseLayersList;
		container.appendChild(label);

		return label;
	},
    _onLayerChange: function (e) {
		var obj = this._layers[L.stamp(e.layer)];

		if (!obj) { return; }

		if (!this._handlingClick) {
			this._update();
		}

		var type = obj.overlay ?
			(e.type === 'layeradd' ? 'overlayadd' : 'overlayremove') :
			(e.type === 'layeradd' ? 'baselayerchange' : null);

		if (type) {
			this._map.fire(type, obj);
		}
	},
    _createRadioElement: function (name, checked) {

		var radioHtml = '<input type="radio" class="leaflet-control-layers-selector" name="' + name + '"';
		if (checked) {
			radioHtml += ' checked="checked"';
		}
		radioHtml += '/>';

		var radioFragment = document.createElement('div');
		radioFragment.innerHTML = radioHtml;

		return radioFragment.firstChild;
	},
    _onInputClick: function () {
		var i, input, obj,
		    inputs = this._form.getElementsByTagName('input'),
		    inputsLen = inputs.length;

		this._handlingClick = true;
		for (i = 0; i < inputsLen; i++) {
			input = inputs[i];
//			console.log('input.LayerId: '+input.layerId);
            obj = this._layers[input.layerId];
//            console.log('obj.layer: '+obj.layer);
//			console.log('obj.name: '+obj.name);
			if (input.checked && !this._map.hasLayer(obj.layer)) {
				this._map.addLayer(obj.layer);

			} else if (!input.checked && this._map.hasLayer(obj.layer)) {
				this._map.removeLayer(obj.layer);
			}
		}

		this._handlingClick = false;

		this._refocusOnMap();
	},
  _toggleState: false,
  get toggleState(){
    return this._toggleState;
  },
  set toggleState(val){
    this._toggleState = val;
  }
});