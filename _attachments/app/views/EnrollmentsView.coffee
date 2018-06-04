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

  events:
    "change #selectedYear": "updateYear"
    "change #selectedTerm": "updateTerm"

  updateYear: =>
    @year = @$("#selectedYear").val()
    @render()

  updateTerm: =>
    @term = @$("#selectedTerm").val()
    @render()

  throttledRender: =>
    _.throttle => @render

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
        #table-enrollments tr.even{
          background-color: #DCDCDC;
        }
        #table-enrollments a{
          font-decoration:none;
          color:black;
        }
      </style>
      <h3>Enrollments 
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
      (Click an enrollment for more details)<br/>
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

    unless @year and @term
      [@year, @term] = Calendar.getYearAndTerm() or [(new Date()).getFullYear(), 1]

    @$("#selectedYear").val(@year)
    @$("#selectedTerm").val(@term)

    nameByUsername = {}
    Coconut.database.allDocs
      startkey: "user.",
      endkey: "user.\ufff0"
      include_docs: true
    .then (result) =>
      _(result.rows).each (row) =>
        nameByUsername[row.key.replace(/user\./,"")] = row.doc.name


    Coconut.enrollmentsDb.query "enrollmentsByYearTermRegion",
      startkey: ["#{@year}","#{@term}"]
      endkey: ["#{@year}","#{@term}", "\uf000"]
      include_docs:true
      reduce: false
    .then (result) =>
      console.log result
      @$("#table-enrollments tbody").html( _(result.rows).map (row) =>
        "
        <tr class='enrollment-row' id='#{row.id}'>
          #{
            headers.map (header) =>
              "<td class='#{slugify(header)}'>
                <a href='#enrollment/#{row.id}'>
                #{
                  data = row.doc[header]
                  if header is "region"
                    row.key[2]
                  else if header is "# of Students"
                    _(row.doc.students).size()
                  else if header is "update-time"
                    _(row.doc[header]).last() or "-"
                  else if header is "created-by"
                    nameByUsername[data] or "-"
                  else if header is "updated-by"
                    _(data).map (username) =>
                      nameByUsername[username] or "-"
                    .join(",")
                  else if _(row.doc[header]).isString()
                    data
                  else if _(row.doc[header]).isArray()
                    data.join(", ")
                  else
                    console.error "Can't render #{data} for #{header}"
                    ""
                  
                }
                </a>
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
