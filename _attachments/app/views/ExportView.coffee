$ = require 'jquery'

Backbone = require 'backbone'
Backbone.$  = $

dasherize = require("underscore.string/dasherize")

class ExportView extends Backbone.View

  #events:
    #"click button#btnSubmit": "ResetPassword"

  render: =>
    @$el.html "
      <label for='startDate'>
        Start Date
      </label>
      <input id='startDate' type='date'></input>
      <label for='endDate'>
        End Date
      </label>
      <input id='endDate' type='date'></input>
      <table class='mdl-data-table mdl-js-data-table mdl-data-table--selectable mdl-shadow--2dp'>
        <thead>
          <th></th>
          <th>Kakuma</th>
          <th>Dadaab</th>
          <th>Combined</th>
        </thead>
        <tbody>
          #{
            _([
              "Verification"
              "Enrolled Students"
            ]).map (dataType) ->
              "
                <tr>
                  <td>#{dataType}</td>
                  <td>
                    <button id='#{dasherize(dataType)}-kakuma' class='mdl-button mdl-js-button mdl-button--fab mdl-button--colored'>
                      <i class='material-icons'>cloud_download</i>
                    </button>
                  </td>
                  <td>
                    <button id='#{dasherize(dataType)}-dadaab' class='mdl-button mdl-js-button mdl-button--fab mdl-button--colored'>
                      <i class='material-icons'>cloud_download</i>
                    </button>
                  </td>
                  <td>
                    <button id='#{dasherize(dataType)}-combined' class='mdl-button mdl-js-button mdl-button--fab mdl-button--colored'>
                      <i class='material-icons'>cloud_download</i>
                    </button>
                  </td>
                </tr>
              "
            .join ""
          }
        </tbody>
      </table>
    "
module.exports = ExportView
