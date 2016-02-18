$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

class DateSelectorView extends Backbone.View
  events:
    "change #select-by": "selectBy"

  selectBy: (e) =>
    selected = $('#select-by :selected').text()
    if (selected == 'Date')
      $('tr.select-by-date').show()
      $('tr.select-by-week').hide()
    else
      $('tr.select-by-date').hide()
      $('tr.select-by-week').show()

  render: =>
    @$el.html "
      <table style='width: 400px; margin-left: 30px'>
        <tbody>
		   <tr id='select-date-week'>
             <td colspan='2'>Select By</td>
             <td><select name='SelectBy' id='select-by'> 
                <option value='Week'>Week</option>
                <option value='Date'>Date</option></select>
             </td>
             <td clospan='4'> &nbsp; </td>
           </tr>
           <tr class='select-by-date hide'>
               <td colspan='2'>
                 <label style='display:inline' for='StartDate'>Start Date</label>
               </td>
			   <td>
			      <div><input value='#{@startDate}'></input></div>
			   </td>
			   <td colspan='4'> </td>
		   </tr>
		   <tr class='select-by-date hide'>	   
               <td colspan='2'>
                 <label style='display:inline' for='EndDate'>End Date</label>
               </td>
			   <td>
			      <div><input value='#{@endDate}'></input></div>
			   </td>
			   <td colspan='4'></td>
		   </tr>	   
           <tr class='select-by-week'>
             <td colspan='2'>
               <label style='display:inline' for='StartYear'>Start Year</label>
             </td>
             <td>
               <select name='StartYear'>
                 #{
                   for i in [2015..2012] 
                      "<option value='#{i}'>#{i}</option>" 
                 }
               </select>
             </td>
             <td> </td>
             <td colspan='2'>
               <label style='display:inline' for='StartWeek'>Start Week</label>
             </td>
             <td>
               <select name='StartWeek'> <option></option>
                 #{
                     for i in [1..53] 
                       "<option value='#{i}'>Week #{i}</option>" 
                 } 
               </select>
             </td>
           </tr>
           <tr class='select-by-week'>
               <td colspan='2'>
                 <label style='display:inline' for='EndYear'>End Year</label>
               </td>
               <td>
                 <select name='EndYear'> 
                   #{
	                    for i in [2015..2012] 
	                      "<option value='#{i}'>#{i}</option>" 
                    }
                 </select>
               </td>
               <td> </td>
               <td colspan='2'>
                  <label style='display:inline' for='EndWeek'>End Week</label>
               </td>
               <td>
                  <select name='EndWeek'>
	 			    #{
	                    for i in [1..53] 
	                      "<option value='#{i}'>Week #{i}</option>" 
	 				}
                  </select>
               </td> 
           </tr>	
		 </tbody>
	   </table> 	
    "
    
module.exports = DateSelectorView
