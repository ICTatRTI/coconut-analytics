_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

class HeaderView extends Backbone.View
  events:
    "click a#logout": "Logout"

  Logout: ->
    App.login()
	  
  render: =>
    @$el.html "
      <div class='mdl-layout__header-row'>
 		<div class='mdl-layout-icon'></div>  
		<span class='mdl-layout-title' id='layout-title'>Dashboard</span>
      </div>
	  <div id='report-title'> </div>
	  <div class='mdl-layout-spacer'></div>
	  <div id='logged-in'><i class='material-icons'>account_circle</i> <span id='username'>John Doe</span></div>	  
	  <div class='wrapper'>
	    <button class='mdl-button mdl-js-button mdl-js-ripple-effect mdl-button--icon' id='menu-top-right'> 
			<i class='material-icons'>more_vert</i> 
		</button>	
		<ul class='mdl-menu mdl-menu--bottom-right mdl-js-menu mdl-js-ripple-effect'
		    for='menu-top-right'>
		  <li class='mdl-menu__item'><a id='help' href='#' class='mdl-color-text--blue-grey-400'><i class='material-icons'>help</i> Help</a></li>
		  <li class='mdl-menu__item'><a id='profile' href='#' class='mdl-color-text--blue-grey-400'><i class='material-icons'>account_box</i> My Profile</a></li>
		  <li disabled class='mdl-menu__item'>Disabled Action</li>
		  <li class='mdl-menu__item'><a id='logout' href='#' class='mdl-color-text--blue-grey-400'><i class='material-icons'>exit_to_app</i> Logout</a></li>
		  <li class='mdl-menu__item login' ><a id='login' href='#' class='mdl-color-text--blue-grey-400'><i class='material-icons'>exit_to_app</i> Login</a></li>
		</ul>
	  </div>
    "

module.exports = HeaderView
