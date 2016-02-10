_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

class HeaderView extends Backbone.View

  render: =>
    @$el.html "
      <h2>Coconut Reporting</h2>
      HEADER TExT
    "

module.exports = HeaderView
