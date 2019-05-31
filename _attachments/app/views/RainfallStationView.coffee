_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
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
    "click button#rsSave": "formSave"
    "click button#rsCancel": "formCancel"
    "click button#buttonYes": "deleteStation"
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

  createStation: (e) =>
    e.preventDefault
    @mode = "create"
    dialogTitle = "Add New Rainfall Station"
    Dialog.create(@dialogEdit, dialogTitle)
    $('form#station input').val('')
    return false

  editStation: (e) =>
    e.preventDefault
    @mode = "edit"
    dialogTitle = "Edit Rainfall Station"
    Dialog.create(@dialogEdit, dialogTitle)
    id = $(e.target).closest("a").attr "data-station-id"
    $("tr").removeClass("selected")
    document.getElementById("#{id}").classList.add('selected')
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
    dialog.close() if dialog.open
    @data = {}
    @data.Region = $("select#Region").val()
    @data.District = $("select#District").val()
    @data.stationName = $("input#Name").val()
    @data.PhoneNumbers = $("input[id='Phone Numbers']").val()

    newdata = [@data.Region, @data.District,@data.stationName, @data.PhoneNumbers, null]
    if @mode is "create"
      @dataTable.row.add(newdata)
    else
      @dataTable.row('.selected').data(newdata)

    dataArray = @dataTable.rows().data()
    @updateRainfallDoc(dataArray)
    @updateDbRecord(@databaseDoc)
    return false

  deleteDialog: (e) =>
    e.preventDefault
    dialog.close() if dialog.open
    id = $(e.target).closest("a").attr "data-station-id"
    $("tr").removeClass("selected")
    document.getElementById("#{id}").classList.add('selected')
    dialogTitle = "Are you sure?"
    Dialog.confirm("This will permanently remove the record.", dialogTitle,['No', 'Yes'])
    console.log("Delete initiated")
    return false

#TODO Need code to delete doc
  deleteStation: (e) =>
    e.preventDefault
    @dataTable.row('.selected').remove()
    @data = @dataTable.rows().data()
    @updateRainfallDoc(@data)
    @updateDbRecord(@databaseDoc)
    console.log("Record Deleted")
    dialog.close() if dialog.open
    return false

  render: ->
    options = $.extend({},Coconut.router.reportViewOptions)
    HTMLHelpers.ChangeTitle("Admin: Rainfall Station")
    @fields = "Region,District,Name,Phone Numbers".split(/,/)
    @document_id = "Rainfall Stations"
    @dialogEdit = "
      <form id='station' method='dialog'>
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
                    <input class='mdl-textfield__input' type='text' id='#{field}' name='#{field}' #{if field is "_id" and not @user then "readonly='true'" else ""}></input>
                    <label class='mdl-textfield__label' for='#{field}'>#{if field is "_id" then "Username" else humanize(field)}</label>
                  </div>
                  "
               }
            "
          ).join("")
        }

        <div id='dialogActions'>
           <button class='mdl-button mdl-js-button mdl-button--primary' id='rsSave' type='submit' value='save'><i class='mdi mdi-content-save mdi-24px'></i> Save</button> &nbsp;
           <button class='mdl-button mdl-js-button mdl-button--primary' id='rsCancel' type='submit' value='cancel'><i class='mdi mdi-close-circle mdi-24px'></i> Cancel</button>
        </div>
      </form>
    "
    $('#analysis-spinner').show()
    @$el.html "
      <style> table.dataTable thead th { padding: 0 0 8px}</style>
      <h4>Rainfall Stations <button class='mdl-button mdl-js-button mdl-button--fab mdl-button--mini-fab mdl-button--colored' id='new-station-btn'>
              <i class='mdi mdi-plus mdi-14px'></i>
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
               <button id='edit-menu_#{rowIdentifier}' class='mdl-button mdl-js-button mdl-js-ripple-effect mdl-button--icon'>
                  <i class='mdi mdi-dots-vertical mdi-24px'></i>
                </button>
                <ul class='mdl-menu mdl-menu--bottom-right mdl-js-menu mdl-js-ripple-effect' for='edit-menu_#{rowIdentifier}'>
                  <li class='mdl-menu__item'><a href='#' class='station-edit' data-station-id='#{rowIdentifier}'><i class='mdi mdi-pencil mdi-24px'></i> Edit</a></li>
                  <li class='mdl-menu__item'><a href='#' class='station-delete' data-station-id='#{rowIdentifier}'><i class='mdi mdi-delete mdi-24px'></i> Delete</a></li>
                </ul>
            </td>
          </tr>
          "
        .join("")
      )
      componentHandler.upgradeDom()
      $('#analysis-spinner').hide()

      @dataTable = $("#rainfallStations").DataTable
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

    @updateRainfallDoc = (tableData) ->
      @databaseDoc.data = {}
      _(tableData).each (row) =>
        [region, district, stationName, phone_numbers] = row
        @databaseDoc.data[stationName] = {} unless @databaseDoc.data[stationName]?
        @databaseDoc.data[stationName]=
          Region: region
          District: district
        @databaseDoc.data[stationName]['Phone Numbers']= [] unless @databaseDoc.data[stationName]['Phone Numbers']?
        # phone_numbers.split(/ +|, */)
        _(phone_numbers.split(/ +|, */)).each (r) =>
          @databaseDoc.data[stationName]['Phone Numbers'].push r

    @updateDbRecord = (rec) ->
      Coconut.database.put rec,
        _rev: rec._rev
      .catch (error) -> console.error error
      .then (result) =>
        @render()
      return false

module.exports = RainfallStationView
