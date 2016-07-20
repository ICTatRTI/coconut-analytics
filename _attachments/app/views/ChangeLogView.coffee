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
        <h5>July 20, 2016</h5>
        <div class='changes'>
          <ul>
            <li>#186 - Change favicon</li>
            <li>#181 - Fixed Issues table search not working</li>
          </ul>
        </div>    
        <h5>July 19, 2016</h5>
        <div class='changes'>
          <ul>
            <li>MapView: comment out code for labeling</li>
            <li>Re-wording of column headings in Analysis report</li>
          </ul>
        </div>  
        <h5>July 18, 2016</h5>
        <div class='changes'>
          <ul>
           <li>#183 - Switch pikaday to DateRangePicker</li>
           <li>Added Bootstrap-DateRanePicker and removed Pikaday npm packages</li>
           <li>MapView: moved label counterpoints files</li>
           <li>MapView: #178 legend and case style matching</li>
           <li>MapView: #134 district labeling - functionality coded referencing JSON files</li>
           <li>MapView: #176 legend displays only when there are cases and is removed when query returns no cases</li>
          </ul>
        </div>
        <h5>July 15, 2016</h5>
        <div class='changes'>
          <ul>
           <li>#86 - Display assignee's full name in the Issues table</li>
           <li>MapView: #169 : Vertical Spacing of Map and Slider, begin work on full screen control slider deactivation(#170)</li>
           <li>MapView: #170 deactivate time slider if active when going into full screen mode. Also captured time slider status on full screen enter to reactivate after full screen exit</li>
          </ul>
        </div>
        <h5>July 13, 2016</h5>
        <div class='changes'>
          <ul>
           <li>#177 - Fixed Missing DateSelector in IssuesView, Add, Edit and Delete functionality</li>
           <li>Removed persistent params from URL after updating data in System Settings</li>
           <li>Removed 'To Do' from Activities menu</li>
          </ul>
        </div>   
        <h5>July 12, 2016</h5>
        <div class='changes'>
          <ul>
           <li>#113 - Completed the enhancement to the Messaging module</li>
           <li>#175 - Fix bug where Case list toggle not working consistently</li>
           <li>#173 - Change wording 'tablet' to 'mobile device'</li>
           <li>Fixed #166 bug in relations to #172</li>
           <li>MapView: #167: corrected labeling for LLIN styling</li>
          </ul>
        </div>
        <h5>July 11, 2016</h5>
        <div class='changes'>
          <ul>
           <li>#166 - Fixed bug for Weekly Facilty Report</li>
           <li>#56 - Fix bug in Users Report - how fast followup</li>
           <li>#172 - Fix bug caused by #80</li>
           <li>Keeping Date Selector format as static YYYY-MM-DD instead of config.dateFormat</li>
          </ul>
        </div>
        <h5>July 9, 2016</h5>
        <div class='changes'>
          <ul>
           <li>#160 - Error when UPDATEing Admin | System Settings</li>
           <li>#135 - Case data repeats in case detail modal dialog</li>
           <li>MapView:  legend added</li>
           <li>MapView #142 Add last Date of IRS to cases and cases (time) layers Also preliminary district labeling implementation</li>
          </ul>
        </div>  
        <h5>July 8, 2016</h5>
        <div class='changes'>
          <ul>
           <li>Add missing IssueView that was called from the Epidemic Thresholds report</li>
           <li>MapView: #163 time slider play bug resolved </li>
           <li>MapView: #164 styling time layer matches styling in cases layer while switching back and forth between cases layer and cases time layer </li>
           <li>MapView: #133 - Turning on and off time slider causes multiple instances of cases to be created in layer control</li>
           <li>Quick Fix for a bug in Config model</li>
           <li>Other bug fixes as detailed in issue tickets</li>
          </ul>
        </div>  
        <h5>July 6, 2016</h5>
        <div class='changes'>
          <ul>
           <li>Add full option list of Countries and Timezones in the System Settings</li>
           <li>#159 - User form Roles select input issue</li>
           <li>#12 - Add Settings for turning off Add and turning off Edit of Facilities</li>
           <li>Reload browser upon System Settings update and add Color Schemes for graphs</li>
           <li>Corrected x-axis label position in large graphs</li>
           <li>Fix positioning and display of graphs legend</li>
           <li>#156: MapView: The time slider's scale endpoints were one day behind. Added a day to the starting and ending point of the scale. </li>
          </ul>
        </div>
        <h5>July 5, 2016</h5>
        <div class='changes'>
          <ul>
           <li>Updated graphs display on Dashboard</li>
           <li>Add Positive Malaria Cases graph</li>
           <li>Aligning hover dots on graphs</li>
           <li>Refactored Graph class</li>
          </ul>
        </div>
        <h5>July 1, 2016</h5>
        <div class='changes'>
          <ul>
           <li>Add role types to System Settings</li>
           <li>Change User roles input to checkbox selection instead of text input</li>
           <li>MapView: time slider looping at end of time scale</li>
           <li>Bug fixes in System Settings saving process</li>
          </ul>
        </div>
        <h5>June 30, 2016</h5>
        <div class='changes'>
          <ul>
           <li>Fixed bug of adding new user record not saving</li>
           <li>Add error popup in the event of error encountered in addition to console.log</li>
           <li>Disable editing of username in UserView</li>
           <li>Replacing 'USSD Notification' to 'Case Notification Sent' and 'Case Notification' to 'Case Notification Received'</li>
          </ul>
        </div>
        <h5>June 29, 2016</h5>
        <div class='changes'>
          <ul>
           <li>Added Config model</li>
           <li>System Settings module update, saving record</li>
           <li>MapView: Create cases link in timeCasesLayer popup</li>
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
