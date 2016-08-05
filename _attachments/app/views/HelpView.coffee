$ = require 'jquery'

Backbone = require 'backbone'
Backbone.$  = $

Dialog = require './Dialog'
dialogPolyfill = require 'dialog-polyfill'
CONST = require "../Constants"

class HelpView extends Backbone.View

  el: '#log'

  events: 
    "click button#OkBtn": "OkClicked"
  
  OkClicked: ->
     aboutDialog.close()
 
  render: =>
    @$el.html "
      <style>
        #acknowledgements { margin-top: 20px; font-weight: bold}
      </style>
      <dialog id='aboutDialog'>
        <div class='m-b-40'>
          <div class='f-left'><img src='images/cocoLogo.png' id='cslogo_xsm'></div>
          <div id='dialog-title'>#{Coconut.config.appName}</div>
        </div>
        <h5>Application Help<h5>
        <div id='help_content'>
          <p>
          Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore 
          magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo 
          consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. 
          Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
          </p>
          <p>
          Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, 
          eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim ipsam 
          voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione 
          voluptatem sequi nesciunt. Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci 
          velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam quaerat voluptatem. Ut enim 
          ad minima veniam, quis nostrum exercitationem ullam corporis suscipit laboriosam, nisi ut aliquid ex ea commodi 
          consequatur? Quis autem vel eum iure reprehenderit qui in ea voluptate velit esse quam nihil molestiae consequatur, 
          vel illum qui dolorem eum fugiat quo voluptas nulla pariatur?
          </p>
        </div>
        <div id='dialogActions'>
             <button class='mdl-button mdl-js-button mdl-button--primary' id='OkBtn' type='submit' ><i class='material-icons'>done</i> Ok</button>
        </div> 
      </dialog>
    "
    dialogPolyfill.registerDialog(aboutDialog)
    
    # Temporary hack for polyfill issue on non-chrome browsers
    if (Env.is_chrome)
       aboutDialog.showModal()
    else
       aboutDialog.show()

module.exports = HelpView
