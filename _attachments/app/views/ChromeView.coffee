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
  
  OkClicked: ->
     aboutDialog.close()
 
  render: =>
    @$el.html "
      <style>
        #acknowledgements { margin-top: 20px; font-weight: bold}
        a:active { outline: none;}
      </style>
      <dialog id='aboutDialog'>
        <div class='m-b-40'>
          <div id='dialog-title'>Browser Check</div>
        </div>
        <div id='recommendation'>
          <p> We detected that you are not using the Chrome browser. <br />
          This software was designed and optimized for the Chrome browser. Hence we recommend that you use 
          Chrome for a better user experience. You can download Chrome at this link:</p> 
          <div><a target='_blank' href='https://www.google.com/chrome/browser/'>Download Chrome</a></div><br />
        </div><br />
        <div id='dialogActions'>
             <button class='mdl-button mdl-js-button mdl-button--primary' id='OkBtn' type='submit' ><i class='material-icons'>done</i> Continue</button>
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
