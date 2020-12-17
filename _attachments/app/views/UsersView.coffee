crypto = require('crypto')
Tabulator = require 'tabulator-tables'

class UsersView extends Backbone.View
    el:'#content'

    events:
      "click button#addUser": "addUser"
      "click button#resetPassword": "resetPassword"

    addUser: =>
      username = prompt "What is the new username (phone number for DMSOs)?"
      username = "user.#{username}"
      password = prompt "What is the new password?"
      password = (crypto.pbkdf2Sync password, '', 1000, 256/8, 'sha256').toString('base64')


      @tabulator.addRow
        _id: username
        district: []
        name: ""
        email: ""
        roles: []
        comments: ""
        inactive: false
        collection: "user"
        isApplicationDoc: true
        password: password
        
    resetPassword: (username) =>
      unless _(username).isString()
        username = prompt "What is the user's id or username that you wish to reset?"
        username = "user.#{username}" unless username.match(/^user/)

      unless (_(await @users()).pluck("_id")).includes username
        alert "Invalid username: #{username}"
        @resetPassword(null)

      newPass = prompt "Enter the new password"
      if newPass is "" or newPass is null
        alert "Password can't be blank"
        @resetPassword(username)
      else
        await Jackfruit.database.upsert username, (doc) =>
          doc.password = (crypto.pbkdf2Sync newPass, '', 1000, 256/8, 'sha256').toString('base64')
          doc
        .catch (error) =>
          alert ("Error: #{JSON.stringify error}")
          console.error error
        alert "Password has been reset"

    users: =>
      Coconut.database.allDocs
        startkey: "user"
        endkey: "user\ufff0"
        include_docs: true
      .catch (error) -> console.error error
      .then (result) =>
        console.log result
        Promise.resolve _(result.rows).pluck("doc")

    render: =>
      @$el.html "
        <h2>Users</h2>
        Click on a cell to edit the user. Districts and roles allow for multiple options to be selected, just press the tab button after the selection have been made.<br/>
        <button id='addUser'>Add a new user</button>
        <button id='resetPassword'>Reset a user's password</button>

        <div id='userTabulator'/>
      "

      columns = for field in [
          "_id"
          "name"
          "district"
          "email"
          "roles"
          "comments"
          "inactive"
        ]

        result = {
          title: field
          field: field
          headerFilter: "input"
        }

        result.editor = switch field
          when "_id" then null
          when "inactive" then "tickCross"
          when "district"
            result.editorParams = 
              values: GeoHierarchy.allDistricts()
              multiselect: true
            "select"
          when "roles"
            result.editorParams = 
              values: ["reports","admin","researcher","DMSO"]
              multiselect: true
            "select"
          else "input"

        result

      @tabulator = new Tabulator "#userTabulator",
        height: 400
        columns: columns
        data: await @users()
        cellEdited: (cell) =>
          oldValue = cell.getOldValue()
          value = cell.getValue()
          isUpdated = if _(value).isArray()
            not _(oldValue).isEqual(value)
          else
            cell.getOldValue() isnt cell.getValue() and
            cell.getOldValue() isnt null and 
            cell.getValue() isnt ""


          if isUpdated and confirm("Are you sure you want to change #{cell.getField()} for #{cell.getData()._id} from '#{oldValue}' to '#{value}'")
            data = cell.getRow().getData()
            delete data._rev
            Coconut.database.upsert data._id,  =>
              data
          else
            cell.restoreOldValue()

module.exports = UsersView
