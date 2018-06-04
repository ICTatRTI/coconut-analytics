_ = require 'underscore'
$ = require 'jquery'
require('jquery-ui')
Backbone = require 'backbone'
Backbone.$  = $

titleize = require "underscore.string/titleize"
slugify = require "underscore.string/slugify"

moment = require 'moment'
global.jQuery = require 'jquery'
require 'tablesorter'
DataTables = require( 'datatables.net' )()


class AttendanceView extends Backbone.View
  initialize: =>
    Coconut.reportOptions = {}

  events:
    "change #selectedYear": "updateYear"
    "change #selectedTerm": "updateTerm"
    "click .expand": "toggle"

  updateYear: =>
    @year = @$("#selectedYear").val()
    @render()

  updateTerm: =>
    @term = @$("#selectedTerm").val()
    @render()

  render: =>

    @$el.html "
      <style>
        #{
          margin = 0
          [4..8].map (level) =>
            ".level-#{level} {margin: #{margin+=20}px}"
          .join("\n")
        }
      </style>
      <h3>Attendance 
        <select id='selectedYear'>
        #{
          [2018..(new Date()).getFullYear()].map (year) =>
            "<option>#{year}</option>"
          .join("")
        }
        </select>
        Term:
        <select id='selectedTerm'>
        #{
          [1..3].map (term) =>
            "<option>#{term}</option>"
          .join("")
        }
        </select>

      </h3>
      <!--
      Search By School <input/>
      -->
      Average attendance percentage followed by the number of students. Click the number of students to show the next level of data.
      <div id='attendance-hierarchy'>
      </div>
    "

    unless @year and @term
      [@year, @term] = Calendar.getYearAndTerm() or [(new Date()).getFullYear(), 1]

    @$("#selectedYear").val(@year)
    @$("#selectedTerm").val(@term)

    @$("#attendance-hierarchy").html "
      <div id='#{@year}_#{@term}'>
    "

    @renderAttendanceResult(3).then =>
      @$(".attendance").show()
      @renderAttendanceResult(4).then =>
        @renderAttendanceResult(5).then =>
          schoolNameById = {}
          Coconut.schoolsDb.allDocs
            include_docs:true
          .then (result) =>
            _(result.rows).each (row) =>
              schoolNameById[row.id[7..]] = row.doc.Name
            @$(".school").each (index, school) =>
              $(school).html(schoolNameById[$(school).html().trim()])
          #@renderAttendanceResult(6).then =>
            #@renderAttendanceResult(7).then =>


  renderAttendanceResult: (level) =>
    Coconut.enrollmentsDb.query "attendanceByYearTermRegionSchoolClassStreamLearner",
      startkey: ["#{@year}","#{@term}"]
      endkey: ["#{@year}","#{@term}", "\uf000"]
      reduce: true
      group_level: level
    .then (result) =>
      _(result.rows).map (row) =>
        targetElement = row.key[0..-2].join("_") #Gets one level up
        lowestLevelIdentifier = row.key[level-1]
        @$("##{targetElement}").append "
          <div class='attendance level-#{level}' id='#{row.key.join("_")}' style='display:none'>
            <span class=#{if lowestLevelIdentifier.match(/\d\d\d\d/) then "school" else ""}>
              #{lowestLevelIdentifier}
            </span>: 
            #{Math.round(row.value[0])}% <button class='expand'>#{row.value[1]}</button>
          </div>
        "
      Promise.resolve()

  toggle: (event) =>
    console.log "Expand"
    $(event.target).parent().children(".attendance").toggle()

module.exports = AttendanceView
