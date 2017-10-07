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
    "click button#fhSave": "formSave"
    "click button#fhCancel": "formCancel"
    "click button#buttonYes": "deleteFacility"
    "change select#Region": "updateDistrictList"

  updateDistrictList: (e) =>
    regionSelected = $("select#Region").val()
    districtSelected = $("select#District").val()
    districtList = if regionSelected isnt "" then GeoHierarchy.findAllDistrictsFor(regionSelected,"REGION") else []
    $("select#District").val(districtSelected)
    $("select#District").empty().append("
      <option value=''></option>
      #{
        districtList.map (list) =>
          "<option value='#{list}'>
            #{list}
           </option>"
        .join ""
      }
    ")

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
    $("tr").removeClass("selected")
    document.getElementById("#{id}").classList.add('selected')
    rec = $("[id='#{id}']").find('td')
    $("select#Region").val(rec[0].innerText)
    $("select#Region").trigger("change")
    $("select#District").val(rec[1].innerText)
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
    dialog.close() if dialog.open
    @data = new FacilityHierarchy()
    @data.Region = $("select#Region").val()
    @data.District = $("select#District").val()
    @data.FacilityName = $("input[id='Facility Name']").val()
    @data.FacilityAlias = $("input#Aliases").val()
    @data.PhoneNumbers = $("input[id='Phone Numbers']").val()
    @data.Type = $("input#Type").val()
    newdata = [@data.Region, @data.District,@data.FacilityName, @data.FacilityAlias, @data.PhoneNumbers, @data.Type, null]
    if @mode is "create"
      @dataTable.row.add(newdata)
    else
      @dataTable.row('.selected').data(newdata)
    dataArray = @dataTable.rows().data()
    @updateDatabaseDoc(dataArray)
    @updateDbRecord(@databaseDoc)

  deleteDialog: (e) =>
    e.preventDefault
    id = $(e.target).closest("a").attr "data-facility-id"
    $("tr").removeClass("selected")
    document.getElementById("#{id}").classList.add('selected')
    dialogTitle = "Are you sure?"
    Dialog.confirm("This will permanently remove the record.", dialogTitle,['No', 'Yes'])
    console.log("Delete initiated")
    return false

#TODOS Need to add codes to delete doc
  deleteFacility: (e) =>
    e.preventDefault
    @dataTable.row('.selected').remove()
    @data = @dataTable.rows().data()
    @updateDatabaseDoc(@data)
    @updateDbRecord(@databaseDoc)
    dialog.close() if dialog.open
    return false

  formCancel: (e) =>
    e.preventDefault
    dialog.close() if dialog.open
    return false

  render: ->
    options = $.extend({},Coconut.router.reportViewOptions)
    HTMLHelpers.ChangeTitle("Admin: Facilities")
    @fields = "Region,District,Facility Name,Aliases,Phone Numbers,Type".split(/,/)
    @document_id = "Facility Hierarchy"

    @dialogEdit = "
      <form id='facility' method='dialog'>
         <div id='dialog-title'> </div>
         #{
          _.map( @fields, (field) =>
            "
               #{ if field is 'Region' or field is 'District'
                    if field is 'Region'
                      selectList = GeoHierarchy.allRegions()
                    else
                      regionSelected = $("select#Region").val()
                      selectList = GeoHierarchy.findAllDistrictsFor(regionSelected,"REGION") if regionSelected isnt ""
                    "
                    <div class='mdl-select mdl-js-select mdl-select--floating-label'>
                        <select class='mdl-select__input' id='#{field}' name='#{field}'>
                          <option value=''></option>
                          #{
                            selectList.map (list) =>
                              "<option value='#{list}'>
                                #{list}
                               </option>"
                            .join ""
                          }
                        </select>
                        <label class='mdl-select__label' for='#{field}'>#{field}</label>
                    </div>
                    "
                  else
                    "
                    <div class='mdl-textfield mdl-js-textfield mdl-textfield--floating-label'>
                      <input class='mdl-textfield__input' type='text' id='#{field}' name='#{field}'" + " #{if field is "_id" and not @user then "readonly='true'" else ''}></input>
                      <label class='mdl-textfield__label' for='#{field}'>#{humanize(field)}</label>
                    </div>
                    "
               }
            "
            ).join("")
         }
         <div id='dialogActions'>
               <button class='mdl-button mdl-js-button mdl-button--primary' id='fhSave' type='submit' value='save'><i class='mdi mdi-content-save mdi-24px'></i> Save</button> &nbsp;
               <button class='mdl-button mdl-js-button mdl-button--primary' id='fhCancel' type='submit' value='cancel'><i class='mdi mdi-close-circle mdi-24px'></i> Cancel</button>
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
      <h4>Health Facilities #{ if(Coconut.config.facilitiesEdit) then "<button class='mdl-button mdl-js-button mdl-button--fab mdl-button--mini-fab mdl-button--colored' id='new-facility-btn'>
              <i class='mdi mdi-plus mdi-36px'></i></button>" else "" }
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
            #{ if(Coconut.config.facilitiesEdit)
                "
                 <button id='edit-menu_#{rowIdentifier}' class='mdl-button mdl-js-button mdl-js-ripple-effect mdl-button--icon'>
                    <i class='mdi mdi-dots-vertical mdi-24px'></i>
                  </button>
                  <ul class='mdl-menu mdl-menu--bottom-right mdl-js-menu mdl-js-ripple-effect' for='edit-menu_#{rowIdentifier}'>
                    <li class='mdl-menu__item'><a href='#' class='facility-edit' data-facility-id='#{rowIdentifier}'><i class='mdi mdi-pencil mdi-24px'></i> Edit</a></li>
                    <li class='mdl-menu__item'><a href='#' class='facility-delete' data-facility-id='#{rowIdentifier}'><i class='mdi mdi-delete mdi-24px'></i> Delete</a></li>
                  </ul>
                "
               else ""
            }
            </td>
          </tr>
          "
        .join("")
      )
      componentHandler.upgradeDom()
      $('#analysis-spinner').hide()
      @dataTable = $("#facilityHierarchy").DataTable
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
          region = if districtData then districtData.parent().name else null
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

    @updateDbRecord = (rec) ->
      Coconut.database.put rec,
        _rev: rec._rev
      .catch (error) -> console.error error
      .then (result) =>
        @render()
      return false

module.exports = FacilityHierarchyView
