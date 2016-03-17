_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
moment = require 'moment'
PouchDB = require 'pouchdb'
require 'moment-range'

DataTables = require 'datatables'
Reports = require '../models/Reports'

class EpidemicthresholdView extends Backbone.View
  el: "#content"

  render: =>
    $("#row-region").hide()
    options = Coconut.router.reportViewOptions
	
    # Thresholds per facility per week
    thresholdFacility = 10
    thresholdFacilityUnder5s = 5
    thresholdShehia = 10
    thresholdShehiaUnder5 = 5
    thresholdVillage = 5
    
    $('#analysis-spinner').show()

    @$el.html "
        <div id='dateSelector'></div>
        <h3>Epidemic Thresholds</h3>
        <div>
        Alerts:<br/>
        <ul>
          <li>Facility with #{thresholdFacility} or more cases</li>
          <li>Facility with #{thresholdFacilityUnder5s} or more cases in under 5s</li>
          <li>Shehia with #{thresholdShehia} or more cases</li>
          <li>Shehia with #{thresholdShehiaUnder5} or more cases in under 5s</li>
          <li>Village (household + neighbors) with  #{thresholdVillage} or more cases</li>
          <li>District - statistical method (todo)</li>
        </ul>
        </div>
    "
    startDate = moment(options.startDate)
    startYear = startDate.format("GGGG") # ISO week year
    startWeek =startDate.format("WW")
    endDate = moment(options.endDate).endOf("day")
    endYear = endDate.format("GGGG")
    endWeek = endDate.format("WW")
    weekRange = []
    moment.range(startDate,endDate).by 'week', (moment) ->
      weekRange.push moment.format("YYYY-WW")

    alerts = [
      "alert-weekly-facility-total-cases"
      "alert-weekly-facility-under-5-cases"
      "alert-weekly-shehia-cases"
      "alert-weekly-shehia-under-5-cases"
      "alert-weekly-village-cases"
    ]

    alertsByDistrictAndWeek = {}

    finished = _.after alerts.length, ->
      $('#analysis-spinner').hide()
      $('#content').append "
        <table class='tablesorter' id='thresholdTable'>
          <thead>
            <th>District</th>
            #{
              _(weekRange).map (week) ->
                "<th>#{week}</th>"
              .join("")
            }
          </thead>
          <tbody>
            #{
              _(GeoHierarchy.allDistricts()).map (district) ->
                "
                <tr> 
                  <td>#{district}</td>
                  #{
                  _(weekRange).map (week) ->
                    "
                    <td>
                      #{
                        _(alertsByDistrictAndWeek[district]?[week]).map (alert) ->
                          "<small><a href='#show/issue/#{alert._id}'>#{alert.Description}</a></small>"
                        .join("<br/>")
                      }
                    </td>
                    "
                  .join("")
                  }
                </tr>
                "
              .join("")
            }
          </tbody>
        </table>
      "
      $("#thresholdTable").dataTable
        aaSorting: [[0,"desc"]]
        iDisplayLength: 50
        dom: 'T<"clear">lfrtip'
        tableTools:
          sSwfPath: "js-libraries/copy_csv_xls.swf"
          aButtons: [
            "csv",
            ]

    _(alerts).each (alert) ->
      Coconut.database.allDocs
        startkey: "#{alert}-#{startYear}-#{startWeek}"
        endkey: "#{alert}-#{endYear}-#{endWeek}-\ufff0"
        include_docs: true
      .catch (error) ->
        console.log error
      .then (result) ->
        _(result.rows).each (row) ->
          alert = row.doc
          alertsByDistrictAndWeek[alert.District] = {} unless alertsByDistrictAndWeek[alert.District]
          alertsByDistrictAndWeek[alert.District][alert.Week] = [] unless alertsByDistrictAndWeek[alert.District][alert.Week]
          alertsByDistrictAndWeek[alert.District][alert.Week].push alert
        finished()

module.exports = EpidemicthresholdView
