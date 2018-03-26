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


class EnrollmentsView extends Backbone.View
  initialize: =>
    Coconut.reportOptions = {}

  #events:
    #

  headers =  [
    "creation-time"
    "created-by"
    "region"
    "school-name"
    "class"
    "stream"
    "sex"
    "# of Students"
    "year"
    "term"
    "updated-by"
    "update-time"
  ]

  render: =>
    @options = $.extend({},Coconut.reportOptions)
#    Coconut.reportOptions.byRegion = Coconut.reportOptions.byRegion || "KAKUMA"

    @$el.html "
      <style>
        #table-enrollments td.warn{
          background-color: #ff4081
        }
      </style>
      <h1>Enrollments #{Calendar.getYearAndTerm().join("-t")}  </h1>
      <table id='table-enrollments'>
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

    Coconut.enrollmentsDb.query "enrollmentsByYearTermRegion",
      startkey: Calendar.getYearAndTerm()
      endkey: Calendar.getYearAndTerm().concat("\uf000")
      include_docs:true
      reduce: false
    .then (result) =>
      @$("#table-enrollments tbody").html( _(result.rows).map (row) =>
        "
        <tr>
          #{
            headers.map (header) =>
              "<td class='#{slugify(header)}'>
              #{
                data = row.doc[header]
                if header is "region"
                  row.key[2]
                else if header is "# of Students"
                  _(row.doc.students).size()
                else if _(row.doc[header]).isString()
                  data
                else if _(row.doc[header]).isArray()
                  data.join(", ")
                else
                  console.error "Can't render #{data} for #{header}"
                  ""
                
              }
              </td>"
            .join("")
          }

        </tr>
        "
      )

      @$("#table-enrollments").DataTable
        paging:false
      @$("#table-enrollments td.of-students").each (index,element) =>
        element = $(element)
        element.addClass("warn") if parseInt(element.html()) < 10


    .catch (error) => console.error error


module.exports = EnrollmentsView
