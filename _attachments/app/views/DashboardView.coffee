_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

DataTables = require 'datatables'

DateSelectorView = require './DateSelectorView'

class DashboardView extends Backbone.View

  render: =>

    @$el.html "
      <h4>Dashboard</h4>
      <div id='dateSelector'></div>
      Start Date: #{@startDate}
      End Date: #{@endDate}
    "

    Coconut.dateSelectorView = new DateSelectorView() unless Coconut.dateSelectorView
    Coconut.dateSelectorView.setElement "#dateSelector"
    Coconut.dateSelectorView.startDate = @startDate
    Coconut.dateSelectorView.endDate = @endDate
    Coconut.dateSelectorView.render()

module.exports = DashboardView
