_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

Reports = require '../models/Reports'
Dialog = require './Dialog'
Config = require '../models/Config'

class SystemSettingsView extends Backbone.View
  el: "#content"

  events:
    "click button#updateBtn": "updateConfig"
    
  updateConfig: (e) =>
    config = new Config
      _id: "coconut.config"
    config.fetch
      error: ->
        console.error error
        options.error()
      success: ->
        console.log(config)
        config.attributes.appName = $('#appName').val()
        config.attributes.appIcon = $('#appIcon').val()
        config.attributes.country = $('#country').val()
        config.attributes.timezone = $('#timeZone').val()
        config.attributes.dateFormat = $('#dateFormat').val()
        Config.saveConfig(config.attributes)   
    return false
    
  render: =>
    countries = ['Zanzibar','Zimbabwe','Unites States']
    timezones = ['East Africa','America/NY']
    dateFormats = ['DD-MM-YYYY', 'MM-DD-YYYY', 'YYYY-MM-DD']

    @$el.html "
      <h4>Global System Settings</h4>
      <form id='system_settings'>
        <div class='indent m-l-20'>
          <div class='mdl-textfield mdl-js-textfield mdl-textfield--floating-label setting_inputs'>
            <input class='mdl-textfield__input' type='text' id='appName' value='#{Coconut.config.appName}'>
            <label class='mdl-textfield__label' for='appName'>Application Title</label>
          </div> 
          <div class='mdl-textfield mdl-js-textfield mdl-textfield--floating-label setting_inputs'>
            <input class='mdl-textfield__input' type='text' id='appIcon' value='#{Coconut.config.appIcon}'>
            <label class='mdl-textfield__label' for='appIcon'>Application Icon File name</label>
          </div> 
          <div class='mdl-select mdl-js-select mdl-select--floating-label setting_inputs'>
            <select class='mdl-select__input' id='country' name='country'>
              <option value=''></option>
              #{
                countries.map (country) =>
                  "<option value='#{country}' #{if Coconut.config.country is country then "selected='true'" else ""}>
                    #{country}
                   </option>"
                .join ""
              }
            </select>
            <label class='mdl-select__label' for=country'>Country</label>
          </div><br />
          <div class='mdl-select mdl-js-select mdl-select--floating-label setting_inputs'>
            <select class='mdl-select__input' id='timeZone' name='timeZone'>
              <option value=''></option>
              #{
                timezones.map (tzone) =>
                  "<option value='#{tzone}' #{if Coconut.config.timezone is tzone then "selected='true'" else ""}>
                    #{tzone}
                   </option>"
                .join ""
              }
            </select>
            <label class='mdl-select__label' for='timeZone'>Time Zone</label>
          </div><br />
          <div class='mdl-select mdl-js-select mdl-select--floating-label setting_inputs'>
            <select class='mdl-select__input' id='dateFormat' name='dateFormat'>
              <option value=''></option>
              #{
                dateFormats.map (dformat) =>
                  "<option value='#{dformat}' #{if Coconut.config.dateFormat is dformat then "selected='true'" else ""}>
                    #{dformat}
                   </option>"
                .join ""
              }
            </select>
            <label class='mdl-select__label' for='dateFormat'>Date Format</label>
          </div>
        </div>
        <h4>Database Settings</h4>
        <div class='indent m-l-20'>
          <div class='mdl-textfield mdl-js-textfield mdl-textfield--floating-label setting_inputs'>
            <input class='mdl-textfield__input' type='text' id='design_doc_name' value='#{Coconut.config.cloud_database_name}'>
            <label class='mdl-textfield__label' for='design_doc_name'>Cloud Database Name</label>
          </div> 
          <div class='mdl-textfield mdl-js-textfield mdl-textfield--floating-label setting_inputs'>
            <input class='mdl-textfield__input' type='text' id='cloud' value='#{Coconut.config.cloud}'>
            <label class='mdl-textfield__label' for='cloud'>Cloud URL</label>
          </div>
          <div class='mdl-textfield mdl-js-textfield mdl-textfield--floating-label setting_inputs'>
            <input class='mdl-textfield__input' type='text' id='cloud_credentials' value='#{Coconut.config.cloud_credentials}'>
            <label class='mdl-textfield__label' for='cloud_credentials'>Cloud Credentials</label>
          </div>
          <div class='mdl-textfield mdl-js-textfield mdl-textfield--floating-label setting_inputs'>
            <input class='mdl-textfield__input' type='text' id='design_doc_name' value='#{Coconut.config.design_doc_name}'>
            <label class='mdl-textfield__label' for='design_doc_name'>Design Doc Name</label>
          </div>
        </div>
        <hr />
        <div id='dialogActions'>
         <button class='mdl-button mdl-js-button mdl-button--primary' id='updateBtn' type='submit' value='save'><i class='material-icons'>save</i> Update</button> &nbsp;
        </div>
      </form>
      
    "
    Dialog.markTextfieldDirty()
    
    
module.exports = SystemSettingsView