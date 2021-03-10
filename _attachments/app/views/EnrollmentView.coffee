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
SweetAlert = require('sweetalert2')

global.Enrollment = require "../models/Enrollment"
global.Person = require "../models/Person"

ExpandableObjectView = require './ExpandableObjectView'

class EnrollmentView extends Backbone.View
  events:
    "click .person-details": "personDetails"
    "click #delete": "delete"

  delete: =>
    if confirm "Are you sure want to delete this enrollment?"
      Coconut.enrollmentsDB.remove(@enrollment.doc).then =>
        Coconut.router.navigate("reports/type/enrollments", {trigger:true})

  personDetails: (event) =>
    personId = @$(event.target).attr("data-id")
    Coconut.router.navigate "person/#{personId}", trigger:true

  headers: [
    "creation-time"
    "created-by"
    "school-name"
    "class"
    "stream"
    "sex"
    "students"
    "year"
    "term"
    "updated-by"
    "update-time"
    "attendance"
    "performance"
    "spotchecks"
  ]

  render: =>
    Enrollment.get @enrollmentId
    .then (@enrollment) =>
      @enrollment.peopleByRegistrationNumber().then (peopleByRegistrationNumber) =>

        @$el.html "
          <style>
            #table-enrollment .header{
              vertical-align:top;
            }
            #table-enrollment tr.even{
              background-color: #DCDCDC;
            }
            .person-details{
              color: #ff4081;
            }
          </style>
          <h3>
            Enrollment: #{@enrollment.toHtmlString()} 
            <i id='delete' class='mdi mdi-delete mdi-24px'></i>

          </h3>
          <table id='table-enrollment'>
            <tbody>
              #{

                extraFields = _(@enrollment.doc).chain().keys().difference(@headers).value()
                @headers = @headers.concat(extraFields) # Just in case new fields have been added to the enrollment

                @headers.map (header, index) =>
                  "
                  <tr class='#{slugify(header)} #{if index%2 is 0 then "even" else "odd"}'>
                    <td class='header'>#{titleize(header)}</td>
                    <td class='data'>
                      #{
                        data = @enrollment.doc[header]
                        if header is "students"

                          performanceCategories = {}
                          for studentId, performanceData of @enrollment.doc.performance
                            for category, result of performanceData
                              performanceCategories[category] = true

                          console.log performanceCategories
                          "
                          <style>
                            .students th{
                              padding: 5px;
                            }
                          </style>
                          <table>
                          <thead>
                          <tr class='students'>
                            <th>Reg Number</th>
                            <th>Name</th>
                            #{
                              (for performanceCategory in Object.keys(performanceCategories)
                                "<th>#{titleize performanceCategory}</th>"
                              ).join("")
                            }
                          </tr>
                          </thead>
                          <tbody>
                          #{

                            (for registrationNumber, person of peopleByRegistrationNumber
                              "
                              <tr>
                                <td>#{registrationNumber}</td>
                                <td>
                                  <a href='#person/#{person.id()}'>#{person.name()}</a>
                                </td>
                                #{
                                  (for performanceCategory in Object.keys(performanceCategories)
                                    "<td>#{@enrollment.doc.performance?[person.id()]?[performanceCategory] or "-"}</td>"
                                  ).join("")
                                }
                              </tr>
                              "
                            ).join("")
                          }
                          </tbody>
                          </table>
                          "

                        else if header is "attendance"
                          _(@enrollment.attendanceSummary()).map (value, property) =>
                            return if property is "Score"
                            "#{property} : #{value}"
                          .join("<br/>")
                        else if header is "performance"
                          _(@enrollment.performanceSummary()).map (value, property) =>
                            return if property is "Score"
                            "#{property} : #{value}"
                          .join("<br/>")
                        else if header is "spotchecks"
                          "<div id='spotchecks'>Loading...</div>"
                        else if _(data).isString() or _(data).isNumber()
                          data
                        else if _(data).isArray()
                          if header is "update-time"
                            data.pop()
                          else
                            data.join(", ")
                        else
                          console.error "Can't render #{data} for #{header}"
                          ""
                      }
                    </td>
                  </tr>
                  "
                .join("")
              }
            </tbody>
          </table>
        "

        [a,b,schoolId, year, c, term, d, className, e, stream, gender] = @enrollment.doc._id.split(/-/)

        Coconut.schoolsDb.get "school-#{schoolId}"
        .then (school) =>
          _(["attendance", "performance"]).each (aggregateType) =>
            Coconut.enrollmentsDb.query "#{aggregateType}ByYearTermRegionSchoolClassStreamLearner",
              startkey: [year, term, school.Region, schoolId, className, "#{stream}-#{gender}"]
              endkey: [year, term, school.Region, schoolId, className, "#{stream}-#{gender}", {}]
              reduce: true
              group_level: 6
            .then (result) =>
              if result.rows[0]
                $("tr.#{aggregateType} .data").html "
                  #{Math.round result.rows[0].value[0]} (for #{result.rows[0].value[1]} records#{if aggregateType is "attendance" then ", latest date: #{@enrollment.latestAttendanceDate()}" else ""})
                "
        Coconut.spotchecksDb.allDocs
          startkey: "spotcheck-#{@enrollment.doc._id}"
          endkey: "spotcheck-#{@enrollment.doc._id}\uf000"
          include_docs: true
        .then (result) =>
          @$("#spotchecks").html(
            (for row in result.rows
              "
                #{row.doc.date}
                #{
                  if row.doc.latitude and row.doc.longitude and row.doc.accuracy
                    "
                      - <a href='#{"https://www.google.com/maps/search/?api=1&query=#{row.doc.latitude},#{row.doc.longitude}"}'>Map </a> #{row.doc.accuracy}
                    "
                  else
                    "No location data"
                }
              "
            ).join("<br/>")
          )
    .catch (error) => console.error error

module.exports = EnrollmentView
