_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

Reports = require '../models/Reports'

class AlertsView extends Backbone.View

  renderAlertStructure: (alerts_to_check)  =>
    $("#content").html "
      <h3>Alerts</h3>
      <div id='alerts_status' style='padding-bottom:20px;font-size:150%'>
        <h4>Checking for system alerts: #{alerts_to_check.join(", ")}</h4>
      </div>
      <div id='alerts'>
        #{
          _.map(alerts_to_check, (alert) -> "<div id='#{alert}'><br/></div>").join("")
        }
      </div>
    "

    @alerts = false

    # Don't call this until all alert checks are complete
    @afterFinished = _.after(alerts_to_check.length, ->
      if @alerts
        $("#alerts_status").html("<div id='hasAlerts'>Report finished, alerts found.</div>")
      else
        $("#alerts_status").html("<div id='hasAlerts'>Report finished, no alerts found.</div>")
    )

  render: =>
    @alerts_to_check = 'system_errors, not_followed_up, unknown_districts'.split(/, */)

    @$el.html "
      <h3>Alerts</h3>
      <div id='alerts_status' style='padding-bottom:20px;font-size:150%'>
        <h4>Checking for system alerts: #{@alerts_to_check.join(", ")}</h4>
      </div>
      <div id='alerts'>
        #{
          _.map(@alerts_to_check, (alert) -> "<div id='#{alert}'><br/></div>").join("")
        }
      </div>
	"
    @alerts = false
    options = Coconut.router.reportViewOptions

    #@renderAlertStructure  'system_errors, not_followed_up, unknown_districts'.split(/, */)

    Reports.systemErrors options,
      success: (errorsByType) =>
        if _(errorsByType).isEmpty()
          $('#system_errors').append 'No system errors in the past 2 days.'
        else
          @alerts = true

          $('#system_errors').append "
            The following system errors have occurred in the last 2 days:
            <table style='border:1px solid black' class='tablesorter'>
              <thead>
                <tr>
                  <th>Time of most recent error</th>
                  <th>Message</th>
                  <th>Number of errors of this type in last 24 hours</th>
                  <th>Source</th>
                </tr>
              </thead>
              <tbody>
                #{
                  _.map(errorsByType, (errorData, errorMessage) ->
                    "
                      <tr>
                        <td>#{errorData['Most Recent']}</td>
                        <td>#{errorMessage}</td>
                        <td>#{errorData.count}</td>
                        <td>#{errorData['Source']}</td>
                      </tr>
                    "
                  ).join("")
                }
              </tbody>
            </table>
          "
       # @afterFinished()
    _.after(@alerts_to_check.length, ->
        if @alerts
           $("#alerts_status").html("<div id='hasAlerts'>Report finished, alerts found.</div>")
        else
           $("#alerts_status").html("<div id='hasAlerts'>Report finished, no alerts found.</div>")
    )
module.exports = AlertsView
