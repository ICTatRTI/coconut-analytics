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
    event.stopPropagation()
    Person.get(@$(event.target).attr("data-id")).then (person) =>
      SweetAlert(
        title: "#{person.name()}"
        html: " "
        showCloseButton: false
        focusConfirm: true
        confirmButtonText: 'Close'
      )

      expandableObject = new ExpandableObjectView(person.doc)
      expandableObject.setElement $("<div/>") # Make an element not on the DOM
      expandableObject.render()
      $("#swal2-content").append expandableObject.$el


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
                          _(peopleByRegistrationNumber).map (person, registrationNumber) =>
                            "#{registrationNumber}: #{person.name()} <span class='person-details' data-id='#{person.id()}'>?</span><br/>"
                          .join("")
                        else if header is "update-time"
                          _(data).last() or "-"
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
                        else if _(data).isString() or _(data).isNumber()
                          data
                        else if _(data).isArray()
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



    .catch (error) => console.error error

module.exports = EnrollmentView
