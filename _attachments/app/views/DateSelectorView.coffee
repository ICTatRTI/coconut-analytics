$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

class DateSelectorView extends Backbone.View
  events:
    "change #select-by": "selectBy"

  selectBy: (e) =>
    selected = $('#select-by :selected').text()
    if (selected == 'Date')
      $('td.select_by_date').show()
      $('td.select_by_week').hide()
    else
      $('td.select_by_date').hide()
      $('td.select_by_week').show()

  render: =>
    @$el.html "
	  <table>
	    <tr>
		 <td>Select By</td>
	     <td><select name = 'SelectBy' id='select-by'> 
		   <option value='Week'>Week</option>
		   <option value='Date'>Date</option></select>
	     </td>
		 <td class='select_by_date width30'> </td>
		 <td class= 'select_by_date'>
            <div>Start date <input value='#{@startDate}'></input></div>
            <div>End date &nbsp;<input value='#{@endDate}'></input></div>
		 </td>
		 <td class= 'select_by_week width30'> </td>
		 <td class= 'select_by_week'>
		    <div>
		     <label style='display:inline' for='StartYear'>Start Year &nbsp;</label>
		     <select name='StartYear'> 
 		       #{
                   for i in [2015..2012] 
                     "<option value='#{i}'>#{i}</option>" 
 			   }
			 </select>
			</div>
			<div> 
		     <label style='display:inline' for='StartWeek'>Start Week </label>
		     <select name='StartWeek'><option></option>
			    #{
                   for i in [1..53] 
                     "<option value='#{i}'>Week #{i}</option>" 
				} 
			 </select>
			</div> 
		 </td>
		 <td class='width30'> </td>
		 <td class= 'select_by_week'>
		    <div>
		     <label style='display:inline' for='EndYear'>End Year &nbsp;</label>
		     <select name='EndYear'>
		       #{
                  for i in [2015..2012] 
                    "<option value='#{i}'>#{i}</option>" 
			   }
			 </select>
			</div>
			<div> 
		     <label style='display:inline' for='EndWeek'>End Week </label>
		     <select name='EndWeek'><option></option>
			    #{
                   for i in [1..53] 
                     "<option value='#{i}'>Week #{i}</option>" 
				} 
			 </select>
			</div> 
		 </td>
		</tr>
	   </table> 	
    "
    
module.exports = DateSelectorView
