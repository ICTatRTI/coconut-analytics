_ = require 'underscore'

class TermDatesView extends Backbone.View

  render: =>
    @$el.html "
      <style>
        .row{
          margin: 20px;
        }
      </style>
      <h1>Term Dates</h1>
      (Note that after making a change here in order for the CSV export to work we also need to manually edit the database query: attendancePerformanceByYearTermRegionSchoolClassStreamLearner.coffee)
      #{
        termDates = Calendar.termDates
        currentYear = new Date().getFullYear()
        nextYear = new Date().getFullYear()+1

        for year in [currentYear, nextYear]
          unless termDates[year]
            termDates[year] =
              1:
                start: "#{year}-01-01"
                end: "#{year}-04-01"
              2:
                start: "#{year}-05-01"
                end: "#{year}-09-01"
              3:
                start: "#{year}-10-01"
                end: "#{year}-12-01"

        termDates[2020][4] or=
          start: "2021-01-01"
          end: "2021-01-31"
        termDates[2020][5] or=
          start: "2021-02-01"
          end: "2021-02-28"

        data = for year, terms of termDates
          for term, dates of terms
            "
              <div class='row'>
                #{year} T#{term} 
                <input class='termDate' data-year-term='#{year}-#{term}' data-year-term-type='start' type='date' value='#{dates.start}'></input>
                - 
                <input class='termDate' data-year-term='#{year}-#{term}' data-year-term-type='end' type='date' value='#{dates.end}'></input>
              </div>
            "
        _(data).flatten().join("")
      }
    "

  events: =>
    "change .termDate": "update"

  update: (event) =>
    [year,term] = event.target.getAttribute("data-year-term").split(/-/)
    type = event.target.getAttribute("data-year-term-type")
    newValue = event.target.value

    if confirm "Are you sure you want to change the #{type.toUpperCase()} date for #{year} Term #{term} to: #{newValue}?"


      newTermDateData = {}
      for element in @$(".termDate")
        [year,term] = element.getAttribute("data-year-term").split(/-/)
        type = element.getAttribute("data-year-term-type")
        newTermDateData[year] or= {}
        newTermDateData[year][term] or= {}
        newTermDateData[year][term][type] = element.value

      await Coconut.database.upsert "Term Dates", (doc) =>
        doc.data = newTermDateData
        doc

      Calendar.load()

module.exports = TermDatesView
