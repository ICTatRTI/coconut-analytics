_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
PouchDB = require 'pouchdb'
moment = require 'moment'
global.jQuery = require 'jquery'
Dialog = require './Dialog'
require 'tablesorter'
FacilityHierarchy = require '../models/FacilityHierarchy'
humanize = require 'underscore.string/humanize'
Form2js = require 'form2js'
js2form = require 'form2js'

class FacilityHierarchyView extends Backbone.View
  el: '#content'
  
  events:
    "click #new-facility-btn": "createFacility"
    "click a.facility-edit": "editFacility"
    "click a.facility-delete": "deleteDialog"
    "click button#formSave": "formSave"
    "click button#formCancel": "formCancel"
    "click button#buttonYes": "deleteFacility"
  
  createFacility: (e) =>
    e.preventDefault
    @mode = "create"
    dialogTitle = "Add New Facility"
    Dialog.create(@dialogEdit, dialogTitle)
    $('form#facility input').val('')
    return false

  editFacility: (e) =>
    e.preventDefault
    @mode = "edit"
    dialogTitle = "Edit Facility"
    Dialog.create(@dialogEdit, dialogTitle)
    id = $(e.target).closest("a").attr "data-facility-id"
    rec = $("[id='#{id}']").find('td')
    console.log(rec[0].innerText)
    $("input#Region").val(rec[0].innerText)
    $("input#District").val(rec[1].innerText)
    $("input[id='Facility Name']").val(rec[2].innerText)
    $("input#Aliases").val(rec[3].innerText)
    $("input[id='Phone Numbers']").val(rec[4].innerText)
    $("input#Type").val(rec[5].innerText)
    Dialog.markTextfieldDirty()
    return false
	  
#    Coconut.database.get id,
#       include_docs: true
#    .catch (error) -> console.error error
#    .then (facility) =>
#       @facility = _.clone(facility)
#       Form2js.js2form($('form#facility').get(0), @facility)
  formSave: (e) =>
    console.log("Saving Data")
    dialog.close()
    
    @data = new FacilityHierarchy()
    @data.Region = $("input#Region").val()
    @data.District = $("input#District").val()
    @data.FacilityName = $("input[id='Facility Name']").val()
    @data.FacilityAlias = $("input#Aliases").val()
    @data.PhoneNumbers = $("input[id='Phone Numbers']").val()
    @data.Type = $("input#Type").val()
    console.log(@data)
    debugger
    Coconut.database.put @data
      _rev: @data._rev if @mode == "edit"
    .catch (error) -> console.error error
    .then (result) ->
      @render()
    return false
	
  deleteDialog: (e) =>
    e.preventDefault
    dialogTitle = "Are you sure?"
    Dialog.confirm("This will permanently remove the record.", dialogTitle,['No', 'Yes']) 
    console.log("Delete initiated")
    return false

#TODOS Need to add codes to delete doc
  deleteFacility: (e) =>
    e.preventDefault
    console.log("Record Deleted")
    dialog.close()
    return false

  formCancel: (e) =>
    e.preventDefault
    console.log("Cancel pressed")
    dialog.close() if dialog.open
    return false

  render: ->
    options = Coconut.router.reportViewOptions
    @fields = "Region,District,Facility Name,Aliases,Phone Numbers,Type".split(/,/)
    @document_id = "Facility Hierarchy"

    @dialogEdit = "
      <form id='facility' method='dialog'>
         <div id='dialog-title'> </div>
         #{
          _.map( @fields, (field) =>
            "
               <div class='mdl-textfield mdl-js-textfield mdl-textfield--floating-label'>
                 <input class='mdl-textfield__input' type='text' id='#{field}' name='#{field}' #{if field is "_id" and not @user then "readonly='true'" else ""}></input>
                 <label class='mdl-textfield__label' for='#{field}'>#{humanize(field)}</label>
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
      <style>
        fieldset { padding:0; border:0; margin-top:25px; }
        .ui-dialog .ui-state-error { padding: .3em; }
        .validateTips { border: 1px solid transparent; padding: 0.3em; }
        input.text { margin-bottom:12px; width:95%; padding: .4em; }
        table.dataTable thead th { padding: 0 0 8px}
      </style>
      <h4>Health Facilities <button class='mdl-button mdl-js-button mdl-button--icon mdl-button--colored' id='new-facility-btn'>
              <i class='material-icons'>add_circle</i>
            </button>
      </h4>
      <dialog id='dialog'>
        <div id='dialogContent'> </div>
      </dialog>
      <table class='tablesorter mdl-data-table mdl-js-data-table mdl-shadow--2dp' id='facilityHierarchy'>
        <thead>
          #{_(@fields).map((field) -> "<th class='mdl-data-table__cell--non-numeric'>#{field}</th>").join("")}
          <th class='action'>Action</th>
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
      @$el.find("#facilityHierarchy tbody").html(_(data).map (rowData, rowIdentifier) =>
          "
          <tr id='#{rowIdentifier}'>
            #{
              _(@fields).map (field) =>
                "<td class='#{field.replace(" ", "_")} mdl-data-table__cell--non-numeric' >#{rowData[field]}</td>"
              .join()
            }
            <td>
               <button class='edit mdl-button mdl-js-button mdl-button--icon'>
                <a href='#' class='facility-edit' data-facility-id='#{rowIdentifier}'><i class='material-icons icon-24'>mode_edit</i></a></button>
               <button class='delete mdl-button mdl-js-button mdl-button--icon'>
                <a href='#' class='facility-delete' data-facility-id='#{rowIdentifier}'><i class='material-icons icon-24'>delete</i></a></button>
            </td>
          </tr>
          "
        .join("")
      )

      $('#analysis-spinner').hide()
      @dataTable = $("#facilityHierarchy").dataTable
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
      _(jsonData.hierarchy).each (facilities,district) =>
        _(facilities).each (facility) ->
          uniqueKey = "#{district}-#{facility.facility}"
          districtData = GeoHierarchy.findFirst(district,"district")
          region = if districtData then districtData.REGION else null
          data[uniqueKey] =
            Region: region
            District: district
            "Facility Name": facility.facility
            "Phone Numbers": (if facility.mobile_numbers then facility.mobile_numbers.join(" ") else "")
            "Aliases": (if facility.aliases then facility.aliases.join(", ") else "")
            Type: facility.type or ""
      return data

    @updateDatabaseDoc = (tableData) ->
      @databaseDoc.hierarchy = {}
      _(tableData).each (row) =>
        [region, district, facility_name, aliases, phone_numbers, type] = row
        district = district.toUpperCase()
        facility_name = facility_name.toUpperCase()
        @databaseDoc.hierarchy[district] = [] unless @databaseDoc.hierarchy[district]
        @databaseDoc.hierarchy[district].push
          facility: facility_name
          mobile_numbers: if phone_numbers is "" then [] else phone_numbers.split(/ +|, */)
          aliases: if aliases is "" then [] else aliases.split(/, */)
          type: type or "public"
module.exports = FacilityHierarchyView