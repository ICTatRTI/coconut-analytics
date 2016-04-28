_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

global.jQuery = require 'jquery'
require 'tablesorter'

humanize = require 'underscore.string/humanize'
Form2js = require 'form2js'
js2form = require 'form2js'

moment = require 'moment'

DataTables = require 'datatables'
User = require '../models/User'
UserCollection = require '../models/UserCollection'

class UsersView extends Backbone.View
    el:'#content'
    events:
      "click #new-user-btn": "createUser"
      "click a.user-edit": "editUser"
      "click #formSave": "formSave"
      "click #formCancel": "formCancel"

    createUser: (e) =>
      e.preventDefault
      $('#form-title').html("Create New User")
      $('#form-inputs').slideToggle()
      $('form#user input').val('')
	  	  
    editUser: (e) =>
      e.preventDefault
      $('#form-title').html("Edit User")
      $('#form-inputs').slideDown()
	  #move focus to the top of edit form
      $('div#content').scrollTop(0)
      #window.location.hash = '#top-of-form'

      id = $(e.target).closest("a").attr "data-user-id"
      
      Coconut.database.get id,
         include_docs: true
      .catch (error) -> console.error error
      .then (user) =>
         @user = _.clone(user)
         user._id = user._id.substring(5)
         Form2js.js2form($('form#user').get(0), user)
         if (user.roles)
           for role in user.roles
             $("[name=role][value=#{role}]").prop("checked", true)
       return false
	   
    formSave: =>
      if not @user
        @user = {
          _id: "user." + $("#_id").val()
        }
      
      @user.inactive = $("#inactive").is(":checked")
      @user.isApplicationDoc = true
      @user.district = $("#district").val().toUpperCase()
      @user.password = $('#password').val()
      @user.name = $('#name').val()
      @user.roles = $('#roles').val()
      @user.comments = $('#comments').val()

      console.log @user

      Coconut.database.put @user
      .catch (error) -> console.error error
      .then =>
        @render()
      

    formCancel: (e) =>
      e.preventDefault
      $('#form-inputs').slideUp()
	  		
    # On saving 
    # Coconut.database.get "user.id"
    # (result) ->       
    # result._rev # what you ned
    # 
    # Create a user from the input fields: createdUser
    # Then add a _rev field from the above get: createdUser._rev = result.document._rev
    # Then you can save the document by doing
    # Coconut.database.put createdUser

    render: =>

      Coconut.database.query "zanzibar-server/users",
        include_docs: true
      .catch (error) -> console.error error
      .then (result) =>
        users = _(result.rows).pluck("doc")

        fields =  "_id,password,district,name,roles,comments".split(",")

        @$el.html "
            <h4>Users <button class='mdl-button mdl-js-button mdl-button--fab mdl-button--mini-fab mdl-button--colored' id='new-user-btn'>
              <i class='material-icons'>add</i>
            </button></h4>
            <div id='top-of-form' tabindex='1'>	</div>
            <div id='form-inputs'>
               <div id='user-form'>
                  <div id='form-title'> </div>
 	              <div>
                     <ul>
                       <li>DMSO's must have a username that corresponds to their phone number.</li>
                       <li>If a DMSO is no longer working, mark their account as inactive to stop notification messages from being sent.</li>
                     </ul>
                  </div>
                  <form id='user'>
                    <div class='mdl-grid'>
                     #{
                      _.map( fields, (field) =>
                        "
                        <div class='mdl-cell mdl-cell--2-col mdl-cell--4-col-tablet'>
                           <label style='display:block' for='#{field}'>#{if field is "_id" then "Username" else humanize(field)}</label>
                           <input id='#{field}' name='#{field}' type='text' #{if field is "_id" and not @user then "readonly='true'" else ""}></input>
                        </div>
                        "
                        ).join("")
                      }

                       <label class='mdl-checkbox mdl-js-checkbox mdl-js-ripple-effect' for='inactive'>
                       <input type='checkbox' id='inactive' name='inactive' class='mdl-checkbox__input'>
                          <span class='mdl-switch__label'>Inactive</span>
                       </label>

                <div style='margin-top: 5px; padding-left: 10px'>
                       <button class='mdl-button mdl-js-button mdl-button--primary' id='formSave'>Save</button> &nbsp;
                       <button class='mdl-button mdl-js-button mdl-button--primary' id='formCancel'>Cancel</button>
                     </div> 
                   </div>	  
                 </form>
              </div>
            </div>
            <div id='results' class='result'>
              <table class='summary tablesorter'>
                <thead>
                  <tr> 
                  <th class='header headerSortUp'>Username</th>
                  <th>Password</th>
                  <th class='header'>District</th>
                  <th class='header'>Name</th>
                  <th class='header'>Roles</th>
                  <th>Comments</th>
                  <th class='header'>Inactive</th>
                  <th>Actions</th>
                  </tr>
                </thead> 
                <tbody>
                  #{
                    _(users).map (user) ->
                      "
                      <tr>
                        <td>#{user._id.substring(5)}</td>
                        <td>#{user.password}</td>
                        <td>#{user.district}</td>
                        <td>#{user.name}</td>
                        <td>#{user.roles}</td>
                        <td>#{user.comments}</td>
                        <td>#{user.inactive}</td>
                        <td> <button class='mdl-button mdl-js-button mdl-button--icon'>
                           <a href='#' class='user-edit' data-user-id='#{user._id}'><i class='material-icons'>mode_edit</i></a></button>
                        </td>
                     </tr> 
                     "
                    .join("")
                  }
                </tbody>
              </table>
            </div>
        "
        $("table.summary").tablesorter({sortList: [[0,0]]})

module.exports = UsersView
