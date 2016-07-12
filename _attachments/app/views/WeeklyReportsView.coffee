_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

DataTables = require( 'datatables.net' )()
Reports = require '../models/Reports'
HTMLHelpers = require '../HTMLHelpers'
Case = require '../models/Case'

class WeeklyReportsView extends Backbone.View
  el: "#content"
    
  events:
    "change select.aggregation": "updateAggregation"
    "click button.caseBtn": "showCaseDialog"
    "click button#closeDialog": "closeDialog"

  updateAggregation: (e) =>
    Coconut.router.reportViewOptions['aggregationPeriod'] = $("#aggregationPeriod").val()
    Coconut.router.reportViewOptions['aggregationArea'] = $("#aggregationArea").val()
    @render()
    Coconut.dateSelectorView.setElement "#dateSelector"
    Coconut.dateSelectorView.render()

  showCaseDialog: (e) ->
    caseID = $(e.target).parent().attr('id') || $(e.target).attr('id')
    Case.showCaseDialog
      caseID: caseID
      success: ->
    return false

  closeDialog: () ->
    caseDialog.close() if caseDialog.open
        
  render: =>
    options = $.extend({},Coconut.router.reportViewOptions)
    @startDate = options.startDate
    @endDate = options.endDate
    @aggregationPeriod = options.aggregationPeriod or "Month"
    @aggregationArea = options.aggregationArea or "Zone"
    $('#analysis-spinner').show()
    @$el.html "
      <dialog id='caseDialog'></dialog>
      <div id='dateSelector'></div>
      <h4>Weekly Facility Reports aggregated by
        <select style='height:50px;font-size:90%' id='aggregationPeriod' class='aggregation'>
          #{
            _("Year,Month,Week".split(",")).map (aggregationPeriod) =>
              "
                <option #{if aggregationPeriod is @aggregationPeriod then "selected='true'" else ''}>
                  #{aggregationPeriod}
                </option>"
            .join ""
          }
        </select>
        and
        <select style='height:50px;font-size:90%' id='aggregationArea' class='aggregation'>
          #{
            _("Zone,District,Facility".split(",")).map (aggregationArea) =>
              "
                <option #{if aggregationArea is @aggregationArea then "selected='true'" else ''}>
                  #{aggregationArea}
                </option>"
            .join ""
          }
        </select>
        </h4>
      <br/>
    "

    Reports.aggregateWeeklyReportsAndFacilityCases
      startDate: @startDate
      endDate: @endDate
      aggregationArea: @aggregationArea
      aggregationPeriod: @aggregationPeriod
      error: (error) ->
        console.error error
      success: (results) =>
        @$el.append "
            <table class='tablesorter mdl-data-table mdl-js-data-table mdl-shadow--2dp' id='weeklyReports'>
              <thead>
                <th class='mdl-data-table__cell--non-numeric'>#{@aggregationPeriod}</th>
                <th class='mdl-data-table__cell--non-numeric'>#{@aggregationArea}</th>
                #{
                  _.map results.fields, (field) ->
                    "<th>#{field}</th>"
                  .join("")
                }
                <th>Weekly Reports Positive Cases</th>
                <th><5 Test Rate</th>
                <th><5 POS Rate</th>
                <th>=>5 Test Rate</th>
                <th>>=5 POS Rate</th>
              </thead>
              <tbody>
                #{
                  _(results.data).map (aggregationAreas, aggregationPeriod) =>
                    _(aggregationAreas).map (data,aggregationArea) =>

                      # TODO fix this - we shouldn't skip unknowns
                      if aggregationArea is "Unknown"
                        console.error "Unknown aggregation area for:"
                        console.error data
                        return if aggregationArea is "Unknown"
                      "
                        <tr>
                          <td>#{aggregationPeriod}</td>
                          <td>#{aggregationArea}</td>
                          #{
                          _.map results.fields, (field) =>
                            if field is "Facility Followed-Up Positive Cases"
                              "<td>#{HTMLHelpers.createDisaggregatableCaseGroup data[field]}</td>"
                            else
                              "<td>#{if data[field]? then data[field] else "-"}</td>"
                          .join("")
                          }
                          <td>
                            #{
                              total = data["Mal POS < 5"]+data["Mal POS >= 5"]
                              if Number.isNaN(total) then '-' else total
                            }
                          </td>
                          #{
                            percentElement = (number) ->
                              if Number.isNaN(number)
                                "<td>-</td>"
                              else
                                "<td>#{Math.round(number * 100)}%</td>"
                            ""
                          }

                          #{percentElement ((data["Mal POS < 5"]+data["Mal NEG < 5"])/data["All OPD < 5"])}
                          #{percentElement (data["Mal POS < 5"]/(data["Mal NEG < 5"]+data["Mal POS < 5"]))}
                          #{percentElement ((data["Mal POS >= 5"]+data["Mal NEG >= 5"])/data["All OPD >= 5"])}
                          #{percentElement (data["Mal POS >= 5"]/(data["Mal NEG >= 5"]+data["Mal POS >= 5"]))}

                        </tr>
                      "
                    .join("")
                  .join("")
                }
              </tbody>
            </table>
        "
        $("#weeklyReports").dataTable
          aaSorting: [[0,"desc"],[1,"asc"],[2,"desc"]]
          iDisplayLength: 50
          dom: 'T<"clear">lfrtip'
          tableTools:
            sSwfPath: "js-libraries/copy_csv_xls.swf"
            aButtons: [
              "copy",
              "csv",
              "print"
            ]
            
        $("#analysis-spinner").hide()
        
module.exports = WeeklyReportsView
