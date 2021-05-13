_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

moment = require 'moment'
global.Graphs = require '../models/Graphs'
DateSelectorView = require './DateSelectorView'
AdministrativeAreaSelectorView = require './AdministrativeAreaSelectorView'

class EntomologyInvestigationsView extends Backbone.View

  render: =>
    @$el.html "
      <h1>Entomology Investigations</h1>

    "

module.exports = EntomologyInvestigationsView
