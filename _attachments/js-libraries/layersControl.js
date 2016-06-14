'use strict';

var layersControl = L.Control.Layers.extend({
  options: {
      collapsed: true,
      position: 'topright',
      autoZIndex: true,
      hideSingleBase: false
  },

  _initLayout: function () {
    var className = 'leaflet-control-layers-mdl',
        container = this._container = L.DomUtil.create('div', className + ' leaflet-bar-mdl'),
        buttonId = 'leaflet-control-layers-toggle-mdl';
  
    // adjust timeout time for material menu
    MaterialMenu.prototype.Constant_ = {
      // Total duration of the menu animation.
      TRANSITION_DURATION_SECONDS: 0.3,
      // The fraction of the total duration we want to use for menu item animations.
      TRANSITION_DURATION_FRACTION: 0.8,
      // How long the menu stays open after choosing an option (so the user can see
      // the ripple).
      CLOSE_TIMEOUT: 600
    };

    // makes this work on IE touch devices by stopping it from firing a mouseout event when the touch is released
    container.setAttribute('aria-haspopup', true);

    if (!L.Browser.touch) {
      L.DomEvent
        .disableClickPropagation(container)
        .disableScrollPropagation(container);
    } else {
      L.DomEvent.on(container, 'click', L.DomEvent.stopPropagation);
    }

    // create material menu
    var menuClass = 'mdl-menu';
    var form = this._form = L.DomUtil.create('ul', menuClass);
    form.setAttribute('for', buttonId)
    if (this.options.materialOptions.rippleEffect) {
      L.DomUtil.addClass(form, 'mdl-js-ripple-effect');
    }
    switch (this.options.position) {
      case 'topleft': 
        L.DomUtil.addClass(form, 'mdl-menu--bottom-left');
        break;
      case 'topright': 
        L.DomUtil.addClass(form, 'mdl-menu--bottom-right');
        break;
      case 'bottomright':
        L.DomUtil.addClass(form, 'mdl-menu--top-right');
        break;
      case 'bottomleft':
        L.DomUtil.addClass(form, 'mdl-menu--top-left');
        break;
    }
      console.log("form: "+ form)
    var link = this._layersLink = this._createMaterialButton(buttonId, 'layers', 'Layers', container);

    this._baseLayersList = L.DomUtil.create('div', className + '-base', form);
    this._separator = L.DomUtil.create('div', className + '-separator', form);
    var overlaysList = this._overlaysList = L.DomUtil.create('div', className + '-overlays', form);

    var separatorItem = L.DomUtil.create('li', 'mdl-menu__divider', this._separator);
    separatorItem.innerHTML = '<hr />';

    container.appendChild(form);

  },

  _addItem: function (obj) {
    var listClass = 'mdl-menu__item', 
        listItem = L.DomUtil.create('li', listClass),
        label = document.createElement('label'),
        checked = this._map.hasLayer(obj.layer),
        spanLabelClass,
        inputId,
        input;
  
    if (this.options.materialOptions.rippleEffect) {
      L.DomUtil.addClass(label, 'mdl-js-ripple-effect');
    }

    if (obj.overlay) {
      L.DomUtil.addClass(label, 'mdl-checkbox mdl-js-checkbox');
      inputId = 'mdl-layer-checkbox-' + L.stamp(obj.layer);
      label.setAttribute('for', inputId);
      input = L.DomUtil.create('input', 'mdl-checkbox__input');
      input.type = 'checkbox';
      input.defaultChecked = checked;
      input.id = inputId;
      spanLabelClass = 'mdl-checkbox__label';
    } else {
      L.DomUtil.addClass(label, 'mdl-radio mdl-js-radio');
      inputId = 'mdl-layer-option-' + L.stamp(obj.layer);;
      label.setAttribute('for', inputId);
      listItem.innerHTML = this._createRadioElement('leaflet-base-layers', checked);
      input = listItem.firstChild;
      input.id = inputId;
      spanLabelClass = 'mdl-radio__label';
    }

    input.layerId = L.stamp(obj.layer);

    L.DomEvent.on(input, 'click', this._onInputClick, this);

    var name = L.DomUtil.create('span', spanLabelClass);
    name.innerHTML = obj.name;

    label.appendChild(input);
    label.appendChild(name);
    listItem.appendChild(label);
    
    var container = obj.overlay ? this._overlaysList : this._baseLayersList;
    container.appendChild(listItem);

    return listItem;
  },

  // IE7 bugs out if you create a radio dynamically, so you have to do it this hacky way (see http://bit.ly/PqYLBe)
  _createRadioElement: function (name, checked) {
    var radioHtml = '<input type="radio" class="mdl-radio__button" name="' +
            name + '"' + (checked ? ' checked="checked"' : '') + '/>';

    return radioHtml;
  },
});
//'use strict';
//
//var layersControl = L.Control.Layers.extend({
//  options: {
//      collapsed: true,
//      position: 'topright',
//      autoZIndex: true,
//      hideSingleBase: false
//  },
//
//_initLayout: function () {
//		var className = 'leaflet-control-layers',
//		    container = this._container = L.DomUtil.create('div', className);
//
//		//Makes this work on IE10 Touch devices by stopping it from firing a mouseout event when the touch is released
//		container.setAttribute('aria-haspopup', true);
//
//		if (!L.Browser.touch) {
//			L.DomEvent
//				.disableClickPropagation(container)
//				.disableScrollPropagation(container);
//		} else {
//			L.DomEvent.on(container, 'click', L.DomEvent.stopPropagation);
//		}
//
//		var form = this._form = L.DomUtil.create('form', className + '-list');
//
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
//
//		this._baseLayersList = L.DomUtil.create('div', className + '-base', form);
//		this._separator = L.DomUtil.create('div', className + '-separator', form);
//		this._overlaysList = L.DomUtil.create('div', className + '-overlays', form);
//
//		container.appendChild(form);
//	}
//
//  
//});
//
