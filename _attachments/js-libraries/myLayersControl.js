'use strict'
var caseStyle = 'numberCases';
    
var myLayersControl =  L.Control.extend({
    
  options: {
      position: 'topright',
      autoZIndex: true
  },
  initialize: function (baseLayers, overlays, queriedLayers, options) {
    L.setOptions(this, options);
//    console.log('initialize options: ' + JSON.stringify(options))
    this._lastZIndex = 0;
    this._layers = {};
    this._baseLayers = baseLayers;
    this._overlays = overlays;
    this._queriedLayers = queriedLayers;
    for (var i in baseLayers) {
//	    console.log('baselayer._addLayer')
        this._addLayer(baseLayers[i], i);
	}

	for (i in overlays) {
//	    console.log('overlays._addLayer')
	    this._addLayer(overlays[i], i, true, true);
	}    
    for (i in queriedLayers) {
//	    console.log('overlays._addLayer')
	    this._addLayer(queriedLayers[i], i, true, true, true);
	}
//    console.log ('initialize overlays: ' + overlays)
  },
  onAdd: function (map) {
    console.log('onAdd Update');
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
    console.log("addbaseLayer Update")
    this._addLayer(layer, name);
	this._update();
	return this;
  },

  addOverlay: function (layer, name) {
    console.log("addOverlay Update")
    this._addLayer(layer, name, true);
	this._update();
	return this;
  },
  addQueriedLayer: function (layer, name) {
//    if(!$("#caseInput")){
        console.log("addQuerriedLayer update")
        this._addLayer(layer, name, true, true);
        this._update();
        return this;
//    }
  },
  addTimeLayer: function (layer, name) {
//    if(!$("#timeInput")){
        console.log("addTimeLayer update")
        this._addLayer(layer, name, true, true, true);
        this._update();
        return this;
//    }
  },
  removeLayer: function (layer) {
    console.log("removeLayer Update")  
	var id = L.stamp(layer);
	delete this._layers[id];
    this._update();
    return this;
  },
//  setLayerTollBooth: function(layerTollBooth){
//      this._layerTollBooth = layerTollBooth;
//      console.log("setLayerTollBooth")
//  },
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
		this._queriedLayersList = L.DomUtil.create('div', className + '-queriedLayers', form);
		this._separator = L.DomUtil.create('div', className + '-separator', form);
		this._overlaysList = L.DomUtil.create('div', className + '-overlays', form);

		
	}, 
        
    _addLayer: function (layer, name, overlay, queried, time) {
    var id = L.stamp(layer);

	this._layers[id] = {
		layer: layer,
		name: name,
		overlay: overlay,
        queried: queried, 
        time: time
	};
    if (this.options.autoZIndex && layer.setZIndex) {
        this._lastZIndex++;
		layer.setZIndex(this._lastZIndex);
	}
//    console.log('this._layers[id]: '+this._layers[id].layer+ ' ' + this._layers[id].name + ' ' + this._layers[id].overlay)
//	console.log('this.options.autoZIndex: '+this.options.autoZIndex)
//    if (this.options.autoZIndex && layer.setZIndex) {
//		this._lastZIndex++;
//        //console.log('addLayer name: :'+name+":")
//        
//        if (name == 'Cases'){
//          //console.log('ZIndex: '+0)
//          layer.setZIndex(1);
//        }
//		else{
//          layer.setZIndex(this._lastZIndex);
//          //console.log('ZIndex: '+this._lastZIndex);
//        }
//        
//	}
  },
  _update: function () {
    //console.log('update')
		if (!this._container) {
			return;
		}
//
		this._baseLayersList.innerHTML = '';
		this._overlaysList.innerHTML = '';
		this._queriedLayersList.innerHTML = '';
        

		var baseLayersPresent = false,
		    overlaysPresent = false,
		    queriedLayersPresent = false,
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
			queriedLayersPresent = queriedLayersPresent || obj.queried;
		}

		this._separator.style.display = overlaysPresent && baseLayersPresent ? '' : 'none';
	},
    _onLayerChange: function (e) {
        var obj = this._layers[L.stamp(e.layer)];
        console.log("obj: "+obj)
		
		if (!obj || typeof(obj.name)!=undefined) { return; }
        console.log("obj.name: " + obj.name)
		if (!this._handlingClick && obj.name != "Cases") {
			console.log("onLayerChange update")
            this._update();
		}

		var type = obj.overlay ?
			(e.type === 'layeradd' ? 'overlayadd' : 'overlayremove') :
			(e.type === 'layeradd' ? 'baselayerchange' : null);

		if (type) {
            console.log("type: "+type)
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
    _addItem: function (obj) {
        console.log('addItem obj.name: '+obj.name)
//        console.log('addItem obj.layer: '+obj.layer)
        var label = document.createElement('label'),
		    input,
            button,
            select,
		    checked = this._map.hasLayer(obj.layer);
        if (obj.queried && !obj.time){label.id = "caseInput"}
        else if(obj.time){label.id = "timeInput"}
//        console.log('obj.name: '+obj.name);
//		console.log('obj.overlay: '+obj.overlay);
		if (obj.overlay) {
			input = document.createElement('input');
            input.type = 'checkbox';
			input.className = 'leaflet-control-layers-selector';
			input.defaultChecked = checked;
        } else if(!obj.overlay) {
			input = this._createRadioElement('leaflet-base-layers', checked);
		}

		input.layerId = L.stamp(obj.layer);
//        console.log('input: '+input)
        
		L.DomEvent.on(input, 'click', this._onInputClick, this);

		var name = document.createElement('span');
		name.innerHTML = ' ' + obj.name;
        if (obj.overlay && !obj.queried){name.style.paddingRight = '7px'};
		label.appendChild(input);
		label.appendChild(name);
        
        if (obj.overlay && !obj.queried){
            var labelButtonContainer = document.createElement('button', 'mdl-button mdl-js-button mdl-button--icon');
            var labelButton = this._createMaterialButton(obj.name+'_lableButton', '<i class="material-icons off" id = "click_'+obj.name+'" style = "font-size: 14px;">label_outline</i>', "Label "+obj.name, labelButtonContainer);
            labelButton.style.fontSize = "14px";
            labelButton.style.minWidth = "22px";
            labelButton.style.minHeight = "22px";
            labelButton.style.width = "22px";
            labelButton.style.height = "22px";
            labelButton.style.display = "inline";
            label.appendChild(labelButton)
            L.DomEvent.on(labelButton, 'click', this._onLabelButtonClick, this);
        }
        
//        if(obj.queried && !$( "#mapStyleSelect" )[ 0 ]){
        if(obj.queried){
            console.log('obj.querried = true')
            select = document.createElement('select');
            select.id = 'mapStyleSelect';
            select.className = 'mdl-select__input';
            select.options[select.options.length] = new Option('One and More Cases', 'numberCases');
            select.options[select.options.length] = new Option('Travel History', 'travelCases');
            select.options[select.options.length] = new Option('# of LLIN < Sleeping Places', 'llinCases');
            console.log("this.caseStyle: " + caseStyle)
            select.value = caseStyle;
            console.log("select.options[select.selectedIndex].value: " + select.options[select.selectedIndex].value)
            L.DomEvent.on(select, 'change', function () {
//                console.log(select.options[select.selectedIndex].value);
                console.log("caseStyle: " + caseStyle);
                var newStyle = select.options[select.selectedIndex].value;
                caseStyle = newStyle; 
                console.log("this.caseStyle: " + caseStyle)
                var event = new CustomEvent('caseStyleChange', { 'detail': { 
                    caseType: newStyle 
                    }
                });   
                window.dispatchEvent(event);
            });
            label.appendChild(select);
        }
        console.log('myLayerControl obj.overlay: ' + obj.overlay)
        console.log('myLayerControl obj.queried: ' + obj.queried)
        var container;
        if(obj.overlay){
            if(obj.queried){
                console.log("overlay and query")
                container = this._queriedLayersList;
            }
            else{
                container = this._overlaysList;
            }
        }
        else{
            container = this._baseLayersList;
        }
//		var container = obj.overlay ? this._overlaysList : this._baseLayersList;
		console.log("label: " + label)
        container.appendChild(label);
        
		return label;
	},
//    _update: function () {
//		console.log('update')
//        if (!this._container) {
//			return;
//		}
//
//		this._baseLayersList.innerHTML = '';
//		this._overlaysList.innerHTML = '';
//
//		var baseLayersPresent = false,
//		    overlaysPresent = false,
//		    i, obj;
//
//		for (i in this._layers) {
//			obj = this._layers[i];
//            this._addItem(obj);
//			overlaysPresent = overlaysPresent || obj.overlay;
//			baseLayersPresent = baseLayersPresent || !obj.overlay;
//		}
//
//		this._separator.style.display = overlaysPresent && baseLayersPresent ? '' : 'none';
//	},
//    _onLayerChange: function (e) {
//		var obj = this._layers[L.stamp(e.layer)];
//
//		if (!obj) { return; }
//        
////		if (!this._handlingClick) {
////			this._update();
////		}
//        console.log("_onLayerChange update")
//        this._update()
//
//		var type = obj.overlay ?
//			(e.type === 'layeradd' ? 'overlayadd' : 'overlayremove') :
//			(e.type === 'layeradd' ? 'baselayerchange' : null);
//
//		if (type) {
//			this._map.fire(type, obj);
//		}
//	},
    
    _onInputClick: function () {
		console.log("onInputClick")
        var i, input, obj,
		    inputs = this._form.getElementsByTagName('input'),
		    inputsLen = inputs.length;
        this._handlingClick = true;
        console.dir("inputs: " + inputs);
        console.log("inputsLen: " + inputsLen);
		for (i = 0; i < inputsLen; i++) {
			input = inputs[i];
//			console.log('input.LayerId: '+input.layerId);
            obj = this._layers[input.layerId];
//            console.log('obj.layer: '+obj.layer);
			console.log("i: "+i)
            console.log('obj.name: '+obj.name);
            if (input.checked && !this._map.hasLayer(obj.layer)) {
				this._map.addLayer(obj.layer);

			} else if (!input.checked && this._map.hasLayer(obj.layer)) {
				this._map.removeLayer(obj.layer);
			}
//            if(obj.name != "Cases"){    
//                if (input.checked && !this._map.hasLayer(obj.layer)) {
//                    this._map.addLayer(obj.layer);
//
//                } else if (!input.checked && this._map.hasLayer(obj.layer)) {
//                    this._map.removeLayer(obj.layer);
//                }
//            }
//            else{
////                console.log("this._layerTollBooth: " + this._layerTollBooth.timeOn)
////                LayerTollBooth.timeOn
//                if (input.checked && !this._map.hasLayer(obj.layer)) {
//                    this._map.addLayer(obj.layer);
//
//                } else if (!input.checked && this._map.hasLayer(obj.layer)) {
//                    this._map.removeLayer(obj.layer);
//                }
//            }
		}

		this._handlingClick = false;

		this._refocusOnMap();
	},
    _onLabelButtonClick: function (e) {
		var targetID = $("#"+e.target.id);
        var labelLayer = e.target.id.split("_")[1];
        var targetButton = $("#"+labelLayer+"_lableButton");
        var onOff;
        if (targetID.hasClass("off")){
            onOff = "on";
            targetID.removeClass( "off" ).addClass( "on" );
            targetButton.removeClass( "mdl-color--cyan" ).addClass( "mdl-color--red" );
        }
        else{
            onOff = "off";
            targetID.removeClass( "on" ).addClass( "off" );
            targetButton.removeClass( "mdl-color--red" ).addClass( "mdl-color--cyan" );
        }
        var event = new CustomEvent('labelsOnOff', { 'detail': { 
                layer: labelLayer,
                onOff: onOff
            }
        });   
        window.dispatchEvent(event);

//        if (activeStatus =='on'){
//            button.removeClass( "mdl-color--cyan" ).addClass( "mdl-color--red" );
//        }
//        else{
//            button.removeClass( "mdl-color--red" ).addClass( "mdl-color--cyan" );
//        }
        
	},
  _toggleState: false,
  get toggleState(){
    return this._toggleState;
  },
  set toggleState(val){
    this._toggleState = val;
  },
  
});

