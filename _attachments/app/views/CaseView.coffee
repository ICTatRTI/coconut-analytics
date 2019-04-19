_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
Question = require '../models/Question'

DataTables = require( 'datatables.net' )()

class CaseView extends Backbone.View
  el: '#content'

  render: (scrollTargetID) =>

    Coconut.case = @case
    tables = [
      "Summary"
      "USSD Notification"
      "Case Notification"
      "Facility"
      "Household"
      "Household Members"
    ]
    @$el.html "
      <style>
        table#caseTable {width: 95%; margin-bottom: 30px}
        table#caseTable th {width: 47%; font-weight: bold; font-size: 1.1em}
      </style>

      <h3>Case ID: #{@case.MalariaCaseID()}</h3>
      <h3>Diagnosis Date: #{@case.IndexCaseDiagnosisDate()}</h3>
      <h3>Classification: TODO</h3>
      <h5>Last Modified: #{@case.LastModifiedAt()}</h5>
    "

    @mappings = {
      createdAt: "Created At"
      lastModifiedAt: "Last Modified At"
      question: "Question"
      user: "User"
      complete: "Complete"
      savedBy: "Saved By"
    }

    # USSD Notification doesn't have a mapping
    finished = _.after 4, =>
      @$el.append _.map(tables, (tableType) =>
        if (tableType is "Summary")
          @createObjectTable(tableType,@case.summaryCollection())
        else if @case[tableType]?
          if tableType is "Household Members"
            _.map(@case[tableType], (householdMember) =>
              @createObjectTable(tableType,householdMember)
            ).join("")
          else
            @createObjectTable(tableType,@case[tableType])
      ).join("")
      _.each $('table tr'), (row, index) ->
        $(row).addClass("odd") if index%2 is 1
      #$('html, body').animate({ scrollTop: $("##{scrollTargetID}").offset().top }, 'slow') if scrollTargetID?

    _(tables).each (question) =>
      question = new Question(id: question)
      question.fetch
        success: =>
          _.extend(@mappings, question.safeLabelsToLabelsMappings())
          finished()
          


  createObjectTable: (name,object) =>
    "
    <div style='height: 40px; font-size:xx-large; cursor:pointer' class='toggleNext'>#{name} ⇩</div>
    <div style='display:none' class='objectTable'>
      #{
        if object._id?
          "<small><a href='#delete/result/#{object._id}'>Delete</a></small>"
        else ""
      }
      <table class='mdl-data-table mdl-js-data-table mdl-data-table--selectable mdl-shadow--2dp' id='caseTable'>
        <thead>
          <tr>
            <th class='mdl-data-table__cell--non-numeric'>Field</th>
            <th class='mdl-data-table__cell--non-numeric'>Value</th>
          </tr>
        </thead>
        <tbody>
          #{
            _.map(object, (value, field) =>
              return if "#{field}".match(/_id|_rev|collection/)
              "
                <tr>
                  <td class='mdl-data-table__cell--non-numeric'>
                    #{
                      @mappings[field] or field
                    }
                  </td>
                  <td class='mdl-data-table__cell--non-numeric'>#{value}</td>
                </tr>
              "
            ).join("")
          
          }
        </tbody>
      </table>
    </div>
    "

  events:
    "click .toggleNext": "toggleNext"

  toggleNext: (event) =>
    $(event.target).next(".objectTable").toggle()

module.exports = CaseView
