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

global.Enrollment = require "../models/Enrollment"

ExpandableObjectView = require './ExpandableObjectView'

class ProgressView extends Backbone.View
  events:
    "change #selectedYear": "updateYear"
    "change #selectedTerm": "updateTerm"

  updateYear: =>
    @year = @$("#selectedYear").val()
    @render()

  updateTerm: =>
    @term = @$("#selectedTerm").val()
    @render()

  headers =  [
    "Region"
    "School & User(s)"
    "Score"
    "Enrollments"
  ]

  render: =>
    @$el.html "
      <style>
        .students{
          background-color: yellow
        }
        .attendance{
          background-color: orange
        }
        .spotcheck{
          background-color: lightpink
        }
        .performance{
          background-color: green
        }
        td{
          vertical-align: top;
        }
        td, th{
          padding: 2px;
        }
      </style>
      <h3>Progress by School
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

      <div id='key'>
      Each school is listed below with all of the enrollments for the selected term. A score for each enrollment is shown. For more details about the enrollment the <span style='color:rgb(255,64,129);'>enrollment name</span> can be clicked on. The name is followed by the <span style='background-color:yellow'>number of students</span>, <span style='background-color:orange'>the latest date for the attendance</span>, the <span style='background-color:lightpink'>number of spotchecks completed</span>, and the <span style='background-color:green'>average performance score</span> for the school.
      </div>

      <h3>
        <table>
          <tr>
            <td>
              Score:
            </td>
            <td id='overall-score'>
              Loading...
            </td>
          </tr>
        </table>
      </h3>

      <table id='table-schools'>
        <thead>
          #{
            headers.map (header) =>
              "<th>#{titleize(header)}</th>"
            .join("")
          }

        </thead>
        <tbody>
        </tbody>
      </table>
    "

    unless @year and @term
      [@year, @term] = Calendar.getYearAndTerm() or [(new Date()).getFullYear(), 1]

    @$("#selectedYear").val(@year)
    @$("#selectedTerm").val(@term)

    @schoolsByRegion().then =>
      @schoolResponsibility()
    .then =>
      @enrollmentsWithCount()
    .then =>
      @enrollmentAttendanceDates()
    .then =>
      @enrollmentSpotchecks()
    .then =>
      @enrollmentPerformance()
    .then =>
      @scores()
    .then =>
      @$("#table-schools").DataTable
        paging:false

  schoolsByRegion: =>

    Coconut.schoolsDB.query "schoolsByRegion",
      include_docs: true
      reduce: false
    .catch (error) => console.error error
    .then (result) =>
      _(result.rows).map (school) =>
        return if school.doc.inactive
        @$("#table-schools tbody").append "
          <tr class='school' id='#{school.id}'>
            <td class='region'>#{school.doc.Region}</td>
            <td class='name'>
              <span style='font-weight:bold'>#{school.doc.Name}</span>
              <div class='responsible'></div>
            </td>
            <td class='score'></td>
            <td class='enrollments'>
            </td>
          </tr>
        "

  schoolResponsibility: =>

    nameByUsername = {}
    Coconut.database.allDocs
      startkey: "user.",
      endkey: "user.\ufff0"
      include_docs: true
    .then (result) =>
      _(result.rows).each (row) =>
        nameByUsername[row.key.replace(/user\./,"")] = row.doc.name

      # Who is responsible for the school
      Coconut.database.query "usersBySchool"
      .then (result) =>
        _(result.rows).each (row) =>
          if row.key isnt ""
            targetElement = @$("#table-schools tbody tr##{row.key} div.responsible")
            targetElement.append(nameByUsername[row.value] + "<br/>")
            
  enrollmentsWithCount: =>
    @enrollments = []
      
    Coconut.enrollmentsDb.query "enrollmentsByYearTermRegionWithStudentCount",
      startkey: ["#{@year}","#{@term}"]
      endkey: ["#{@year}","#{@term}", "\uf000"]
      include_docs: false
      reduce: false
    .then (result) =>
      _(result.rows).each (row) =>
        @enrollments.push row.id
        enrollment = Enrollment.parseId(row.id)
        @$("#table-schools tbody tr#school-#{enrollment.schoolId} .enrollments").append "
          <div class='enrollment' id='#{slugify(row.id)}'>
            <span class='class'><a href='#enrollment/#{row.id}'>#{enrollment.className} #{enrollment.stream}</a></span>
            <span class='students'>#{row.value}</span>
            <span class='attendance'></span>
            <span class='spotcheck'></span>
            <span class='performance'></span>
            <span class='comments'></span>
          </div>
        "

  enrollmentAttendanceDates: =>
    Coconut.enrollmentsDb.query "latestRecordedAttendanceByYearTermRegion",
      startkey: ["#{@year}","#{@term}"]
      endkey: ["#{@year}","#{@term}", "\uf000"]
      include_docs: false
      reduce: false
    .then (result) =>
      _(result.rows).each (row) =>
        @$("##{slugify(row.id)} .attendance").html moment(row.value).format("DD MMM")

      Coconut.enrollmentsDb.query "attendanceByYearTermRegionSchoolClassStreamLearner",
        startkey: ["#{@year}","#{@term}"]
        endkey: ["#{@year}","#{@term}", "\uf000"]
        include_docs: false
        reduce: true
        group_level: 6
      .then (result) =>
        _(result.rows).each (row) =>
          [year,term,region,schoolId,className,stream] = _(row.key).map( (value) => value.replace(/ /,'-'))
          @$("#enrollment-school-#{schoolId}-#{year}-term-#{term}-class-#{className.toLowerCase()}-stream-#{stream.toLowerCase()} .attendance").append "- #{Math.round(row.value[0])}%"

  enrollmentSpotchecks: =>
    #spotcheck id includes the date
    Coconut.spotchecksDb.query "resultsByDate",
      startkey: Calendar.termDates[@year][@term].start
      endkey: Calendar.termDates[@year][@term].end
      reduce: false
    .then (result) =>
      console.log result
      _(result.rows).chain().groupBy (row) =>
        console.log row
        enrollmentId = row.id[10..-12]
      .each (spotchecks, enrollmentId) =>
        @$("##{slugify(enrollmentId)} .spotcheck").html (
          _(spotchecks).map (spotcheck) =>
            moment(spotcheck.key).format("DD MMM")
        ).join(", ")

  enrollmentPerformance: =>
    Coconut.enrollmentsDb.query "performanceByYearTermRegionSchoolClassStreamLearner",
      startkey: ["#{@year}","#{@term}"]
      endkey: ["#{@year}","#{@term}", "\uf000"]
      include_docs: false
      reduce: true # want the average score
      group_level: 6  # gets it per stream

    .then (result) =>
      _(result.rows).each (row) =>
        [year,term,region,schoolId, classname, streamGender] = row.key
        targetId = slugify("enrollment-school-#{schoolId}-#{year}-term-#{term}-class-#{classname}-stream-#{streamGender}")
        @$("##{targetId} .performance").html Math.round(row.value[0])

  scores: =>
    fields = [
      "students"
      "attendance"
      "spotcheck"
      "performance"
    ]
    fieldsRequiredToBeComplete = 4 # Note that we don't require spotchecks

    aggregateScore = 0
    numberOfSchools = 0
    aggregateScoreByRegion =
      Dadaab: 0
      Kakuma: 0
    numberOfSchoolsByRegion = 
      Dadaab: 0
      Kakuma: 0

    aggregateScoreByField = {}
    aggregateScoreByRegionAndField =
      Kakuma: {}
      Dadaab: {}
    aggregatePotentialScoreByField = {}
    aggregatePotentialScoreByRegionAndField =
      Kakuma: {}
      Dadaab: {}

    _(fields).each (field) =>
      aggregateScoreByField[field] = 0
      aggregatePotentialScoreByField[field] = 0
      for region in ["Dadaab", "Kakuma"]
        aggregateScoreByRegionAndField[region][field] = 0
        aggregatePotentialScoreByRegionAndField[region][field] = 0

    $("tr.school").each (rowNumber, schoolRow) =>
      enrollmentCount = 0
      enrollmentScore = 0

      region = $(schoolRow).find(".region").html()

      $(schoolRow).find(".enrollment").each (number, enrollmentElement) =>
        enrollmentElement = $(enrollmentElement)
        enrollmentCount += 1
        
        #calculate the score
        _(fields).each (field) =>
          fieldResult = enrollmentElement.find(".#{field}")
          aggregatePotentialScoreByField[field] += 1
          aggregatePotentialScoreByRegionAndField[region][field] += 1
          if fieldResult.length > 0 and
            fieldResult.html() isnt "0" and
            fieldResult.html() isnt ""
              enrollmentScore += 1
              aggregateScoreByField[field] += 1
              aggregateScoreByRegionAndField[region][field] += 1
      schoolScore = enrollmentScore/(enrollmentCount*fieldsRequiredToBeComplete) || 0
      $(schoolRow).find(".score").html (schoolScore*100).toFixed(0)+"%"
      aggregateScore += schoolScore
      numberOfSchools += 1
      aggregateScoreByRegion[region] += schoolScore
      numberOfSchoolsByRegion[region] += 1

    overallScore = aggregateScore/numberOfSchools
    $('#overall-score').html "
      <div>
      Overall: #{(overallScore*100).toFixed(0)+"%"} 
      <small>
        #{
          _(fields).map (field) ->
            "<span class='#{field}'>#{titleize(field)}: #{Math.round(100*aggregateScoreByField[field]/aggregatePotentialScoreByField[field])}% </span>"
          .join(", ")
        }
      </small>
      </div>


      #{
        (for region in ["Dadaab","Kakuma"]
          console.log aggregateScoreByRegion[region]
          console.log numberOfSchoolsByRegion[region]
          overallScoreByRegion = aggregateScoreByRegion[region]/numberOfSchoolsByRegion[region]
          "
          <div>
          Overall #{region}: #{(overallScoreByRegion*100).toFixed(0)+"%"} 
          <small>
            #{
              _(fields).map (field) ->
                "<span class='#{field}'>#{titleize(field)}: #{Math.round(100*aggregateScoreByRegionAndField[region][field]/aggregatePotentialScoreByRegionAndField[region][field])}% </span>"
              .join(", ")
            }
          </small>
          </div>
          "
        ).join("")
      }
    "

module.exports = ProgressView
