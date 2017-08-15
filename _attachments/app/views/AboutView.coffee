$ = require 'jquery'

Backbone = require 'backbone'
Backbone.$  = $

Dialog = require './Dialog'
dialogPolyfill = require 'dialog-polyfill'
CONST = require "../Constants"

class AboutView extends Backbone.View

  el: '#log'

  events:
    "click button#OkBtn": "OkClicked"

  OkClicked: ->
     aboutDialog.close() if aboutDialog.open

  render: =>
    @$el.html "
      <style>
        #acknowledgements { margin-top: 20px; font-weight: bold}
        a:active { outline: none;}
      </style>
      <dialog id='aboutDialog'>
        <div class='m-b-40'>
          <div class='f-left'><img src='images/cocoLogo.png' id='cslogo_xsm'></div>
          <div id='dialog-title'>#{Coconut.config.appName}</div>
        </div>
        <div id='version'>Version #{CONST.Version}</div>
        <div id='license'>
          <p><i class='mdi mdi-copyright mdi-24px'></i> Copyright 2012 RTI International. </p>
          <p>RTI International is a registered trademark and a trade name of Research Triangle Institute.</p>
          <div>Licensed under the Apache License, Version 2.0 (the 'License');<br />
          you may not use this file except in compliance with the License.<br />
          You may obtain a copy of the License at</div><br />
          <div><a target='_blank' href='http://www.apache.org/licenses/LICENSE-2.0'>http://www.apache.org/licenses/LICENSE-2.0</a></div><br />
          <div>Unless required by applicable law or agreed to in writing, software<br />
          distributed under the License is distributed on an 'AS IS' BASIS,<br />
          WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
        </div><br />
        <div>See the License for the specific language governing permissions and<br />
          limitations under the License.
        </div>
        <div id='acknowledgements'>Acknowledgements and Credits</div>
        <div>The development of Coconut Surveillance has been funded by RTI International and the U.S. President’s
Malaria Initiative. Coconut Surveillance has been developed in close collaboration with the Zanzibar Malaria Elimination Programme.</div>
        <div id='dialogActions'>
             <button class='mdl-button mdl-js-button mdl-button--primary' id='OkBtn' type='submit' ><i class='mdi mdi-check mdi-24px'></i> Ok</button>
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

module.exports = AboutView
