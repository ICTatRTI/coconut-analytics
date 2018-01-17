_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

Dialog = require './Dialog'
Config = require '../models/Config'
CONST = require '../Constants'

class SystemSettingsView extends Backbone.View
  el: "#content"

  events:
    "click button#updateBtn": "updateConfig"
    "change #logoImage": "updateFileName"
    "click #appIcon": "showImage"

  updateFileName: (e) =>
    #document.getElementById('appIcon').value = this.files[0].name
    filename = $(e.target)[0].files[0].name
    $('#appIcon').val(filename)

  showImage: (e) ->
    Dialog.createDialogWrap()
    Config.getLogoUrl()
    .then (url) ->
      img = document.createElement('img')
      img.src = url
      Dialog.confirm("", Coconut.config.appIcon,['Close'])
      $('#alertText').html(img)
    .catch (error) ->
      console.error error
    return false

  updateConfig: (e) =>
    Coconut.database.get(Coconut.config._id)
    .then (doc) ->
      fields = ['appName','appIcon','country','timezone','dateFormat','graphColorScheme','cloud_database_name','cloud',
        'cloud_credentials','design_doc_name','role_types','case_notification','case_followup','case_focus_investigation',
        'location_accuracy_threshold','mobile_background_sync','mobile_background_sync_freq']
      _(fields).map (field) =>
        doc["#{field}"] = $("##{field}").val()
      getFile = $('#logoImage')[0].files[0]
      if getFile != undefined
        doc._attachments = {
          "#{doc.appIcon}":
            type: getFile.type
            data: getFile
        }
      doc.facilitiesEdit = $('#facilitiesEdit').prop('checked')
      doc.mobile_background_sync = $('#mobile_background_sync').prop('checked')
      return Coconut.database.put(doc)
        .catch (error) ->
          console.error error
          Dialog.errorMessage(error)
          return false
        .then (response) ->
          Dialog.createDialogWrap()
          Dialog.confirm("Configuration has been saved.", 'System Settings',['Ok'])
          dialog.addEventListener 'close', ->
            location.reload(true)
          return false
    .catch (error) ->
      console.error error
      Dialog.errorMessage(error)
      return false


  render: =>
    countries = _.pluck(CONST.Countries, 'name')
    timezones = _.pluck(CONST.Timezones,'DisplayName')
    dateFormats = CONST.dateFormats
    colorSchemes = CONST.graphColorSchemes
    HTMLHelpers.ChangeTitle("Admin: System Settings")
    @$el.html "
      <form id='system_settings'>
      <div class='mdl-grid'>
        <div class='mdl-cell mdl-cell--6-col mdl-cell--4-col-tablet mdl-cell--2-col-phone'>
          <h4>Global System Settings</h4>
            <div class='indent m-l-20'>
              <div class='mdl-textfield mdl-js-textfield mdl-textfield--floating-label setting_inputs'>
                <input class='mdl-textfield__input' type='text' id='appName' value='#{Coconut.config.appName}'>
                <label class='mdl-textfield__label' for='appName'>Application Title</label>
              </div>
              <div class='mdl-textfield mdl-js-textfield mdl-textfield--floating-label mdl-textfield--file setting_inputs'>
                <input class='mdl-textfield__input' placeholder='Application logo' type='text' id='appIcon' value='#{Coconut.config.appIcon}' title='Click to view image' readonly/>
                <div class='mdl-button mdl-button--primary mdl-button--icon mdl-button--file'>
                  <i class='mdi mdi-paperclip mdi-24px'></i>
                  <input type='file' id='logoImage'>
                </div>
                <label class='mdl-textfield__label' for='appName'>Application Logo (recommended size: 70 x 55 px )</label>
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
                <select class='mdl-select__input' id='timezone' name='timezone'>
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
              </div><br />
              <div class='mdl-select mdl-js-select mdl-select--floating-label setting_inputs'>
                <select class='mdl-select__input' id='graphColorScheme' name='graphColorScheme'>
                  <option value=''></option>
                  #{
                    colorSchemes.map (cscheme) =>
                      "<option value='#{cscheme}' #{if Coconut.config.graphColorScheme is cscheme then "selected='true'" else ""}>
                        #{cscheme}
                       </option>"
                    .join ""
                  }
                </select>
                <label class='mdl-select__label' for='graphColorScheme'>Graph Color Scheme</label>
              </div><br />
              <label class='mdl-switch mdl-js-switch mdl-js-ripple-effect' for='facilitiesEdit' id='switch-1'>
                <input type='checkbox' id='facilitiesEdit' class='mdl-switch__input' #{if Coconut.config.facilitiesEdit then 'checked'}>
                <span class='mdl-switch__label facilities_editable'>Facilities Editable</span>
              </label>
            </div>
        </div>
        <div class='mdl-cell mdl-cell--6-col mdl-cell--4-col-tablet mdl-cell--2-col-phone'>
          <h4>Database Settings</h4>
          <div class='indent m-l-20'>
            <div class='mdl-textfield mdl-js-textfield mdl-textfield--floating-label setting_inputs'>
              <input class='mdl-textfield__input' type='text' id='cloud_database_name' value='#{Coconut.config.cloud_database_name}'>
              <label class='mdl-textfield__label' for='cloud_database_name'>Cloud Database Name</label>
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
            <div class='mdl-textfield mdl-js-textfield mdl-textfield--floating-label setting_inputs'>
              <input class='mdl-textfield__input' type='text' id='role_types' value='#{Coconut.config.role_types}'>
              <label class='mdl-textfield__label' for='role_types'>Role Types</label>
            </div>
          </div>
        </div>
      </div>
      <div class='mdl-grid'>
        <div class='mdl-cell mdl-cell--6-col mdl-cell--4-col-tablet mdl-cell--2-col-phone'>
        </div>
        <div class='mdl-cell mdl-cell--6-col mdl-cell--4-col-tablet mdl-cell--2-col-phone'>
           <h4>Map Settings</h4>
           <div class='indent m-l-20'>
             <div class='mdl-textfield mdl-js-textfield mdl-textfield--floating-label setting_inputs'>
               <input class='mdl-textfield__input' type='text' pattern='[0-9]*' id='location_accuracy_threshold' value='#{Coconut.config.location_accuracy_threshold}'>
               <label class='mdl-textfield__label' for='location_accuracy_threshold'> Location Accuracy Threshold (in meters)</label>
               <span class='mdl-textfield__error'>Only positive integer allowed.</span>
             </div>
           </div>
        </div>
      </div>
      <div class='mdl-grid'>
        <div class='mdl-cell mdl-cell--6-col mdl-cell--4-col-tablet mdl-cell--2-col-phone'>
          <h4>Coconut Mobile Settings</h4>
          <div class='indent m-l-20'>
            <div class='mdl-textfield mdl-js-textfield mdl-textfield--floating-label setting_inputs'>
              <label class='mdl-switch mdl-js-switch mdl-js-ripple-effect' for='mobile_background_sync' id='switch_2'>
                <input type='checkbox' id='mobile_background_sync' class='mdl-switch__input' #{if Coconut.config.mobile_background_sync then 'checked'}>
                <span class='mdl-switch__label facilities_editable'>Background Sync</span>
              </label>
            </div>
            <div class='mdl-textfield mdl-js-textfield mdl-textfield--floating-label setting_inputs'>
              <input class='mdl-textfield__input' type='text' pattern='[0-9]*' id='mobile_background_sync_freq' value='#{Coconut.config.mobile_background_sync_freq}'>
              <label class='mdl-textfield__label' for='mobile_background_sync_freq'> Background Sync Frequency (in minutes)</label>
              <span class='mdl-textfield__error'>Only positive integer allowed.</span>
            </div>
          </div>
        </div>
        <div class='mdl-cell mdl-cell--6-col mdl-cell--4-col-tablet mdl-cell--2-col-phone'>
        </div>
      </div>
      <hr />
      <div id='dialogActions-left'>
       <button class='mdl-button mdl-js-button mdl-button--primary' id='updateBtn' type='button' value='save'><i class='mdi mdi-content-save mdi-24px'></i> Update</button> &nbsp;
      </div>
      </form>
    "
    Dialog.markTextfieldDirty()
    # This is for MDL switch
    componentHandler.upgradeAllRegistered()

module.exports = SystemSettingsView
