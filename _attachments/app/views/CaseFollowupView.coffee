_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

global.jQuery = require 'jquery'
require 'tablesorter'

Reports = require '../models/Reports'

class CaseFollowupView extends Backbone.View
  events:
    "click .rpt-suboptions": "showDropDown"

  showDropDown: (e) =>
    id = '#'+ e.currentTarget.id + '-section'
    $("#{id}").slideToggle()
	
  render: =>
    $('#analysis-spinner').show()
    @$el.html "
      <div id='dateSelector'></div>
      <img id='analysis-spinner' src='/images/spinner.gif'/> 	
      <div id='summary-dropdown'>
        <div id='unhide-icons'>
		  <!--
		  <span id='cases-drop' class='drop-pointer rpt-suboptions'>
		 	<button class='mdl-button mdl-js-button mdl-button--icon'> 
		 	   <i class='material-icons'>functions</i> 
		     </button>Summary
		  </span>
          -->	  
		  <span id='legend-drop' class='drop-pointer rpt-suboptions'>
		 	<button class='mdl-button mdl-js-button mdl-button--icon'> 
		 	   <i class='material-icons'>dashboard</i> 
		     </button>
		 	Legend
		  </span>
		</div>
      </div>	
	  <div id='dropdown-container'>
           <div id='cases-drop-section'>
             <h4>Summary</h4>
             <div>
               <table class='mdl-data-table mdl-js-data-table mdl-shadow--2dp'>
                 <thead>
                   <tr>
                     <td class='mdl-data-table__cell--non-numeric'>Cases Reported at Facility</td>
                     <td>51</td>
                   </tr>
                 </thead>
                 <tbody>
                   <tr>
                     <td class='mdl-data-table__cell--non-numeric'>Additional People Tested</td>
                     <td>137</td>
                   </tr>
                   <tr>
                     <td class='mdl-data-table__cell--non-numeric'>Additional People Tested Positive</td>
                     <td>6</td>
                   </tr>
                 </tbody>
               </table>
             </div>	
             <hr />
           </div>
           
           <div id='legend-drop-section'>
             <h4>Legends</h4>	
             <h6>Click on a button for more details about the case.</h6>
             <button class='mdl-button mdl-js-button mdl-button--icon mdl-button--accent'><i class='material-icons'>account_circle</i></button> - Positive malaria result found at household<br />
             <button class='mdl-button mdl-js-button mdl-button--icon'><i class='material-icons  c_orange'>account_circle</i></button> - Positive malaria result found at household with no travel history (probable local transmission). <br />
             <button class='mdl-button mdl-js-button mdl-button--icon'><i class='material-icons  household'>home</i></button> - Index case had no travel history (probable local transmission).<br />
             <button class='mdl-button mdl-js-button mdl-button--icon mdl-button--accent'><i class='material-icons'>error_outline</i></button> - Case not followed up to facility after 24 hours. <br />
             <span style='font-size:75%;color:#3F51B5;font-weight:bold'>SHEHIA</span> - is a shehia classified as high risk based on previous data. <br />
             <button class='btn btn-small  mdl-button--primary'>caseid</button> - Case not followed up after 48 hours. <br />
          </div>
      </div>
      <script>$('#analysis-spinner').hide()</script>	
      <div id='results' class='result'>
         <table class='summary tablesorter'>
           <thead>
             <tr> 
               <th class='header'>Case ID (<span id='th-CaseID-count'>51</span>)</th>
               <th class='header headerSortUp'>Diagnosis Date (<span id='th-DiagnosisDate-count'>0</span>)</th>
               <th class='header'>Health Facility District (<span id='th-HealthFacility District-count'></span>)</th>
               <th class='header'>Shehia (<span id='th-Shehia-count'>0</span>)</th>
               <th class='header'>USSD Notification (<span id='th-USSDNotification-count'>49</span>)</th>
               <th class='header'>Case Notification (<span id='th-CaseNotification-count'>44</span>)</th>
               <th class='header'>Facility (<span id='th-Facility-count'>35</span>)</th>
               <th class='header'>Household (<span id='th-Household-count'>34</span>)</th>
               <th class='header'>Household Members (<span id='th-HouseholdMembers-count'>137</span>)</th>
             </tr>
           </thead>
          <tbody>
		    <tr id='case-109535' class='odd'> 
             <td class='CaseID'> <a class='btn btn-small  mdl-button--primary' href='#show/case/109535'>109535</button> </a> </td> 
             <td class='IndexCaseDiagnosisDate'> 2015-11-27 </td> 
             <td class='HealthFacilityDistrict'> MICHEWENI </td> 
             <td class='HealthFacilityDistrict high-risk-shehia'> TUMBE MASHARIKI </td> 
             <td class='USSDNotification'> <a href='#show/case/109535/e3f8034cfa0787f62c3e2828ff23f6f3'><button class='mdl-button mdl-js-button mdl-button--icon mdl-button--primary'><i class='material-icons'>open_in_browser</i></button></a> </td> 
             <td class='CaseNotification'> <a href='#show/case/109535/5D6BE0EF-0BC7-14D7-86FD-CB5276243847'><button class='mdl-button mdl-js-button mdl-button--icon mdl-button--primary'><i class='material-icons'>tap_and_play</i></button></a> </td> 
             <td class='Facility'> <a href='#show/case/109535/82E6F3E6-9490-CD3A-841E-1867BDBC3F31'><button class='mdl-button mdl-js-button mdl-button--icon mdl-button--primary'><i class='material-icons'>error_outline</i></button></a> </td> 
             <td class='Household'> <a href='#show/case/109535/21D6F874-0017-5E31-B668-CF22FB69F327'><button class='mdl-button mdl-js-button mdl-button--icon mdl-button--primary'><i class='material-icons household-incomplete'>home</i></button></a> </td> 
             <td class='HouseholdMembers'>  </td> 
	        </tr>
          </tbody> 
         </table>	
      </div>
    </div>
	"
	
module.exports = CaseFollowupView