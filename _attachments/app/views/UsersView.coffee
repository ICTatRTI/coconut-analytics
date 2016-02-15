_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

DataTables = require 'datatables'
User = require '../models/User'
UserCollection = require '../models/UserCollection'

class UsersView extends Backbone.View
    el:'#content'
    events:
      "click #new-user-btn": "createUser"

    render: =>
      @$el.html "
          <button class='btn btn-primary' id='new-user-btn'>Create New User</button>
		  <div id='results' class='result'>
		  	<table class='summary tablesorter'> 
		  		<thead>
		  			<tr> 
		  			<th class='header headerSortUp'>Username</th>
		  			<th class='header'>Password</th>
		  			<th class='header'>District</th>
		  			<th class='header'>Name</th>
		  			<th class='header'>Roles</th>
		  			<th class='header'>Comments</th>
		  			<th class='header'>Inactive</th>
		  			<th class='header'>Actions</th>
		  			</tr>
		  		</thead> 
		  		<tbody>
				   <td class='CaseID'>
					   <button type='button' class='btn btn-info'><a href='#'>{{username}}</a></button>
					</td>
				   <td>{{doc.password}}</td>
				   <td>{{doc.district}}</td>	
				   <td>{{doc.name}}</td>
				   <td>{{doc.roles}}</td>
				   <td>{{doc.comments}}</td>
				   <td> </td>
				   <td> <button class='mdl-button mdl-js-button mdl-button--icon'>
					   <a href='#'><i class='material-icons'>mode_edit</i></a></button> 
					   <button class='mdl-button mdl-js-button mdl-button--icon'>
					   <a href='#'><i class='material-icons'>delete</i></a></button>
					</td>
		  		</tbody>
		  	</table>
		  </div>
      "

module.exports = UsersView