$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

class DateSelectorView extends Backbone.View

  render: =>
    @$el.html "
      Enter the start date <input value='#{@startDate}'></input>
      Enter the end date <input value='#{@endDate}'></input>
    "
    
module.exports = DateSelectorView
