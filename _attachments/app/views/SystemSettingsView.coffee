_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

Reports = require '../models/Reports'
Dialog = require './Dialog'

class SystemSettingsView extends Backbone.View
  el: "#content"

  render: =>
    countries = ['Zanzibar','Zimbabwe','Unites States']
    timezones = ['East Africa','America/NY']
    dateFormats = ['DD-MM-YYYY', 'MM-DD-YYYY', 'YYYY-MM-DD']
    @$el.html "
      <h4>Global System Settings</h4>
      <form id='system_settings'>
        <div class='mdl-select mdl-js-select mdl-select--floating-label setting_inputs'>
          <select class='mdl-select__input' id='assignedTo' name='assignedTo'>
            <option value=''></option>
            #{
              countries.map (country) =>
                "<option value='#{country}' #{if @issue?["Country"] is country then "selected='true'" else ""}>
                  #{country}
                 </option>"
              .join ""
            }
          </select>
          <label class='mdl-select__label' for='assignedTo'>Country</label>
        </div><br />
        <div class='mdl-select mdl-js-select mdl-select--floating-label setting_inputs'>
          <select class='mdl-select__input' id='assignedTo' name='assignedTo'>
            <option value=''></option>
            #{
              timezones.map (tzone) =>
                "<option value='#{tzone}' #{if @issue?["Time Zone"] is tzone then "selected='true'" else ""}>
                  #{tzone}
                 </option>"
              .join ""
            }
          </select>
          <label class='mdl-select__label' for='assignedTo'>Time Zone</label>
        </div><br />
        <div class='mdl-select mdl-js-select mdl-select--floating-label setting_inputs'>
          <select class='mdl-select__input' id='assignedTo' name='assignedTo'>
            <option value=''></option>
            #{
              dateFormats.map (dformat) =>
                "<option value='#{dformat}' #{if @issue?["Date Format"] is dformat then "selected='true'" else ""}>
                  #{dformat}
                 </option>"
              .join ""
            }
          </select>
          <label class='mdl-select__label' for='assignedTo'>Date Format</label>
        </div>
      </form>

    "
    Dialog.markTextfieldDirty()
    
    
module.exports = SystemSettingsView