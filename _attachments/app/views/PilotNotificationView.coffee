_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

DataTables = require( 'datatables.net' )()
Reports = require '../models/Reports'

class PilotNotificationView extends Backbone.View
  el: "#content"

  render: =>

    @$el.html "
        <div id='dateSelector'></div>
    "
    options = $.extend({},Coconut.router.reportViewOptions)

module.exports = PilotNotificationView
