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

class AggregatingAverageView extends Backbone.View
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
      <h3>#{@title} 
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
      Averaged percentage followed by the number of students. Click the number of students to show the next level of data.
      <div style='font-size: small; color: rgb(33,150,243)' id='message'></div>
      <div id='data-hierarchy'>
      </div>
    "

    unless @year and @term
      [@year, @term] = Calendar.getYearAndTerm() or [(new Date()).getFullYear(), 1]

    @$("#selectedYear").val(@year)
    @$("#selectedTerm").val(@term)

    @$("#data-hierarchy").html "
      <div id='#{@year}-#{@term}'>
    "

    $("#message").html("Loading Regions")
    @renderDataResult(3).then =>
      @$(".data").show()
      $("#message").html("Loading Schools")
      @renderDataResult(4).then =>
        schoolNameById = {}
        Coconut.schoolsDb.allDocs
          include_docs:true
        .then (result) =>
          _(result.rows).each (row) =>
            schoolNameById[row.id[7..]] = row.doc.Name
          @$(".school").each (index, school) =>
            $(school).html(schoolNameById[$(school).html().trim()])
        $("#message").html("Loading Classes")
        @renderDataResult(5).then =>
          $("#message").html("Loading Streams")
          @renderDataResult(6).then =>
            $("#message").html("Loading Learners")
            @renderDataResult(7).then =>
              $("#message").html("All data loaded")


  renderDataResult: (level) =>
    #Coconut.enrollmentsDb.query "attendanceByYearTermRegionSchoolClassStreamLearner",
    Coconut.enrollmentsDb.query @query,
      startkey: ["#{@year}","#{@term}"]
      endkey: ["#{@year}","#{@term}", "\uf000"]
      reduce: if level is 7 then false else true # No need to reduce for last level
      group_level: if level is 7 then 0 else level
    .then (result) =>
      _(result.rows).map (row) =>
        return unless row.value # Had some bad data
        targetElement = slugify(row.key[0..-2]) #Gets one level up
        lowestLevelIdentifier = row.key[level-1]
        @$("##{targetElement}").append "
          <div class='data level-#{level}' id='#{slugify(row.key)}' style='display:none'>
            <span class=#{if lowestLevelIdentifier.match(/\d\d\d\d/) then "school" else ""}>
              #{lowestLevelIdentifier}
              #{
                if level is 6
                  [year, term, region, schoolId, className, streamGender]  = row.key
                  "<a href='#enrollment/enrollment-school-#{schoolId}-#{year}-term-#{term}-class-#{className}-stream-#{streamGender}'>View Enrollment Details</a>"
                else
                  ""
              }

            </span>: 
              #{
                if row.value[0]
                  "
                    #{Math.round(row.value[0])}%
                    <button class='expand'>#{row.value[1]}</button>
                  "
                else
                  row.value + "%"
              }
          </div>
        "
      Promise.resolve()

  toggle: (event) =>
    $(event.target).parent().children(".data").toggle()

module.exports = AggregatingAverageView
