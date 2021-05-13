_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

moment = require 'moment'
global.Graphs = require '../models/Graphs'
DateSelectorView = require './DateSelectorView'
AdministrativeAreaSelectorView = require './AdministrativeAreaSelectorView'

class EntomologyDashboardView extends Backbone.View

  render: =>
    @$el.html "
      <h1>Entomology Dashboard</h1>
      (Coming soon)
      <li> <a href='#entomology_investigations'>Investigations</a>
      <li> <a href='#entomology_specimens'>Specimens</a>
    "

module.exports = EntomologyDashboardView
