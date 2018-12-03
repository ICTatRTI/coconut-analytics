$ = require 'jquery'

Backbone = require 'backbone'
Backbone.$  = $

Dialog = require './Dialog'
dialogPolyfill = require 'dialog-polyfill'
CONST = require "../Constants"

class ChromeView extends Backbone.View

  el: '#log'

  events:
    "click button#OkBtn": "OkClicked"
    "click button#DownloadBtn": "DownloadClicked"

  OkClicked: ->
     aboutDialog.close() if aboutDialog.open

  DownloadClicked: ->
     aboutDialog.close() if aboutDialog.open
     window.open("https://www.google.com/chrome/browser/")

  render: =>
    @$el.html "
      <style>
        #acknowledgements { margin-top: 20px; font-weight: bold}
        a:active { outline: none;}
      </style>
      <dialog id='aboutDialog'>
        <div class='m-b-40'>
          <div id='dialog-title'>Optimized for Chrome</div>
        </div>
        <div id='recommendation'>
          <p> This software was designed and optimized for the Chrome browser. We cannot guarantee that it will work as well on other web browsers. Please consider downloading and installing Chrome for the best user experience.</p>
        </div><br />
        <div id='dialogActions'>
             <button class='mdl-button mdl-js-button mdl-button--primary' id='DownloadBtn'><i class='mdi mdi-cloud-download'></i> Download Chrome</button>
             <button class='mdl-button mdl-js-button mdl-button--primary' id='OkBtn' type='submit' ><i class='mdi mdi-checkbox-marked-circle-outline mdi-24px'></i> Continue</button>
        </div>
      </dialog>
    "
    dialogPolyfill.registerDialog(aboutDialog)
    $('button#OkBtn').focus()

    # Temporary hack for polyfill issue on non-chrome browsers
    if (Env.is_chrome)
       aboutDialog.showModal()
    else
       aboutDialog.show()

module.exports = ChromeView
