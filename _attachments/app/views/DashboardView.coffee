$ = require 'jquery'

Backbone = require 'backbone'
Backbone.$  = $
moment = require 'moment'
slugify = require "underscore.string/slugify"
humanize = require "underscore.string/humanize"

Calendar = require '../Calendar.coffee'

class DashboardView extends Backbone.View
  render: =>

    @tableData =
      headers: ["Total","Kakuma","Dadaab"]
      rows: [
        ["Learners","mdi-human-male-female"]
        ["Girls", "mdi-human-female"]
        ["Boys", "mdi-human-female"]
        ["Schools","mdi-home"]
        ["Enrollments for current term","mdi-clipboard-check"]
        ["Learners in an Enrollment for current term","mdi-clipboard-check"]
        ["Schools with more than 5 Enrollments for current term","mdi-home"]
        #["Spotchecks for current term","mdi-clipboard-check"]
        #["Spotchecks last 7 days","mdi-clipboard-check"]
        #["Learners on followup list","mdi-human-greeting"]
      ]


    @$el.html "
      <style>
        .mdl-button--fab.mdl-button--mini-fab {
           height: 35px;
           min-width: 35px;
           width: 35px;
         }
         .stats-card-wide {
           min-height: 176px;
           width: 100%;
           background: linear-gradient(to bottom, #fff 0%, #a7d0f1 100%);
           padding: 20px;
           margin-bottom: 10px;
         }
         .stats-card-wide.totals {
           background: linear-gradient(to bottom, #fff 0%, #dcdcdc 100%);
           min-height: 150px;
           padding: 10px;
         }
         .stats-card-wide.region {
           padding: 10px;
         }
         .demo-card-wide > .mdl-card__title {
            color: #fff;
            height: 176px;
          }
          .mdl-card__supporting-text {
            width: 100%;
            background-color: #fff;
            padding: 0px;
           }

           table td {padding: 0 10px;}
           .orange {color: orange}
      </style>
      <div class='scroll-div'>

        <div class='content-grid mdl-grid'>

          <div class='mdl-cell mdl-cell--7-col' style='margin-bottom: 10px;'>
            <div class='stats-card-wide mdl-card mdl-shadow--2dp region'>
              <div class='mdl-card__title'>
                <h4 class='mdl-card__title-text'>Dashboard</h4>
              </div>
              <div class='mdl-card__supporting-text'>

                <table class='mdl-data-table mdl-js-data-table mdl-shadow--2dp'>
                  <thead>
                    <tr>
                      <th/>
                      #{
                        _(@tableData.headers).map (header) =>
                          "<th>#{header}</th>"
                        .join("")
                      }
                    </tr>
                  </thead>
                  <tbody>
                    #{
                      _(@tableData.rows).map (row) =>
                        "
                          <tr class='row-#{slugify(row[0])}'>
                            <td><i class='mdi #{row[1]} mdi-18px'></i> #{row[0]}:</td>
                            #{
                              _(@tableData.headers).map (header) =>
                                "<td class='td-#{slugify(header)}'>Loading...</td>"
                              .join("")
                            }
                          </tr>
                        "
                      .join("")
                    }

                  </tbody>
                </table>
                  

              </div>
            </div>
          </div>

          <div class='mdl-cell mdl-cell--4-col'>
            <div><img src='images/sample_pie1.png'></div>
            <div><img src='images/sample_pie2.png'></div>
            <div><img src='images/sample_bar1.png'></div>
          </div>
        </div>
      </div>
    "

    Coconut.schoolsDb.query "schoolsByRegion",
      reduce: true
      include_docs: false
      group: true
      group_level: 1
    .then (result) =>
      total = 0
      _(result.rows).each (row) =>
        $(".row-schools .td-#{slugify(row.key[0])}").html(row.value)
        total += parseInt(row.value)
      $(".row-schools .td-total").html(total)
      addSchoolPercentages()

    Coconut.peopleDb.query "peopleByRegionAndGender",
      reduce: true
      include_docs: false
      group: true
      group_level: 2
    .then (result) =>
      total = 0
      kakumaTotal = 0
      dadaabTotal = 0
      boysTotal = 0
      girlsTotal = 0
      _(result.rows).map (row) =>
        # By region
        switch row.key[0]
          when 'KAKUMA'
            total += row.value
            kakumaTotal += row.value
          when 'DADAAB'
            total += row.value
            dadaabTotal += row.value

        # By region and gender
        switch row.key[1]
          when 'MALE'
            boysTotal += row.value
            @$(".row-boys .td-#{slugify(row.key[0])}").html(row.value)
          when 'FEMALE'
            girlsTotal += row.value
            @$(".row-girls .td-#{slugify(row.key[0])}").html(row.value)

      @$(".row-girls .td-total").html(girlsTotal)
      @$(".row-boys .td-total").html(boysTotal)

      @$(".row-learners .td-total").html(total)
      @$(".row-learners .td-kakuma").html(kakumaTotal)
      @$(".row-learners .td-dadaab").html(dadaabTotal)
      addLearnerPercentage()

    .catch (error) ->
      console.error error
      $('div.mdl-spinner').hide()

    Coconut.enrollmentsDb.query "enrollmentsByYearTermRegion",
      startkey: Calendar.getYearAndTerm()
      endkey: Calendar.getYearAndTerm().concat("\uf000")
      reduce: true
      group: true
    .then (result) =>
      total = 0
      _(result.rows).each (row) =>
        total += row.value
        @$(".row-enrollments-for-current-term .td-#{row.key[2].toLowerCase()}").html(row.value)
      @$(".row-enrollments-for-current-term .td-total").html(total)
      
    Coconut.enrollmentsDb.query "enrollmentsByYearTermRegionWithStudentCount",
      startkey: Calendar.getYearAndTerm()
      endkey: Calendar.getYearAndTerm().concat("\uf000")
      reduce: true
      group: true
    .then (result) =>
      total = 0
      _(result.rows).each (row) =>
        total += row.value
        @$(".row-learners-in-an-enrollment-for-current-term .td-#{row.key[2].toLowerCase()}").html(row.value)
      @$(".row-learners-in-an-enrollment-for-current-term .td-total").html(total)
      addLearnerPercentage()

    # Call this after the 4 functions that create the num/den are done
    addLearnerPercentage = _.after 2, =>
      @tableData.headers.map (header) =>
        header = header.toLowerCase()
        targetCell = ".row-learners-in-an-enrollment-for-current-term .td-#{header}"
        numerator = @$(targetCell).html()
        denominator = @$(".row-learners .td-#{header}").html()
        percent = Math.round(numerator/denominator*100)
        @$(targetCell).append " (#{percent}%)"
      
    Coconut.enrollmentsDb.query "enrollmentsByYearTermRegion",
      startkey: Calendar.getYearAndTerm()
      endkey: Calendar.getYearAndTerm().concat("\uf000")
      reduce: false
    .then (result) =>
      value = _(result.rows).chain().countBy (row) =>
        row.id[18..21] #school ID
      .pick (numberOfEnrollments, schoolId) =>
        numberOfEnrollments > 5
      .size().value()

      @$(".row-schools-with-more-than-5-enrollments-for-current-term .td-total").html "#{value}"
      addSchoolPercentages()


    @tableData.headers.map (region) =>
      return if region is "Total"
      Coconut.enrollmentsDb.query "enrollmentsByYearTermRegion",
        startkey: Calendar.getYearAndTerm().concat(region)
        endkey: Calendar.getYearAndTerm().concat(region).concat("\uf000")
        reduce: false
      .then (result) =>
        value = _(result.rows).chain().countBy (row) =>
          row.id[18..21] #school ID
        .pick (numberOfEnrollments, schoolId) =>
          numberOfEnrollments > 5
        .size().value()
        @$(".row-schools-with-more-than-5-enrollments-for-current-term .td-#{region.toLowerCase()}").html value
        addSchoolPercentages()

    # Call this after the 4 functions that create the num/den are done
    addSchoolPercentages = _.after 4, =>
      @tableData.headers.map (header) =>
        header = header.toLowerCase()
        targetCell = ".row-schools-with-more-than-5-enrollments-for-current-term .td-#{header}"
        numerator = @$(targetCell).html()
        denominator = @$(".row-schools .td-#{header}").html()
        percent = Math.round(numerator/denominator*100)
        @$(targetCell).append " (#{percent}%)"

module.exports = DashboardView
