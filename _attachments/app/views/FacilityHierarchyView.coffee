_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
PouchDB = require 'pouchdb'
moment = require 'moment'

DataTables = require 'datatables'

class FacilityHierarchyView extends Backbone.View
  el: '#content'
  
  render: ->
    options = Coconut.router.reportViewOptions
    $('#analysis-spinner').show()
    @$el.html "
      <h3>Manage Facilities</h3>
      <table class='tablesorter' id='facilityHierarchy'>
        <thead>
          <th>Region</th>
          <th>District</th>
          <th>Facility Name</th>
          <th>Aliases</th>
          <th>Phone Numbers</th>
          <th>Type</th>
          <th>Delete</th>
        </thead>
        <tbody>
        </tbody>
      </table>
    "
    $('#analysis-spinner').hide()

    $("#facilityHierarchy").dataTable
      aaSorting: [[1,"desc"],[2,"desc"]]
      iDisplayLength: 50
      dom: 'T<"clear">lfrtip'
      tableTools:
        sSwfPath: "js-libraries/copy_csv_xls.swf"
        aButtons: [
          "copy",
          "csv",
          "print"
        ]

module.exports = FacilityHierarchyView