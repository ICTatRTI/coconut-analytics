$ = require 'jquery'

Backbone = require 'backbone'
Backbone.$  = $

Form2js = require 'form2js'

User = require '../models/User'
dialogPolyfill = require 'dialog-polyfill'

class LoginView extends Backbone.View

  el: '#content'

  events:
    "click button#btnLogin": "login"
    "keypress #passWord": "submitIfEnter"

  render: =>
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
      </style>
      <dialog id='dialog'>
        <form id='loginForm' method='dialog'>
           <div id='dialog-title'>LOGIN </div>
           <div class='coconut-mdl-card__title'></div>
           <div class='mdl-textfield mdl-js-textfield mdl-textfield--floating-label'>
               <input class='mdl-textfield__input' type='text' id='userName' name='userName' autofocus style='text-transform:lowercase;' on keyup='javascript:this.value=this.value.toLowerCase()'>
               <label class='mdl-textfield__label' for='userName'>Username*</label>
           </div>

           <div class='mdl-textfield mdl-js-textfield mdl-textfield--floating-label'>
             <input class='mdl-textfield__input' type='password' id='passWord' name='passWord'>
             <label class='mdl-textfield__label' for='passWord'>Password*</label>
           </div>

          <div id='dialogActions'>
             <button class='mdl-button mdl-js-button mdl-button--primary' id='btnLogin' type='submit' ><i class='material-icons'>lock_open</i> Login</button>
          </div> 
        </form>
      </dialog>
    "
    dialogPolyfill.registerDialog(dialog)
    # Temporary hack for polyfill issue on non-chrome browsers
    if (Env.is_chrome)
       dialog.showModal()
    else
       dialog.show()
    componentHandler.upgradeDom()

  submitIfEnter: (event) ->
    @login() if event.which == 10 or event.which == 13

  login: (callback) =>
    # Useful for reusing the login screen - like for database encryption
    if $("#userName").val() is "" or $("#passWord").val() is ""
      $('.coconut-mdl-card__title').html "<i class='material-icons'>error_outline</i> Please enter both username and password."
      return false

    loginData = Form2js.form2js('loginForm')
    loginData.userName = loginData.userName.toLowerCase()
    
    User.login
      username: loginData.userName
      password: loginData.passWord
      success: =>
        Coconut.router.navigate('dashboard', true)
      error: =>
        $('.coconut-mdl-card__title').html "<i class='material-icons'>error_outline</i> Invalid username/password."
   

  module.exports = LoginView
