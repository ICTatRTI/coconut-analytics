$ = require 'jquery'

Backbone = require 'backbone'
Backbone.$  = $

Dialog = require './Dialog'
dialogPolyfill = require 'dialog-polyfill'
CONST = require "../Constants"

class ChangeLogView extends Backbone.View

  el: '#log'

  events: 
    "click button#OkClickBtn, button#closeBtn": "OkClicked"
  
  OkClicked: ->
     changeLogDialog.close()
 
  render: =>
    @$el.html "
      <style>
        #acknowledgements { margin-top: 20px; font-weight: bold}
      </style>
      <dialog id='changeLogDialog'>
        <div class='f-right'>
             <button class='mdl-button mdl-js-button mdl-button--primary' id='closeBtn' type='submit' ><i class='material-icons'>close</i></button>
        </div>
        <div class='m-b-40'>
          <div id='dialog-title'>Changes Log</div>
        </div>
        <h5>June 29, 2016</h5>
        <div class='changes'>
          <ul>
           <li>Added Config model</li>
           <li>System Settings module update</li>
          </ul>
        </div>
        <h5>June 28, 2016</h5>
        <div class='changes'>
          <ul>
            <li>Add HoverDetail to Graphs and other minor changes</li>
            <li> Remove zero counts from column titles in Case Follow Up report</li>
            <li>Remove 'USSD' from CaseFollowUp report column title</li>
          </ul>
        </div>  
        <h5>June 27, 2016</h5>
        <div class='changes'>
          <ul>
            <li>Bug fixed where Username input in form cannot accept typing</li>
            <li>In Data Export, show 'Success' modal upon successful file download</li>
            <li>Remove yellow background color in icons in CaseFollowUp report</li>
            <li>MapView: Fixed broken Home button</li>
            <li>Add sample graphs on Dashboard</li>
          </ul>
        </div>
        <h5>June 24, 2016</h5>
        <div class='changes'>
          <ul>
            <li>Add password input field to the Add New User form.</li>
            <li>Add validations to the form inputs fields for Users</li>
            <li>Fixed bug where the Data Selector change is not applied to the Data Export</li>
            <li>Improved Graph container box and layout</li>
            <li>Fixed hidden bug of incorrect Object cloning method used</li>
            <li>Fixed the 'Page not found' error when changing the dates in Date Selector within Data Export</li>
            <li>Application version to be set as a Constant</li>
            <li>Added the token generating function to generate token when user request password reset. Token to be saved in user doc</li>
            <li>Make graph layout on dashboard responsive </li>
            <li>Refactor Graph model functions to be shareable among different graphs. </li>
            <li>Add preliminary Yearly Trends graph. Appropriate data still need to be extracted for this graph</li>
            <li>Temporarily apply disabled css to drawer items not ready</li>
            <li>MapView: Cases style functionality for One or More Cases, Recent Travel and LLIN < Number of Sleeping Spaces</li>
            
          </ul>
        </div>
        <h5>June 23, 2016</h5>
        <div class='changes'>
          <ul>
            <li>Add a class for Graphs. Refactor graph layout and placement </li>
            <li>Fix routing in DashboardView after date change, not to show 'Page not found' message.</li
            <li>MapView:  Geographic data structure for LLIN and RecentTravel data styling</li>
            </li>Adding a module for Constants</li>
            <li>MapView: Event listener established between myLayersControl and MapView. Will be used to style cases tomorrow. </li>
          </ul>
        </div>
        <h5>June 22, 2016</h5> 
        <div class='changes'>
          <ul>          
            <li>MapView:  initial work done for case styling selector (layout change event). Not finished. </li>
            <li>Added bcryptjs for generating password hash, and modify codes to reset passwords.</li>
            <li>Removed 'undefined' as roles in MessagingView</li>
            <li>Remove 'user' from Assigned To listing in IssuesView</li>
            <li>MapView: time slider setting added to page refresh.</li>      
            <li>MapView: heatmap and cluster settings added to page refresh setting</li>
            <li>MapView:  add mapLat and mapping variables to url and parse them on page refresh</li>
          </ul>
        </div>
        <h5>June 21, 2016</h5> 
        <div class='changes'>
          <ul>
            <li>MapView: Template for url variable parsing for map settings loading after date query. zoom level implemented. other settings to come.</li>      
          </ul>
        </div>
        <h5>June 20, 2016</h5> 
        <div class='changes'>
          <ul>
            <li>MapView: True Case Numbers added.</li>
            <li>Fix to catch-then in one db query in Reports model</li>
            <li>Add fix to Errors detected by System</li>
            <li>MapView: Material color palette for admin layers</li>
            <li>MapView: Camera button maintains position when layer control panel is visible </li>
            <li>Enhancement to MessagingView</li>
            <li>MapView: Play button styling: Blue minifab with on/off coloration consistent with other map tool buttons</li>
            <li>MapView: Layer control styling: move cases layer above other overlay layers</li>
          </ul>
        </div>
        
        <div id='dialogActions'>
             <button class='mdl-button mdl-js-button mdl-button--primary' id='OkClickBtn' type='submit' ><i class='material-icons'>done</i> Ok</button>
        </div> 
      </dialog>
    "
    dialogPolyfill.registerDialog(changeLogDialog)
    
    # Temporary hack for polyfill issue on non-chrome browsers
    if (Env.is_chrome)
       changeLogDialog.showModal()
    else
       changeLogDialog.show()

module.exports = ChangeLogView
