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

  #events:
    #

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
      <h1>Users #{Calendar.getYearAndTerm().join("-t")}  </h1>
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

    Coconut.database.allDocs
      startkey: "user.",
      endkey: "user.\ufff0"
      include_docs: true
    .then (result) =>
      @$("#table-users tbody").html( _(result.rows).map (row) =>
        "
        <tr id='row-#{slugify(row.id)}'>
          #{
            headers.map (header) =>
              "<td class='#{slugify(header)}'>
                #{
                  data = row.doc[header]
                  if _(data).isString()
                    data
                  else if header is "username"
                    row.id
                  else if header is "schools"
                    _.delay =>
                      console.log data
                      Promise.all(_(data)?.map (school) =>
                        Coconut.schoolsDb.get(school)
                        .then (result) =>
                          console.log result
                          Promise.resolve(result.Name)
                      ).then (schoolNames) =>
                        console.log schoolNames
                        @$("#row-#{slugify(row.id)} td.schools").html(schoolNames.join(","))

                    ,1000
                  else if header is "# of enrollments"
                    "-"
                  else
                    console.error "Can't render #{data} for #{header}"
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
      Coconut.enrollmentsDb.query "enrollmentsByYearTermRegion",
        startkey: Calendar.getYearAndTerm()
        endkey: Calendar.getYearAndTerm().concat("\uf000")
        include_docs:true
        reduce: false
      .then (result) =>
        _(result.rows).chain().groupBy (row) =>
          row.doc["created-by"]
        .each (rows, user) =>
          @$("#row-user-#{user} td.of-enrollments").html(rows.length)
      .then =>
        Coconut.schoolsDB
      .then =>


        @$("#table-users").DataTable
          paging:false
        @$("#table-users td.of-enrollments").each (index,element) =>
          element = $(element)
          element.addClass("warn") if element.html() is " - "
          element.addClass("warn") if parseInt(element.html()) < 5


    .catch (error) => console.error error


module.exports = UsersReportView
