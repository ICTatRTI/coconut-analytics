_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

class MenuView extends Backbone.View

  render: =>
    @$el.html "
      <h2>Coconut Reporting</h2>
      MENU
      <a href='#dashboard'>Dashboard</a>
    "

module.exports = MenuView
