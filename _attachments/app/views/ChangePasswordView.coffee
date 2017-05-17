$ = require 'jquery'

Backbone = require 'backbone'
Backbone.$  = $

Dialog = require './Dialog'
User = require '../models/User'
dialogPolyfill = require 'dialog-polyfill'
bcrypt = require('bcryptjs')
CONST = require "../Constants"

class ChangePasswordView extends Backbone.View

  el: '#login-backgrd'

  events:
    "click button#btnSubmit": "ResetPassword"

  render: (username)=>
    $("#login-backgrd").show()
    @$el.html "
      <dialog id='loginDialog'>
        <form id='loginForm' method='dialog'>
           <div class='m-b-20'>
             <div class='f-left'><img src='images/cocoLogo.png' id='cslogo_xsm'></div>
             <div id='dialog-title'>Coconut Plus</div>
           </div>
           <h5>Reset Password</h5>
           <input id='username' type='hidden' value='#{username}' name='username'>
           <div class='mdl-textfield mdl-js-textfield mdl-textfield--floating-label'>
               <input class='mdl-textfield__input' type='password' id='newPass' name='newPass' autofocus>
               <label class='mdl-textfield__label' for='newPass'>New Password*</label>
           </div>

           <div class='mdl-textfield mdl-js-textfield mdl-textfield--floating-label'>
             <input class='mdl-textfield__input' type='password' id='confirmPass' name='confirmPass'>
             <label class='mdl-textfield__label' for='confirmPass'>Confirm Password*</label>
           </div>
           <div class='coconut-mdl-card__title'></div>
          <div id='dialogActions'>
             <button class='mdl-button mdl-js-button mdl-button--primary' id='btnSubmit' type='submit' ><i class='mdi mdi-check-circle mdi-24px'></i> Submit</button>
             <button class='mdl-button mdl-js-button mdl-button--primary' id='toLogin' type='submit' ><i class='mdi mdi-login mdi-24px'></i> Back to Login</button>
          </div>
        </form>
      </dialog>
    "
    dialogPolyfill.registerDialog(loginDialog)
    componentHandler.upgradeAllRegistered()

    # Temporary hack for polyfill issue on non-chrome browsers
    if (Env.is_chrome)
       loginDialog.showModal()
    else
       loginDialog.show()

    componentHandler.upgradeDom()

  displayErrorMsg: (msg) ->
    errMsg = @$el.find('.coconut-mdl-card__title')[0]
    $(errMsg).html "<i class='mdi mdi-information-outline mdi-24px'></i> #{msg}"


  ResetPassword: () ->
    view = @
    newPass = $("#newPass").val()
    confirmPass = $("#confirmPass").val()
    username = $("input#username").val()
    if newPass is "" or confirmPass is ""
      view.displayErrorMsg('Both passwords are required.')
      return false
    else
      if newPass != confirmPass
        view.displayErrorMsg('Passwords not matching. Please retry')
        return false
      else
        # TODO: codes to reset password in User model?
        id = "user.#{username}"
        hash = bcrypt.hashSync newPass, CONST.SaltRounds
        Coconut.database.get id,
           include_docs: true
        .catch (error) =>
          view.displayErrorMsg('Error encountered resetting password...')
          console.error error
        .then (user) =>
          user.hash = hash
          Coconut.database.put user
          .catch (error) -> console.error error
          .then =>
            loginDialog.close()
            view.trigger "success"

    return false

  module.exports = ChangePasswordView
