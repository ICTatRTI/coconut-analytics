_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
Cookies = require 'js-cookie'
AboutView = require './AboutView'
HelpView = require './HelpView'

class HeaderView extends Backbone.View
  el: "header.coconut-header"

  events:
    "click a#logout": "Logout"
    "click a#changepass": "ChangePass"
    "click a#about": "About"
    "click a#help": "Help"

  Logout: ->
    Coconut.router.navigate "#logout", {trigger: true}

  Login: ->
    Coconut.router.navigate "#login"

  ChangePass: ->
   Coconut.router.navigate "#change_password", {trigger: true}

  About: ->
    Coconut.aboutView = new AboutView() if !Coconut.aboutView
    Coconut.aboutView.render()

  Help: ->
    Coconut.helpView = new HelpView() if !Coconut.helpView
    Coconut.helpView.render()

  render: =>
    @$el.html "
      <div class='mdl-layout__header-row'>
 		    <div class='mdl-layout-icon'></div>
		      <span class='mdl-layout-title' id='layout-title'>Dashboard</span>
      </div>
	    <div id='report-title'> </div>
	    <div class='mdl-layout-spacer'></div>
	    <div id='logged-in'><i class='mdi mdi-account-circle mdi-36px'></i> <span id='username'>#{Coconut.currentlogin || ""}</span></div>
	    <div class='wrapper'>
	      <button class='mdl-button mdl-js-button mdl-js-ripple-effect mdl-button--icon' id='menu-top-right'>
			    <i class='mdi mdi-dots-vertical mdi-36px'></i>
		    </button>
		    <ul class='mdl-menu mdl-menu--bottom-right mdl-js-menu mdl-js-ripple-effect' for='menu-top-right'>
    		  <li class='mdl-menu__item'><a id='help' class='mdl-color-text--blue-grey-400'><i class='mdi mdi-help-circle mdi-24px'></i> Help</a></li>
          <li class='mdl-menu__item'><a id='about' class='mdl-color-text--blue-grey-400'><i class='mdi mdi-information mdi-24px'></i> About</a></li>
          <li class='mdl-menu__item'><a id='changepass' class='mdl-color-text--blue-grey-400'><i class='mdi mdi-key mdi-24px'></i> Change Passwd</a></li>
    		  <li class='mdl-menu__item'><a id='logout' href='#login' class='mdl-color-text--blue-grey-400'><i class='mdi mdi-logout mdi-24px'></i> Logout</a></li>
    		  <li class='mdl-menu__item login' ><a id='login' href='#' class='mdl-color-text--blue-grey-400'><i class='mdi mdi-login mdi-24px'></i> Login</a></li>
		    </ul>
	    </div>
    "

module.exports = HeaderView
