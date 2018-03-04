$ = require 'jquery'

Backbone = require 'backbone'
Backbone.$  = $

Form2js = require 'form2js'
Dialog = require './Dialog'
User = require '../models/User'
dialogPolyfill = require 'dialog-polyfill'

class ChangePasswdView extends Backbone.View

  el: "#content"

  events:
    "click button#btnSubmit": "ChangePass"
    "click button#btnCancel": "CancelAction"

  CancelAction: ->
    window.history.back()

  render: =>
    @$el.html "
      <dialog id='passwdDialog'>
        <form id='passwdForm' method='dialog'>
           <div class='m-b-20'>
             <div class='f-left'><img src='images/cocoLogo.png' id='cslogo_xsm'></div>
             <div id='dialog-title'>#{Coconut.config.appName}</div>
           </div>
           <div class='mdl-textfield mdl-js-textfield mdl-textfield--floating-label'>
               <input class='mdl-textfield__input' type='password' id='currentPass' name='currentPass' autofocus style='text-transform:lowercase;' onkeyup='javascript:this.value=this.value.toLowerCase()' />
               <label class='mdl-textfield__label' for='userName'>Current Password*</label>
           </div>

           <div class='mdl-textfield mdl-js-textfield mdl-textfield--floating-label' id='passwordInput'>
             <input class='mdl-textfield__input' type='password' id='newPasswd' name='newPasswd'>
             <label class='mdl-textfield__label' for='newPassWord'>New Password*</label>
           </div>
           <div class='mdl-textfield mdl-js-textfield mdl-textfield--floating-label' id='passwordInput'>
             <input class='mdl-textfield__input' type='password' id='confirmPasswd' name='confirmPasswd'>
             <label class='mdl-textfield__label' for='confirmPasswd'>Re-enter New Password*</label>
           </div>
           <div class='coconut-mdl-card__title'></div>
          <div id='dialogActions'>
             <button class='mdl-button mdl-js-button mdl-button--primary' id='btnSubmit' type='submit' ><i class='mdi mdi-lock-open-outline mdi-24px'></i> Submit</button>
             <button class='mdl-button mdl-js-button mdl-button--primary' id='btnCancel' type='submit' ><i class='mdi mdi-close-circle mdi-24px'></i> Cancel</button>
          </div>
        </form>
      </dialog>
    "
    dialogPolyfill.registerDialog(passwdDialog)
    componentHandler.upgradeAllRegistered()

    # Temporary hack for polyfill issue on non-chrome browsers
    if (Env.is_chrome)
       passwdDialog.showModal()
    else
       passwdDialog.show()

    componentHandler.upgradeDom()

  displayErrorMsg: (msg, icon) ->
    errMsg = @$el.find('.coconut-mdl-card__title')[0]
    $(errMsg).show()
    $(errMsg).html "<i class='mdi mdi-#{icon} mdi-24px'></i> #{msg}"

  ChangePass: () =>
    view = @
    passwdData = {
      currentPass: $('#currentPass').val()
      newPasswd: $('#newPasswd').val()
      confirmPasswd: $('#confirmPasswd').val()
    }

    if $("#currentPass").val() is "" or $("#newPassWord").val() is "" or $("#confirmPasswd").val() is ""
      view.displayErrorMsg('All inputs are required.', 'information-outline')
      return false
    else
      if $("#newPasswd").val() isnt $("#confirmPasswd").val()
        view.displayErrorMsg('New password and confirm password do not match', 'information-outline')
        return false

    User.changePass
      currentPass: passwdData.currentPass
      newPasswd: passwdData.newPasswd
      success: =>
        view.trigger "success"
      error: (error) ->
        console.log(passwdData)
        view.render()
        $('#currentPass').val(passwdData.currentPass)
        $('#newPasswd').val(passwdData.newPasswd)
        $('#confirmPasswd').val(passwdData.confirmPasswd)
        view.displayErrorMsg(error,'error_outline')
        Dialog.markTextfieldDirty()

  module.exports = ChangePasswdView
