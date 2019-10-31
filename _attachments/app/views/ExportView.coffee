$ = require 'jquery'

Backbone = require 'backbone'
Backbone.$  = $
global.FileSaver = require 'file-saver'
dasherize = require("underscore.string/dasherize")

class ExportView extends Backbone.View

  events:
    "click button.download-csv": "downloadCsv"
    "change #selectedYear": "updateYear"
    "change #selectedTerm": "updateTerm"

  updateYear: =>
    @year = @$("#selectedYear").val()
    @render()

  updateTerm: =>
    @term = @$("#selectedTerm").val()
    @render()

  # Need to keep in sync with __view
  fields: [
    "Year"
    "Term"
    "Region"
    "SchoolId"
    "Class"
    "Stream"
    "PersonId"
    "Name"
    "Sex"
    "Attendance - Days Eligible"
    "Attendance - Days Present"
    "Attendance - Percent"
    "Spotcheck - Jan"
    "Spotcheck - Feb"
    "Spotcheck - Mar"
    "Spotcheck - Apr"
    "Spotcheck - May"
    "Spotcheck - Jun"
    "Spotcheck - Jul"
    "Spotcheck - Aug"
    "Spotcheck - Sep"
    "Spotcheck - Oct"
    "Spotcheck - Nov"
    "Spotcheck - Dec"
    "Spotchecks - # Performed"
    "Spotchecks - # Present For"
    "Spotchecks - Attendance Mismatches"
    "Performance - English"
    "Performance - Kiswahili"
    "Performance - Maths"
    "Performance - Science"
    "Performance - Social Studies"
    "Performance - Biology"
    "Performance - Physics"
    "Performance - Chemistry"
    "Performance - History"
    "Performance - Geography"
    "Performance - Christian Religious Education"
    "Performance - Islamic Religious Education"
    "Performance - Music"
    "Performance - Home Science"
    "Performance - Art and Craft"
    "Performance - Agriculture"
    "Performance - Arabic"
    "Performance - German"
    "Performance - French"
    "Performance - Business Studies"
    "Performance - Computer"
  ]


  downloadCsv: =>

   Coconut.peopleDB.query "attendancePerformanceByYearTermRegionSchoolClassStreamLearner",
     include_docs: false
     startkey: [@year, @term]
     endkey: [@year, @term, {}]
   .then (result) =>
      csv = @fields.join(",")+"\n"
      _(result.rows).map (row) ->
        csv += row.value + "\n"
      blob = new Blob([csv], {type: "text/plain;charset=utf-8"})
      FileSaver.saveAs(blob, "coconut-keep-#{@year}-#{@term}.csv")
      $('#downloadMsg').hide()
      $('#analysis-spinner').hide()
    .catch (error) -> console.error error

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
      <h3>Learners
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
      <button class='download-csv'>Download CSV</button>
    "

    unless @year and @term
      [@year, @term] = Calendar.getYearAndTerm() or [(new Date()).getFullYear().toString(), "1"]

    @$("#selectedYear").val(@year)
    @$("#selectedTerm").val(@term)

module.exports = ExportView
