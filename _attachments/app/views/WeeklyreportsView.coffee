_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

DataTables = require 'datatables'
Reports = require '../models/Reports'

class WeeklyreportsView extends Backbone.View
  el: "#content"

  events:
    "click button#dateFilter": "showForm"
  
  showForm: (e) =>
    e.preventDefault
    $("div#filters-section").slideToggle()

  render: =>
    options = Coconut.router.reportViewOptions
    @startDate = options.startDate
    @endDate = options.endDate
    @aggregationPeriod = options.aggregationPeriod or "Month"
    @aggregationArea = options.aggregationArea or "Zone"
    $('#analysis-spinner').show()
    @$el.html "
      <div id='dateSelector'></div>
      <h4>Weekly Facility Reports from MEEDS or iSMS aggregated by
        <select style='height:50px;font-size:90%' id='aggregationPeriod'>
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
        <select style='height:50px;font-size:90%' id='aggregationArea'>
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
    .catch (error) ->
      console.log error
    .then (results) =>
      $("#analysis-spinner").hide()
      @$el.append "
          <table class='tablesorter' id='weeklyReports'>
            <thead>
              <th>#{@aggregationPeriod}</th>
              <th>#{@aggregationArea}</th>
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
                            "<td>#{@createDisaggregatableCaseGroupWithLength data[field]}</td>"
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
 
module.exports = WeeklyreportsView
