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
              #{
                _(users).map (user) -> "
                  <td><button type='button' class='btn btn-info'>#{user._id.substring(5)}<button></td>
                  <td>#{user.password}</td>
                  <td>#{user.district}</td>
                  <td>#{user.name}</td>
                  <td>#{user.roles}</td>
                  <td>#{user.comments}</td>
                "
              }
             <td class='CaseID'>
            </td>
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
