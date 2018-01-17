$ = require 'jquery'

Backbone = require 'backbone'
Backbone.$  = $

class DashboardView extends Backbone.View

  #events:
    #"click button#btnSubmit": "ResetPassword"

  render: =>
    @$el.html "
      <table class='mdl-data-table mdl-js-data-table mdl-data-table--selectable mdl-shadow--2dp'>
        <thead>
          <th></th>
          <th>Kakuma</th>
          <th>Dadaab</th>
          <th>Total</th>
        </thead>
        <tbody>
          #{
            _(
              "Students": [23022, 25411]
              "Girls": [11001, 12121]
              "Boys": [12111, 13111]
              "Schools": [200, 333]
              "Spot checks in last month": [35, 99]
              "Spot checks in last 7 days": [11, 44]
              "Spot checks in last 24 hours": [7,8]
              "Students requiring followup": [117,128]
            ).map (values, property) ->
              "
                <tr>
                  <td>#{property}</td>
                  <td>#{values[0]}</td>
                  <td>#{values[1]}</td>
                  <td>#{values[0] + values[1]}</td>
                </tr>
              "
            .join ""
          }
        </tbody>
      </table>
    "
module.exports = DashboardView
