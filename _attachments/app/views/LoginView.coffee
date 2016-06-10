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
    "click a#forgot_passwd": "ForgotPassword"
    "click button#resetPwd": "ResetPassword"
    "click button#toLogin": "ToLogin"

  render: =>
    $("#login-backgrd").show()
    @$el.html "
      <dialog id='loginDialog'>
        <form id='loginForm' method='dialog'>
           <div class='m-b-20'>
             <div class='f-left'><img src='images/cocoLogo.png' id='cslogo_xsm'></div>
             <div id='dialog-title'>#{Coconut.config.appName}</div>
           </div>
           <div class='mdl-textfield mdl-js-textfield mdl-textfield--floating-label'>
               <input class='mdl-textfield__input' type='text' id='userName' name='userName' autofocus style='text-transform:lowercase;' on keyup='javascript:this.value=this.value.toLowerCase()'>
               <label class='mdl-textfield__label' for='userName'>Username*</label>
           </div>

           <div class='mdl-textfield mdl-js-textfield mdl-textfield--floating-label' id='passwordInput'>
             <input class='mdl-textfield__input' type='password' id='passWord' name='passWord'>
             <label class='mdl-textfield__label' for='passWord'>Password*</label>
           </div>
           <div class='coconut-mdl-card__title'></div>
           <div id='forgotten'><a href='#' id='forgot_passwd'>Forgot my password</a></div>
          <div id='dialogActions'>
             <button class='mdl-button mdl-js-button mdl-button--primary' id='btnLogin' type='submit' ><i class='material-icons'>lock_open</i> Login</button>
             <button class='mdl-button mdl-js-button mdl-button--primary' id='resetPwd' type='submit' ><i class='material-icons'>vpn_key</i> Reset Password</button>
             <button class='mdl-button mdl-js-button mdl-button--primary' id='toLogin' type='submit' ><i class='material-icons'>lock_open</i> Back To Login</button>
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
    
  displayErrorMsg: (msg, icon) ->
    errMsg = @$el.find('.coconut-mdl-card__title')[0]
    $(errMsg).show()
    $(errMsg).html "<i class='material-icons'>#{icon}</i> #{msg}"

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
      view.displayErrorMsg('Please enter both username and password.', 'error_outline')
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
        view.displayErrorMsg('Invalid username/password.','error_outline')
        Dialog.markTextfieldDirty()
        console.log("Wrong credentials")

  ForgotPassword: () ->
    $('div#passwordInput').hide()
    $('a#forgot_passwd').hide()
    $('button#btnLogin').hide()
    $('.coconut-mdl-card__title').hide()
    $('button#resetPwd').show()
    return false

  ResetPassword: () ->
    view = @    
    username = $("#userName").val()
    if username is ""
      view.displayErrorMsg('Please enter your username...', 'error_outline')
    else
      id = "user.#{username}"
      Coconut.database.get id,
         include_docs: true
      .then (user) =>
        #TODO: Sends email with password reset link and token. Token needs to be generated.
        view.displayErrorMsg('Reset Password email has been sent...','beenhere')
        $('a#forgot_passwd').hide()
        $('button#resetPwd').hide()
        $('button#toLogin').show()
      .catch (error) => 
        view.displayErrorMsg('Invalid username...','error_outline')
        console.error error
    return false
    
  ToLogin: () =>
    @render()
    
  module.exports = LoginView
