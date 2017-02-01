_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

Dialog = require './Dialog'
Dhis2 = require '../models/Dhis2'

class Dhis2View extends Backbone.View
  el: "#content"

  events:
    "click button#updateBtn": "update"
    "click button#test": "test"
    "click button#send": "send"
    
  render: =>

    @fields = {
      dhis2Url: "Dhis2 URL"
      dhis2username: "Dhis2 Username"
      dhis2password: "Dhis2 Password"
      programId: "Program Id"
      malariaCaseEntityId: "Malaria Case Entity Id"
      caseIdAttributeId: "Case Id Attribute Id"
      ageAttributeId: "Age Attribute Id"
    }
    HTMLHelpers.ChangeTitle("Admin: DHIS2")
    @$el.html "
      <form id='system_settings'>
      <h4>DHIS2</h4>
      #{
        _(@fields).map (fieldName, fieldId) ->
          "
          <div class='mdl-textfield mdl-js-textfield mdl-textfield--floating-label setting_inputs'>
            <input class='mdl-textfield__input' type='text' id='#{fieldId}' value=''>
            <label class='mdl-textfield__label' for='#{fieldId}'>#{fieldName}</label>
          </div> 
          "
        .join ""
      }
      <div id='dialogActions'>
       <button class='mdl-button mdl-js-button mdl-button--primary' id='updateBtn' type='button'><i class='material-icons'>save</i> Update Settings</button> &nbsp;
       <button class='mdl-button mdl-js-button mdl-button--primary' id='test' type='button'><i class='material-icons'>cloud_done</i> Test Settings</button> &nbsp;
       <button class='mdl-button mdl-js-button mdl-button--primary' id='send' type='button'><i class='material-icons'>sync</i>Send Cases For Last 30 Days</button> &nbsp;
      </div>
    "
    @load()

    Dialog.markTextfieldDirty()
    # This is for MDL switch
    componentHandler.upgradeAllRegistered()

  load: =>
    Coconut.database.get "dhis2"
    .then (result) =>
      @dhis2Doc = result
      _(@fields).each (fieldName, fieldId) ->
        if result[fieldId]
          $("##{fieldId}").val result[fieldId]
            .parent().addClass "is-dirty"
    .catch (error) ->
  
  test: =>
    dhis2 = new Dhis2
      dhis2Url: $("#dhis2Url").val()
      username: $("#dhis2username").val()
      password: $("#dhis2password").val()
      programId: $("#programId").val()
      malariaCaseEntityId: $("#malariaCaseEntityId").val()
      caseIdAttributeId: $("#caseIdAttributeId").val()
      ageAttributeId: $("#ageAttributeId").val()
    dhis2.test
      error: (error) ->
        Dialog.createDialogWrap()
        Dialog.confirm("Test Error: #{JSON.stringify error}", 'Test DHIS Connection',['Ok'])
      success: ->
        Dialog.createDialogWrap()
        Dialog.confirm("Test Succeeded", 'Test DHIS Connection',['Ok'])

  update: =>
    @dhis2Doc = {_id: "dhis2", isApplicationDoc: true} unless @dhis2Doc
    _(@fields).each (fieldName, fieldId) =>
      @dhis2Doc[fieldId] = $("##{fieldId}").val()

    Coconut.database.put @dhis2Doc
    .then (result) ->
      Coconut.dhis2 = new Dhis2()
      Coconut.dhis2.loadFromDatabase()
      Dialog.createDialogWrap()
      Dialog.confirm("Dhis2 Configuration has been saved.", 'System Settings',['Ok'])

  send: =>
    Coconut.database.query "caseIDsByDate",
      # Note that these seem reversed due to descending order
      startkey: moment().subtract(1,"month").format("YYYY-MM-DD")
      endkey: moment().format("YYYY-MM-DD")
      include_docs: false
    .catch (error) -> console.error error
    .then (result) ->
      Case.getCases
        caseIDs: _.unique(_.pluck result.rows, "value")
        error: (error) -> console.error error
        success: (cases) ->
          numberCasesToSend = cases.length
          console.log "Sending: #{numberCasesToSend} cases"
          numberCasesSent = 0
          numberCasesNotSent = 0
          casesNotSentErrors = ""
          processCasesSynchronously = ->
            console.log cases.length
            if cases.length > 0
              malariaCase = cases.pop()
              malariaCase.createOrUpdateOnDhis2
                error: (error) ->
                  console.error "Error processing case #{malariaCase.caseId()}, proceeding to next case: #{error}"
                  numberCasesNotSent += 1
                  casesNotSentErrors += error + "<br/>"
                  processCasesSynchronously()
                success: ->
                  numberCasesSent += 1
                  processCasesSynchronously()
            else
              Dialog.createDialogWrap()
              message = "#{numberCasesSent} cases sent to DHIS2<br/>"
              if numberCasesNotSent > 0
                message +="#{numberCasesNotSent} cases that were unable to be sent:<br/>#{casesNotSentErrors}"
              Dialog.confirm(message, 'Send Complete',['Ok'])

          processCasesSynchronously()


module.exports = Dhis2View
