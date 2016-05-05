_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
PouchDB = require 'pouchdb'
moment = require 'moment'
require 'tablesorter'
Common = require './Common'
humanize = require 'underscore.string/humanize'
Form2js = require 'form2js'
js2form = require 'form2js'


class GeoHierarchyView extends Backbone.View
  el: '#content'
  events:
    "click #new-geo-btn": "createGeoHierarchy"
    "click a.geo-edit": "editGeoHierarchy"
    "click a.geo-delete": "deleteDialog"
    "click button#formSave": "formSave"
    "click button#formCancel": "formCancel"
    "click button#buttonYes": "deleteGeo"

  createGeoHierarchy: (e) =>
    e.preventDefault
    dialogTitle = "Add New Geo Hierarchy"
    Common.createDialog(@dialogEdit, dialogTitle)
    $('form#hierarchy input').val('')
    return false
	
  editGeoHierarchy: (e) =>
    e.preventDefault
    dialogTitle = "Edit Geo Hierarchy"
    Common.createDialog(@dialogEdit, dialogTitle)
    id = $(e.target).closest("a").attr "data-geo-id"
    rec = $("[id='#{id}']").find('td')
    $("input#Region").val(rec[0].innerText)
    $("input#District").val(rec[1].innerText)
    $("input#Shehia").val(rec[2].innerText)
    return false

  formSave: (e) =>
    console.log("Saving Data")
    dialog.close()
    return false

  deleteDialog: (e) =>
    e.preventDefault
    dialogTitle = "Are you sure?"
    Common.createDialog(@dialogConfirm, dialogTitle) 
    console.log("Delete initiated")
    return false
	
  deleteGeo: (e) =>
    e.preventDefault
    console.log("Record Deleted")
    dialog.close()
    return false
	
  formCancel: (e) =>
    e.preventDefault
    console.log("Cancel pressed")
    dialog.close()
    return false

  render: ->
    options = Coconut.router.reportViewOptions
    @fields = "Region,District,Shehia".split(/,/)
    @document_id = "Geo Hierarchy"
    @dialogEdit = "
      <form id='hierarchy' method='dialog'>
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
    @dialogConfirm = "
      <form method='dialog'>
        <div id='dialog-title'> </div>
        <div>This will permanently remove the record.</div>
        <div id='dialogActions'>
          <button type='submit' id='buttonYes' class='mdl-button mdl-js-button mdl-button--primary' value='yes'>Yes</button>
          <button type='submit' id='buttonNo' class='mdl-button mdl-js-button mdl-button--primary' value='no' autofocus>No</button>
        </div>
      </form>
    "
    $('#analysis-spinner').show()
    @$el.html "
      <style> 
       .icon-28 {font-size: 28px}; 
       .icon-24 {font-size: 24px}
       table.dataTable thead th { padding: 0 0 8px}
      </style>
      <h4>Geo Hierarchy <button class='mdl-button mdl-js-button mdl-button--icon mdl-button--colored' id='new-geo-btn'>
              <i class='material-icons icon-28'>add_circle</i>
            </button>
      </h4>
      <dialog id='dialog'>
        <div id='dialogContent'> </div>
      </dialog>
      <table class='tablesorter mdl-data-table mdl-js-data-table mdl-shadow--2dp' id='geoHierarchy'>
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

      @$el.find("#geoHierarchy tbody").html(_(data).map (rowData, rowIdentifier) =>
          "
          <tr id='#{rowIdentifier}'>
            #{
              _(@fields).map (field) =>
                "<td class='#{field.replace(" ", "_")} mdl-data-table__cell--non-numeric'>#{rowData[field]}</td>"
              .join()
            }
            <td>
               <button class='delete mdl-button mdl-js-button mdl-button--icon'>
                <a href='#' class='geo-edit' data-geo-id='#{rowIdentifier}'><i class='material-icons icon-24'>mode_edit</i></a></button>
               <button class='delete mdl-button mdl-js-button mdl-button--icon'>
                <a href='#' class='geo-delete' data-geo-id='#{rowIdentifier}'><i class='material-icons icon-24'>delete</i></a></button>
            </td>
          </tr>
          "
        .join("")
      )

      $('#analysis-spinner').hide()

      $("#geoHierarchy").dataTable
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
      _(jsonData.hierarchy).each (districtData,region) ->
        _(districtData).each (shehias,district) ->
          _(shehias).each (shehia) ->
            uniqueKey = "#{district}-#{shehia}"
            data[uniqueKey] =
              Region: region
              District: district
              Shehia: shehia
      return data
		  
module.exports = GeoHierarchyView