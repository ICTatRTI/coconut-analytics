$ = require 'jquery'

Backbone = require 'backbone'
Backbone.$  = $

Form2js = require 'form2js'
Dialog = require './Dialog'
User = require '../models/User'
dialogPolyfill = require 'dialog-polyfill'

class LoginView extends Backbone.View

  el: '#login-backgrd'

  events:
    "click button#btnLogin": "login"
    "keypress #passWord": "submitIfEnter"

  render: =>
    $("#login-backgrd").show()
    @$el.html "
      <style>
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
           <div class='mdl-textfield mdl-js-textfield mdl-textfield--floating-label'>
               <input class='mdl-textfield__input' type='text' id='userName' name='userName' autofocus style='text-transform:lowercase;' on keyup='javascript:this.value=this.value.toLowerCase()'>
               <label class='mdl-textfield__label' for='userName'>Username*</label>
           </div>

           <div class='mdl-textfield mdl-js-textfield mdl-textfield--floating-label'>
             <input class='mdl-textfield__input' type='password' id='passWord' name='passWord'>
             <label class='mdl-textfield__label' for='passWord'>Password*</label>
           </div>
           <div class='coconut-mdl-card__title'></div>
          <div id='dialogActions'>
             <button class='mdl-button mdl-js-button mdl-button--primary' id='btnLogin' type='submit' ><i class='material-icons'>lock_open</i> Login</button>
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

  submitIfEnter: (event) ->
    @login() if event.which == 10 or event.which == 13
      
  login: () =>
    view = @
    loginData = {
      userName: $('#userName').val().toLowerCase()
      passWord: $('#passWord').val()
    }
    # Useful for reusing the login screen - like for database encryption
    if $("#userName").val() is "" or $("#passWord").val() is ""
      view.displayErrorMsg('Please enter both username and password.')
      return false

    User.login
      username: loginData.userName
      password: loginData.passWord
      success: =>
        $("#login-backgrd").hide()
        view.trigger "success"

      error: (error) ->
        view.render()
        $('#userName').val(loginData.userName)
        $('#passWord').val(loginData.passWord)
        view.displayErrorMsg('Invalid username/password.')
        Dialog.markTextfieldDirty()
        console.log("Wrong credentials")
        
  module.exports = LoginView
