_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
Question = require '../models/Question'
Case = require '../models/Case'
MapView = require '../views/MapView'

DataTables = require( 'datatables.net' )()

class CaseView extends Backbone.View
  el: '#content'

  render: (scrollTargetID) =>

    Coconut.case = @case
    tables = [
      "USSD Notification"
      "Case Notification"
      "Facility"
      "Household"
      "Household Members"
      "ODK 2017-2019"
    ]
    @$el.html "
      <style>
        table#caseTable {width: 95%; margin-bottom: 30px}
        table#caseTable th {width: 47%; font-weight: bold; font-size: 1.1em}
      </style>
      <div id='map' style='height:400px; width:400px;float:right'>
      </div>

      <h3>Case ID: #{@case.MalariaCaseID()}</h3>
      <h3>Diagnosis Date: #{@case.IndexCaseDiagnosisDate()}</h3>
      <h3>Classification: #{@case.classificationsByHouseholdMemberType()}</h3>
      <h5>Last Modified: #{@case.LastModifiedAt()}</h5>
      <h5>Saved By: #{@case.allUserNames().join(", ")}</h5>
    "

    @mappings = {
      createdAt: "Created At"
      lastModifiedAt: "Last Modified At"
      question: "Question"
      user: "User"
      complete: "Complete"
      savedBy: "Saved By"
    }

    for question in tables
      question = new Question(id: question)
      continue if question.id is "Summary" or question.id is "USSD Notification"
      await question.fetch()
      .catch (error) => console.error "Can't find question: #{question}"
      _.extend(@mappings, question.safeLabelsToLabelsMappings())

    # USSD Notification doesn't have a mapping
    @$el.append _.map(tables, (tableType) =>
      if @case[tableType]?
        if tableType is "Household Members"
          _.map(@case[tableType], (householdMember) =>
            console.log householdMember
            title = "Household Member"
            title += " Index" if householdMember.HouseholdMemberType is "Index Case"
            title += ": #{householdMember.CaseCategory}" if householdMember.CaseCategory
            @createObjectTable(title,householdMember)
          ).join("")
        else
          @createObjectTable(tableType,@case[tableType])
    ).join("")
    try
      # TODO there is a bug here that merges the facility data with the household data in the case object - i've moved this here to avoid the side effect showing up
      @$("h5").last().after @createObjectTable("Summary",@case.summaryCollection())
    catch error
      console.error error
    _.each $('table tr'), (row, index) ->
      $(row).addClass("odd") if index%2 is 1
    #$('html, body').animate({ scrollTop: $("##{scrollTargetID}").offset().top }, 'slow') if scrollTargetID?
    #
    @renderMap()
    @$(".controls").hide()

  renderMap: =>
    return if @case.householdLocationLatitude() is NaN or @case.householdLocationLongitude() is NaN
    mapView = new MapView()
    mapView.setElement "#map"
    classifications = @case.classificationsByDiagnosisDate()?.split(/, /) or [null]
    mapView.casesWithKeyIndicators = for classification in classifications
      {
        id: @case.caseID
        value:
          latLong: [
            @case.householdLocationLatitude()
            @case.householdLocationLongitude()
          ]
          classification: classification?.split(": ")[1]
      }
    mapView.render()


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

CaseView.showCaseDialog = (options) ->
  caseId = options.caseID

  caseView = new CaseView()
  caseView.case = new Case
    caseID: caseId
  caseView.case.fetch
    success: ->
      caseView.setElement($("#caseDialog"))
      caseView.render()
      if (Env.is_chrome)
         caseDialog.showModal() if !caseDialog.open
      else
         caseDialog.show() if !caseDialog.open
      options?.success()

module.exports = CaseView
