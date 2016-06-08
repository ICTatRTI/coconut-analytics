$ = require 'jquery'

Backbone = require 'backbone'
Backbone.$  = $

Dialog = require './Dialog'
User = require '../models/User'
dialogPolyfill = require 'dialog-polyfill'

class ChangePasswordView extends Backbone.View

  el: '#login-backgrd'

  events:
    "click button#btnSubmit": "ResetPassword"

  render: =>
    $("#login-backgrd").show()
    @$el.html "
      <style>
        #forgotten {
           padding-top: 20px;
           float: left;
        }
        
        #dialog + .backdrop {
          position: fixed;
          top: 0;
          left: 0;
          right: 0;
          bottom: 0;
          background-color: rgba(0, 0, 0, 0.4);
        }

        #dialog::backdrop {
          position: fixed;
          top: 0;
          left: 0;
          right: 0;
          bottom: 0;
          background-color: rgba(0, 0, 0, 0.4);
        }
        #loginDialog {
          top: 20%;
        }
      </style>
      <dialog id='loginDialog'>
        <form id='loginForm' method='dialog'>
           <div class='m-b-20'>
             <div class='f-left'><img src='images/cocoLogo.png' id='cslogo_xsm'></div>
             <div id='dialog-title'>Coconut Plus</div>
           </div>
           <h5>Reset Password</h5>
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
             <button class='mdl-button mdl-js-button mdl-button--primary' id='btnSubmit' type='submit' ><i class='material-icons'>loop</i> Submit</button>
             <button class='mdl-button mdl-js-button mdl-button--primary' id='toLogin' type='submit' ><i class='material-icons'>open_lock</i> Back to Login</button>
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
    $(errMsg).html "<i class='material-icons'>error_outline</i> #{msg}"


  ResetPassword: () ->
    view = @
    newPass = $("#newPass").val()
    confirmPass = $("#confirmPass").val()
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
        Coconut.database.get id,
           include_docs: true
        .then (user) =>
          view.displayErrorMsg('Password has been reset.')
          $('button#btnSubmit').hide()
          $('button#toLogin').show()
          view.trigger "success"
        .catch (error) => 
          view.displayErrorMsg('Error encountered resetting password...')
          console.error error
        
    return false

  module.exports = ChangePasswordView
