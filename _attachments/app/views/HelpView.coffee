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
          <p>Need help with Coconut Surveillance?</p>
          
          <p>The best place to start may be the <a target='_blank' href='http://docs.coconutsurveillance.org'>Coconut Surveillance documentation</a> website. There you will find information 
          about deploying the system, using the mobile and analytics applications, and the software technology behind the System.
          Documentation can also be downloaded from this website in PDF format for use offline.</p>
          
          <p>Still need help? Visit the <a target='_blank' href='http://talk.coconutsurveillance.org'>Coconut Surveillance Community</a> to search for answers or to post a question to the 
          community.</p>
          
          <p>Need expert technical assistance, help considering a new deployment, or have a great idea for collaboration? 
          <a href='mailto:coconutsurveillance@rti.org'>Contact us</a> to discuss your needs and your ideas.</p>
        </div>
        <div id='dialogActions'>
             <button class='mdl-button mdl-js-button mdl-button--primary' id='OkBtn' type='submit' autofocus='autofocus'><i class='material-icons'>done</i> Ok</button>
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
