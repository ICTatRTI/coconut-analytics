_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
moment = require 'moment'
PouchDB = require 'pouchdb'
require 'moment-range'
capitalize = require "underscore.string/capitalize"

DataTables = require 'datatables'
Reports = require '../models/Reports'

class EpidemicThresholdView extends Backbone.View
  el: "#content"

  render: =>
    @startDate = Coconut.router.reportViewOptions.startDate
    @endDate = Coconut.router.reportViewOptions.endDate
    $("#row-region").hide()

    @$el.html "
      <style>
        .threshold {
          border: solid 1px
        }
        .alarmAlert {
          color:black;
          background-color:#EEEEEE;
          font-weight:bold;
        }
        th{
          text-align:center;
        }
      </style>
      <div id='dateSelector'></div>

      <table class='tablesorter tableData '>
        <thead>
          <tr>
            <th></th>
            <th>Facility</th>
            <th>Shehia</th>
            <th>Village</th>
            <th>District</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td class='alarmAlert'>Alert</td>
            <td class='threshold' colspan='2'>5 or more under 5 cases or 10 or more total cases within 7 days</td>
            <td class='threshold'>5 or more total cases within 7 days</td>
            <td class='threshold'rowspan='2'>Specific for each district and week, based on 5 years of previous data</td>
          </tr>
          <tr>
            <td class='alarmAlert'>Alarm <span style='font-weight:normal'><br/>(in <span style='color:red'>red</span>)</span></td>
            <td class='threshold' colspan='2'>10 or more under 5 cases or 20 or more total cases within 14 days</td>
            <td class='threshold'>10 or more total cases within 14 days</td>
          </tr>
        </tbody>
      </table>

      (Note that cases counted for district thresholds don't include household and neighbor cases)
      <br/>
      <br/>
    "
    startDate = moment(Coconut.router.reportViewOptions.startDate)
    endDate = moment(Coconut.router.reportViewOptions.endDate).endOf("day")
    weekRange = []
    moment.range(startDate,endDate).by 'week', (moment) ->
      weekRange.push moment.format("GGGG-WW")

    # Need to look for any that start or end within our target period - longest alert/alarm range is 14 days
    startkeyDate = startDate.subtract(14,'days').format("YYYY-MM-DD")
    endkeyDate = endDate.add(14,'days').format("YYYY-MM-DD")

    Coconut.database.allDocs
      startkey: "threshold-#{startkeyDate}"
      endkey: "threshold-#{endkeyDate}\ufff0"
      include_docs: true
    .catch (error) -> console.error error
    .then (result) =>
      console.debug result
      thresholdsByDistrictAndWeek = {}
      _(result.rows).each (row) =>
        # If the threshold is starts or ends during the relevant week, then include it, otherwise ignore it
        if (row.doc.StartDate >= @startDate and row.doc.StartDate <= @endDate) or (row.doc.EndDate >= @startDate and row.doc.EndDate <= @endDate)
          district = row.doc.District
          week = moment(row.doc.EndDate).format "GGGG-WW"
          thresholdsByDistrictAndWeek[district] = {} unless thresholdsByDistrictAndWeek[district]
          thresholdsByDistrictAndWeek[district][week] = [] unless thresholdsByDistrictAndWeek[district][week]
          thresholdsByDistrictAndWeek[district][week].push row.doc
          
      console.debug thresholdsByDistrictAndWeek

      @$el.append "

        <table class='tablesorter mdl-data-table mdl-js-data-table mdl-shadow--2dp' id='thresholdTable'>
          <thead>
            <th class='mdl-data-table__cell--non-numeric'>District</th>
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
                  <td class='mdl-data-table__cell--non-numeric'>#{district}</td>
                  #{
                  _(weekRange).map (week) ->
                    "
                    <td>
                      #{
                        _(thresholdsByDistrictAndWeek[district]?[week]).map (threshold) ->
                          "<small><a style='color:#{if threshold.ThresholdType is 'Alarm' then 'red' else 'black'}' href='#show/issue/#{threshold._id}'>#{capitalize(threshold.Description)}</a></small>"
                        .join("<br/><br/>")
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

      $('#analysis-spinner').hide()

module.exports = EpidemicThresholdView
