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
       <button class='mdl-button mdl-js-button mdl-button--primary' id='test' type='button'><i class='material-icons'>test</i> Test</button> &nbsp;
       <button class='mdl-button mdl-js-button mdl-button--primary' id='updateBtn' type='button'><i class='material-icons'>sync</i> Update</button> &nbsp;
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
    dhis2.test()

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

module.exports = Dhis2View
