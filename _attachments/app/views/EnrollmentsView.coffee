_ = require 'underscore'
$ = require 'jquery'
require('jquery-ui')
Backbone = require 'backbone'
Backbone.$  = $

titleize = require "underscore.string/titleize"
slugify = require "underscore.string/slugify"

moment = require 'moment'
global.jQuery = require 'jquery'

Tabulator = require 'tabulator-tables'

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
      <div id='table-enrollments'/>
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

      data = _(result.rows).map (row) =>
        doc = row.doc
        doc.region = row.key[2]
        doc.id = doc._id
        doc["created-by"] = nameByUsername[doc["created-by"]] or "-"
        doc["school-name"] = nameByUsername[doc["created-by"]] or "-"
        doc["# of Students"] = _(doc.students).size()
        doc["updated-by"] = _(doc["updated-by"]).map( (username) => nameByUsername[username] or "-").join(",")
        doc["update-time"] = _(doc['update-time']).last() or "-"
        delete doc._id
        delete doc._rev
        delete doc.students
        doc

      console.log data

      table = new Tabulator "#table-enrollments", 
        height: "400"
        autoColumns: true
        data: data
        layout: "fitColumns"
        rowClick: (e, row) =>
          router.navigate "enrollment/#{row.getData().id}", trigger: true


    .catch (error) => console.error error


module.exports = EnrollmentsView
