_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
PouchDB = require 'pouchdb'
moment = require 'moment'
require 'tablesorter'
Dialog = require './Dialog'
humanize = require 'underscore.string/humanize'
Form2js = require 'form2js'
js2form = require 'form2js'

class RainfallStationView extends Backbone.View
  el: '#content'

  events:
    "click #new-station-btn": "createStation"
    "click a.station-edit": "editStation"
    "click a.station-delete": "deleteDialog"
    "click button#formSave": "formSave"
    "click button#formCancel": "formCancel"
    "click button#buttonYes": "deleteStation"

  createStation: (e) =>
    e.preventDefault
    dialogTitle = "Add New Rainfall Station"
    Dialog.create(@dialogEdit, dialogTitle)
    $('form#station input').val('')
    return false

  editStation: (e) =>
    e.preventDefault
    dialogTitle = "Edit Rainfall Station"
    Dialog.create(@dialogEdit, dialogTitle)
    id = $(e.target).closest("a").attr "data-station-id"
    rec = $("[id='#{id}']").find('td')
    $("input#Region").val(rec[0].innerText)
    $("input#District").val(rec[1].innerText)
    $("input#Name").val(rec[2].innerText)
    $("input[id='Phone Numbers']").val(rec[3].innerText)
    Dialog.markTextfieldDirty()
    return false
	
  formCancel: (e) =>
    e.preventDefault
    console.log("Cancel pressed")
    dialog.close() if dialog.open
    return false

  formSave: (e) =>
    console.log("Saving Data")
    dialog.close()
#    @updateDatabaseDoc(@dataTable.data())
#    Coconut.database.put @databaseDoc
#      _rev: doc._rev #if edit mode
#    .catch (error) -> console.error error
#    .then (result) ->
#      @render()
    return false

  deleteDialog: (e) =>
    e.preventDefault
    dialogTitle = "Are you sure?"
    Dialog.confirm("This will permanently remove the record.", dialogTitle,['No', 'Yes']) 
    console.log("Delete initiated")
    return false

#TODO Need code to delete doc	
  deleteStation: (e) =>
    e.preventDefault
    console.log("Record Deleted")
    dialog.close()
    return false
			
  render: ->
    options = $.extend({},Coconut.router.reportViewOptions)
    @fields = "Region,District,Name,Phone Numbers".split(/,/)
    @document_id = "Rainfall Stations"
    @dialogEdit = "
      <form id='station' method='dialog'>
         <div id='dialog-title'> </div>
         #{
          _.map( @fields, (field) =>
            "
               <div class='mdl-textfield mdl-js-textfield mdl-textfield--floating-label'>
                 <input class='mdl-textfield__input' type='text' id='#{field}' name='#{field}' #{if field is "_id" and not @user then "readonly='true'" else ""}></input>
                 <label class='mdl-textfield__label' for='#{field}'>#{if field is "_id" then "Username" else humanize(field)}</label>
               </div>
            "
            ).join("")
          }

        <div id='dialogActions'>
           <button class='mdl-button mdl-js-button mdl-button--primary' id='formSave' type='submit' value='save'><i class='material-icons'>save</i> Save</button> &nbsp;
           <button class='mdl-button mdl-js-button mdl-button--primary' id='formCancel' type='submit' value='cancel'><i class='material-icons'>cancel</i> Cancel</button>
        </div> 
      </form>
    "
    $('#analysis-spinner').show()
    @$el.html "
      <style> table.dataTable thead th { padding: 0 0 8px}</style>
      <h4>Rainfall Stations <button class='mdl-button mdl-js-button mdl-button--icon mdl-button--colored' id='new-station-btn'>
              <i class='material-icons'>add_circle</i>
            </button>
      </h4>
      <dialog id='dialog'>
        <div id='dialogContent'> </div>
      </dialog>
      <table class='tablesorter mdl-data-table mdl-js-data-table mdl-shadow--2dp' id='rainfallStations'>
        <thead>
          #{_(@fields).map((field) -> "<th class='mdl-data-table__cell--non-numeric'>#{field}</th>").join("")}
          <th>Action</th>
        </thead>
        <tbody>
        </tbody>
      </table>
    "

    Coconut.database.get @document_id
    .catch (error) -> "Could not open: #{JSON.stringify error}"
    .then (result) =>
      @databaseDoc = result
      data = @dataToColumns(result)

      @$el.find("#rainfallStations tbody").html(_(data).map (rowData, rowIdentifier) =>
          "
          <tr id='#{rowIdentifier}'>
            #{
              _(@fields).map (field) =>
                "<td class='#{field.replace(" ", "_")} mdl-data-table__cell--non-numeric'>#{rowData[field]}</td>"
              .join()
            }
            <td>
               <button class='delete mdl-button mdl-js-button mdl-button--icon'>
                <a href='#' class='station-edit' data-station-id='#{rowIdentifier}'><i class='material-icons icon-sm'>mode_edit</i></a></button>
               <button class='delete mdl-button mdl-js-button mdl-button--icon'>
                <a href='#' class='station-delete' data-station-id='#{rowIdentifier}'><i class='material-icons icon-sm'>delete</i></a></button>
            </td>
          </tr>
          "
        .join("")
      )

      $('#analysis-spinner').hide()

      $("#rainfallStations").dataTable
        aaSorting: [[0,"asc"]]
        iDisplayLength: 10
        dom: 'T<"clear">lfrtip'
        tableTools:
          sSwfPath: "js-libraries/copy_csv_xls.swf"
          aButtons: [
            "copy",
            "csv",
            "print"
          ]

    @dataToColumns = (jsonData) ->
      data = {}
      _(jsonData.data).each (stationData,stationName) =>
        _(@fields).each (field) =>
          data[stationName] = {} unless data[stationName]?
          data[stationName][field] = stationData[field]
        data[stationName]["Name"] = stationName
        data[stationName]["Phone Numbers"] = data[stationName]["Phone Numbers"].join(",")
      return data

module.exports = RainfallStationView