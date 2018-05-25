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


class UsersReportView extends Backbone.View
  initialize: =>
    Coconut.reportOptions = {}

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
    "username"
    "name"
    "region"
    "schools"
    "# of enrollments"
    "# of spot checks"
  ]

  render: =>
    @options = $.extend({},Coconut.reportOptions)
#    Coconut.reportOptions.byRegion = Coconut.reportOptions.byRegion || "KAKUMA"

    @$el.html "
      <style>
        #table-users td.warn{
          background-color: #ff4081
        }
      </style>

      <h3>Users 
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

      <table id='table-users'>
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

    if @year and @term
      @$("#selectedYear").val(@year)
      @$("#selectedTerm").val(@term)
    else
      [@year, @term] = Calendar.getYearAndTerm() or [(new Date()).getFullYear(), 1]

    Coconut.database.allDocs
      startkey: "user.",
      endkey: "user.\ufff0"
      include_docs: true
    .then (result) =>
      @$("#table-users tbody").html( _(result.rows).map (row) =>
        return if row.id is "user.admin"
        return if row.doc.inactive
        "
        <tr id='row-#{slugify(row.id)}'>
          #{
            headers.map (header) =>
              "<td class='#{slugify(header)}'>
                #{
                  data = row.doc[header]
                  if header is "username"
                    row.id.replace(/user-/,"")
                  else if header is "schools"
                    "-"
                  else if header is "# of enrollments"
                    "-"
                  else if _(data).isString()
                    data
                  else
                    console.info "Can't render #{data} for #{header}"
                    ""
                }
                </td>
              "
            .join("")
          }
        </tr>
        "
      )



    .then =>
      Coconut.schoolsDb.allDocs
        include_docs: true
      .then (result) =>
        regionBySchoolId = {}
        _(result.rows).each (row) =>
          regionBySchoolId[row.id.replace(/school-/,"")] = row.doc.Region

        Coconut.enrollmentsDb.query "enrollmentsByYearTermRegion",
          startkey: ["#{@year}","#{@term}"]
          endkey: ["#{@year}","#{@term}", "\uf000"]
          include_docs:true
          reduce: false
        .then (result) =>
          enrollmentNumberByUser = {}
          enrollmentSchoolNameByUser = {}
          enrollmentRegionByUser = {}

          _(result.rows).each (row) =>
            _(row.doc["updated-by"]).each (user) =>
              enrollmentNumberByUser[user] or= 0
              enrollmentNumberByUser[user]+=1

              enrollmentSchoolNameByUser[user] or= []
              enrollmentSchoolNameByUser[user].push row.doc["school-name"]
              enrollmentRegionByUser[user] or= []
              enrollmentRegionByUser[user].push regionBySchoolId[row.doc["school-id"]] or "-"
          
          _(enrollmentNumberByUser).each (numberOfEnrollments, user) =>
            @$("#row-user-#{user} td.of-enrollments").html(numberOfEnrollments)

          _(enrollmentSchoolNameByUser).each (schools, user) =>
            @$("#row-user-#{user} td.schools").html(_(schools).uniq().join(","))

          _(enrollmentRegionByUser).each (regions, user) =>
            @$("#row-user-#{user} td.region").html(_(regions).uniq().join(","))


        .then =>
          @$("#table-users td.of-enrollments").each (index,element) =>
            element = $(element)
            element.addClass("warn") if element.html() is " - "
            element.addClass("warn") if parseInt(element.html()) < 5
          _.delay =>
            @$("#table-users").DataTable
              paging:false
          , 1000


        .catch (error) => console.error error


module.exports = UsersReportView
