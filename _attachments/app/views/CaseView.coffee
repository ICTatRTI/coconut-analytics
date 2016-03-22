_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
Question = require '../models/Question'

DataTables = require 'datatables'

class CaseView extends Backbone.View
  el: '#content'

  render: (scrollTargetID) =>

    Coconut.case = @case
    @$el.html "
      <style>
        table#caseTable {width: 95%; margin-bottom: 30px}
        table#caseTable th {width: 47%; font-weight: bold; font-size: 1.1em}
      </style>

      <h3>Case ID: #{@case.MalariaCaseID()}</h3>
      <h5>Last Modified: #{@case.LastModifiedAt()}</h5>
      <h5>Questions: #{@case.Questions()}</h5>
    "

    tables = [
      "USSD Notification"
      "Case Notification"
      "Facility"
      "Household"
      "Household Members"
    ]

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
        if @case[tableType]?
          if tableType is "Household Members"
            _.map(@case[tableType], (householdMember) =>
              @createObjectTable(tableType,householdMember)
            ).join("")
          else
            @createObjectTable(tableType,@case[tableType])
      ).join("")
      _.each $('table tr'), (row, index) ->
        $(row).addClass("odd") if index%2 is 1
      $('html, body').animate({ scrollTop: $("##{scrollTargetID}").offset().top }, 'slow') if scrollTargetID?

    _(tables).each (question) =>
      question = new Question(id: question)
      question.fetch
        success: =>
          _.extend(@mappings, question.safeLabelsToLabelsMappings())
          finished()
          


  createObjectTable: (name,object) =>
    "
      <h4 id=#{object._id}>#{name} 
        <!-- <small><a href='#edit/result/#{object._id}'>Edit</a></small> --> 
      </h4>
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
    "

module.exports = CaseView