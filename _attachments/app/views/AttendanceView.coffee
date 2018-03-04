_ = require 'underscore'
$ = require 'jquery'
require('jquery-ui')
Backbone = require 'backbone'
Backbone.$  = $

moment = require 'moment'
global.jQuery = require 'jquery'
require 'tablesorter'
DataTables = require( 'datatables.net' )()


class AttendanceView extends Backbone.View
  el: "#content"
  initialize: =>
    Coconut.reportOptions = {}

  events:
    "click button.caseBtn": "showCaseDialog"
    "click button#closeDialog": "closeDialog"
    "click button#submitBtn": "updateFilters"
    "change [name=aggregationType]": "updateRegion"

  showCaseDialog: (e) ->
    caseID = $(e.target).parent().attr('id') || $(e.target).attr('id')
    Case.showCaseDialog
      caseID: caseID
      success: ->
    return false

  closeDialog: () ->
    caseDialog.close() if caseDialog.open

  updateFilters: (e) ->
    Coconut.reportOptions.byRegion = $("#byRegion option:selected").val()
    Coconut.reportOptions.byYear = $("#byYear option:selected").val()
    Coconut.reportOptions.byTerm = $("#byTerm option:selected").val()
    Coconut.reportOptions.bySchool = $("#bySchool option:selected").val()
    console.log(Coconut.reportOptions)
    renderData()

  renderData = () =>
    $('#analysis-spinner').show()
    Coconut.peopleDb.query "attendanceByYearTermRegionSchool",
       startkey: [Coconut.reportOptions.byYear,Coconut.reportOptions.byTerm,Coconut.reportOptions.byRegion, Coconut.reportOptions.bySchool]
       endkey: [Coconut.reportOptions.byYear,Coconut.reportOptions.byTerm,Coconut.reportOptions.byRegion, Coconut.reportOptions.bySchool,{}]
       include_docs: true
    .catch (error) ->
       coconut.debug "Error: #{JSON.stringify error}"
       console.error error
    .then (result) =>
        # results = _.filter(result.rows, (student) ->
        #   return student.key[2].toUpperCase() is Coconut.reportOptions.byRegion
        # )
        students = _(result.rows).pluck("doc")
        console.log(students)
        tableContent = _.map(students,(student) ->
          console.log(student)
          for date, rec of student['Performance and Attendance']
              "
                <tr>
                  <td>#{rec['Student Name']}</td>
                  <td>#{rec['Student Code']}</td>
                  <td>#{rec.Sex}</td>
                  <td>#{rec.Class}</td>
                  <td class='text-right'>#{rec.Perf_T1_2017}</td>
                  <td class='text-right'>#{rec.Att_T1_2017}</td>
                  <td class='text-right'>#{rec['Att_T1_2017_%']}</td>
                </tr>
              "
        ).join("")
        $("table.summary tbody").html(tableContent)
        $('#analysis-spinner').hide()
        @dataTable = $("table.summary").DataTable
           "order": [[0,"asc"]]
           "pagingType": "full_numbers"
           "dom": '<"top"fl>rt<"bottom"ip><"clear">'
           "lengthMenu": [[10, 25, 50, 100, -1], [10, 25, 50, 100, "All"]]
           "retrieve": true
           "iDisplayLength": 50

  render: =>
    @options = $.extend({},Coconut.reportOptions)
#    Coconut.reportOptions.byRegion = Coconut.reportOptions.byRegion || "KAKUMA"
    @byYear = @options.byYear or moment().format("YYYY")
    @byTerm = @options.byTerm or "All"
    @bySchools = []
    HTMLHelpers.ChangeTitle("Reports: Attendance")
    view = @
    Coconut.schoolsDb.allDocs
      include_docs: true
    .catch (error) ->
      console.error error
      @schools = []
    .then (result) ->
      @schools = result.rows
      view.$el.html "
        <style>
          .mdl-data-table th, .mdl-data-table td {text-align: left;}
          .filter-grid.mdl-grid {padding: 0px;}
          .filter-grid div.mdl-cell {margin: 2px;}
        </style>
        <div class='filter-grid mdl-grid'>
          <div class='mdl-cell mdl-cell--1-col'>
            Region:
          </div>
          <div class='mdl-cell mdl-cell--8-col'>
            <select id='byRegion' class='aggregatedBy'>
            #{
              _("Kakuma,Dadaab,All".split(",")).map (byRegion) =>
                "
                  <option #{if byRegion is @byRegion then "selected='true'" else ''}>
                    #{byRegion}
                  </option>"
              .join ""
            }
            </select>
          </div>
        </div>
        <div class='filter-grid mdl-grid'>
          <div class='mdl-cell mdl-cell--1-col'>
            Year:
          </div>
          <div class='mdl-cell mdl-cell--8-col'>
            <select id='byYear' class='aggregatedBy'>
              #{
                _("2017,2018,All".split(",")).map (byYear) =>
                  "
                    <option #{if byYear is @byYear then "selected='true'" else ''}>
                      #{byYear}
                    </option>"
                .join ""
              }
            </select>
          </div>
        </div>
        <div class='filter-grid mdl-grid'>
          <div class='mdl-cell mdl-cell--1-col'>
            Term:
          </div>
          <div class='mdl-cell mdl-cell--8-col'>
            <select id='byTerm' class='aggregatedBy'>
                #{
                  _("1,2,3, All".split(",")).map (byTerm) =>
                    "
                      <option #{if byTerm is @byTerm then "selected='true'" else ''}>
                        #{byTerm}
                      </option>"
                  .join ""
                }
            </select>
          </div>
        </div>
        <div class='filter-grid mdl-grid'>
          <div class='mdl-cell mdl-cell--1-col'>
            School:
          </div>
          <div class='mdl-cell mdl-cell--5-col'>
            <select id='bySchool' class='aggregatedBy'>
                #{
                  schools = _(@schools).pluck("doc")
                  _.map(schools,(school) ->
                    "
                      <option value='#{school['KEEP Assigned Code']}'>
                        #{school.Name} (#{school['KEEP Assigned Code']})
                      </option>"
                  ).join ""
                }
            </select>
          </div>
          <div class='mdl-cell mdl-cell--3-col'>
            <button class='mdl-button mdl-js-button mdl-button--raised mdl-button--colored' id='submitBtn' type='submit' >Get Results</button>
          </div>
        </div>
        <hr/>
        </div>
        <table class='summary mdl-data-table mdl-js-data-table mdl-shadow--2dp'>
          <thead>
            <tr>
              <th>Student Name</th>
              <th>Student ID</th>
              <th>Gender</th>
              <th>Class</th>
              <th>Performance</th>
              <th>Attendance</th>
              <th>Attendance%</th>
            </tr>
          </thead>
          <tbody>
          </tbody>
        </table>
      "
#      renderData()
#      componentHandler.upgradeDom()

module.exports = AttendanceView
