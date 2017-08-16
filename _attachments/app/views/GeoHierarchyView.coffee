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


class GeoHierarchyView extends Backbone.View
  el: '#content'
  events:
    "click #new-geo-btn": "createGeoHierarchy"
    "click a.geo-edit": "editGeoHierarchy"
    "click a.geo-delete": "deleteDialog"
    "click button#ghSave": "formSave"
    "click button#ghCancel": "formCancel"
    "click button#buttonYes": "deleteGeo"

  createGeoHierarchy: (e) =>
    e.preventDefault
    dialogTitle = "Add New Geo Hierarchy"
    Dialog.create(@dialogEdit, dialogTitle)
    $('form#hierarchy input').val('')
    return false

  editGeoHierarchy: (e) =>
    e.preventDefault
    dialogTitle = "Edit Geo Hierarchy"
    Dialog.create(@dialogEdit, dialogTitle)
    id = $(e.target).closest("a").attr "data-geo-id"
    rec = $("[id='#{id}']").find('td')
    $("input#Region").val(rec[0].innerText)
    $("input#District").val(rec[1].innerText)
    $("input#Shehia").val(rec[2].innerText)
    Dialog.markTextfieldDirty()
    return false

  formSave: (e) =>
    console.log("Saving Data")
    dialog.close()
    return false

  deleteDialog: (e) =>
    e.preventDefault
    dialogTitle = "Are you sure?"
    Dialog.confirm("This will permanently remove the record.", dialogTitle,['No', 'Yes'])
    console.log("Delete initiated")
    return false

#TODO Need code to delete doc
  deleteGeo: (e) =>
    e.preventDefault
    console.log("Record Deleted")
    dialog.close() if dialog.open
    return false

  formCancel: (e) =>
    e.preventDefault
    console.log("Cancel pressed")
    dialog.close() if dialog.open
    return false

  render: ->
    options = $.extend({},Coconut.router.reportViewOptions)
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
           <button class='mdl-button mdl-js-button mdl-button--primary' id='ghSave' type='submit' value='save'><i class='mdi mdi-content-save mdi-24px'></i> Save</button> &nbsp;
           <button class='mdl-button mdl-js-button mdl-button--primary' id='ghCancel' type='submit' value='cancel'><i class='mdi mdi-close-circle mdi-24px'></i> Cancel</button>
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
      <h4>Geo Hierarchy <button class='mdl-button mdl-js-button mdl-button--fab mdl-button--mini-fab mdl-button--colored' id='new-geo-btn'>
              <i class='mdi mdi-plus mdi-36px'></i>
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
               <button id='edit-menu_#{rowIdentifier}' class='mdl-button mdl-js-button mdl-js-ripple-effect mdl-button--icon'>
                  <i class='mdi mdi-dots-vertical mdi-24px'></i>
                </button>
                <ul class='mdl-menu mdl-menu--bottom-right mdl-js-menu mdl-js-ripple-effect' for='edit-menu_#{rowIdentifier}'>
                  <li class='mdl-menu__item'><a href='#' class='geo-edit' data-geo-id='#{rowIdentifier}'><i class='mdi mdi-pencil mdi-24px'></i> Edit</a></li>
                  <li class='mdl-menu__item'><a href='#' class='geo-delete' data-geo-id='#{rowIdentifier}'><i class='mdi mdi-delete mdi-24px'></i> Delete</a></li>
                </ul>
            </td>
          </tr>
          "
        .join("")
      )
      componentHandler.upgradeDom()
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
