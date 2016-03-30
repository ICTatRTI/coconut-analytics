_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
PouchDB = require 'pouchdb'
moment = require 'moment'

DataTables = require 'datatables'

class GeoHierarchyView extends Backbone.View
  el: '#content'
  
  render: ->
    options = Coconut.router.reportViewOptions
    $('#analysis-spinner').show()
    @$el.html "
      <h3>Manage Geo Hierarchy</h3>
      <table class='tablesorter' id='geoHierarchy'>
        <thead>
          <th>Region</th>
          <th>District</th>
          <th>Shehia</th>
          <th>Delete</th>
        </thead>
        <tbody>
        </tbody>
      </table>
    "
    $('#analysis-spinner').hide()

    $("#geoHierarchy").dataTable
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

module.exports = GeoHierarchyView