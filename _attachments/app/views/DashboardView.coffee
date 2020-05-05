$ = require 'jquery'

Backbone = require 'backbone'
Backbone.$  = $
moment = require 'moment'
slugify = require "underscore.string/slugify"
humanize = require "underscore.string/humanize"

Chart = require 'chart.js'

Calendar = require '../Calendar.coffee'

class DashboardView extends Backbone.View
  events:
    "change #selectedYear": "updateYear"
    "change #selectedTerm": "updateTerm"

  updateYear: =>
    @year = @$("#selectedYear").val()
    @render()

  updateTerm: =>
    @term = @$("#selectedTerm").val()
    @render()


  render: =>
    unless @year and @term
      [@year, @term] = Calendar.getYearAndTerm() or [(new Date()).getFullYear(), 1]

    @tableData =
      headers: ["Total","Kakuma","Dadaab"]
      rows: [
        ["Learners","mdi-human-male-female"]
        ["Girls", "mdi-human-female"]
        ["Boys", "mdi-human-female"]
        ["Schools","mdi-home"]
        ["Enrollments for current term","mdi-clipboard-check"]
        ["Learners in an Enrollment for current term","mdi-clipboard-check"]
        ["Schools with Enrollments for current term","mdi-home"]
        ["Schools with > 2 up-to-date Attendances for current term","mdi-home"]
        ["Enrollments with spotchecks completed for current term","mdi-clipboard-check"]
        ["Spotchecks completed in last 30 days","mdi-checkbox-marked-circle-outline"]
        ["Learners on followup list","mdi-human-greeting"]
        ["Learners that transitioned to next class","mdi-trophy-award"]
        ["Learners with previous Standard 8 enrollment that have transitioned to Form 1","mdi-trophy-award"]
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

      .chartDiv {
        float:left
      }
      </style>
      <div class='scroll-div'>

        <h4 class='mdl-card__title-text'>Dashboard

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
        </h4>


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
                    <td><i class='mdi #{row[1]} mdi-18px'></i> #{row[0].replace(/current term/,"#{@year} t#{@term}")}:</td>
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
      <div>
        <div class='chartDiv'>
          <canvas style='height:400px' id='percentSchoolsWithEnrollment'/>
        </div>

        <div class='chartDiv'>
          <canvas style='height:400px' id='percentLearnersEnrolled'/>
        </div>
      </div>
    "

    if @year and @term
      @$("#selectedYear").val(@year)
      @$("#selectedTerm").val(@term)

    await Coconut.schoolsDb.query "schoolsByRegion",
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

    await Coconut.peopleDb.query "peopleByRegionAndGender",
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

    .catch (error) ->
      console.error error
      $('div.mdl-spinner').hide()

    await Coconut.enrollmentsDb.query "enrollmentsByYearTermRegion",
      startkey: ["#{@year}","#{@term}"]
      endkey: ["#{@year}","#{@term}", "\uf000"]
      reduce: true
      group: true
    .then (result) =>
      total = 0
      _(result.rows).each (row) =>
        total += row.value
        @$(".row-enrollments-for-current-term .td-#{row.key[2].toLowerCase()}").html(row.value)
      @$(".row-enrollments-for-current-term .td-total").html(total)
      
    await Coconut.enrollmentsDb.query "enrollmentsByYearTermRegionWithStudentCount",
      startkey: ["#{@year}","#{@term}"]
      endkey: ["#{@year}","#{@term}", "\uf000"]
      reduce: true
      group: true
    .then (result) =>
      total = 0
      _(result.rows).each (row) =>
        total += row.value
        @$(".row-learners-in-an-enrollment-for-current-term .td-#{row.key[2].toLowerCase()}").html(row.value)
      @$(".row-learners-in-an-enrollment-for-current-term .td-total").html(total)

    @tableData.headers.map (header) =>
      header = header.toLowerCase()
      targetCell = ".row-learners-in-an-enrollment-for-current-term .td-#{header}"
      numerator = @$(targetCell).html()
      denominator = @$(".row-learners .td-#{header}").html()
      percent = Math.round(numerator/denominator*100)
      @$(targetCell).append " (#{percent}%)"


      new Chart @$("#percentLearnersEnrolled"),
        type: 'pie'
        data:
          labels: ["Learners Enrolled", "Learners not Enrolled"]
          datasets: [{
            backgroundColor: ["rgb(33,150,243)", "#ff4081"],
            data:[
              numerator
              denominator-numerator
            ]
          }]
        options: {
          title: {
            display: true,
            text: "Percent Learners Enrolled"
          }
        }

      
    await Coconut.enrollmentsDb.query "enrollmentsByYearTermRegion",
      startkey: ["#{@year}","#{@term}"]
      endkey: ["#{@year}","#{@term}", "\uf000"]
      reduce: false
    .then (result) =>
      value = _(result.rows).chain().countBy (row) =>
        row.id[18..21] #school ID
      .pick (numberOfEnrollments, schoolId) =>
        numberOfEnrollments > 1
      .size().value()

      @$(".row-schools-with-enrollments-for-current-term .td-total").html "#{value}"


    @tableData.headers.map (region) =>
      return if region is "Total"
      await Coconut.enrollmentsDb.query "enrollmentsByYearTermRegion",
        startkey: ["#{@year}","#{@term}", region]
        endkey: ["#{@year}","#{@term}", region, "\uf000"]
        reduce: false
      .then (result) =>
        value = _(result.rows).chain().countBy (row) =>
          row.id[18..21] #school ID
        .pick (numberOfEnrollments, schoolId) =>
          numberOfEnrollments > 1
        .size().value()
        @$(".row-schools-with-enrollments-for-current-term .td-#{region.toLowerCase()}").html value


    Coconut.enrollmentsDb.query "latestRecordedAttendanceByYearTermRegion",
      startkey: ["#{@year}","#{@term}"]
      endkey: ["#{@year}","#{@term}", "\uf000"]
      reduce: false
    .then (result) =>
      value = _(result.rows).chain().countBy (row) =>
        row.id[18..21] #school ID
      .pick (numberOfAttendances, schoolId) =>
        numberOfAttendances > 2
      .size().value()

      @$(".row-schools-with-2-up-to-date-attendances-for-current-term .td-total").html "#{value}"


    @tableData.headers.map (region) =>
      return if region is "Total"
      Coconut.enrollmentsDb.query "latestRecordedAttendanceByYearTermRegion",
        startkey: ["#{@year}","#{@term}", region]
        endkey: ["#{@year}","#{@term}", region, "\uf000"]
        reduce: false
      .then (result) =>
        value = _(result.rows).chain().countBy (row) =>
          row.id[18..21] #school ID
        .pick (numberOfAttendances, schoolId) =>
          numberOfAttendances > 2
        .size().value()
        @$(".row-schools-with-2-up-to-date-attendances-for-current-term .td-#{region.toLowerCase()}").html value


    @tableData.headers.map (header) =>
      header = header.toLowerCase()
      targetCell = ".row-schools-with-enrollments-for-current-term .td-#{header}"
      numerator = @$(targetCell).html()
      denominator = @$(".row-schools .td-#{header}").html()
      percent = Math.round(numerator/denominator*100)
      @$(targetCell).append " (#{percent}%)"

      new Chart @$("#percentSchoolsWithEnrollment"),
        type: 'pie'
        data:
          labels: ["Schools With Enrollments", "Schools Without Enrollments"]
          datasets: [{
            backgroundColor: ["rgb(33,150,243)", "#ff4081"],
            data:[
              numerator
              (denominator-numerator)
            ]
          }]
        options: {
          title: {
            display: true,
            text: "Percent Schools With Enrollments"
          }
        }


    regionBySchoolId = await (Coconut.schoolsDb.allDocs
      include_docs: true
    .then (result) =>
      regionBySchoolId = {}
      _(result.rows).each (row) =>
        regionBySchoolId[row.id.replace(/school-/,"")] = row.doc.Region
      Promise.resolve regionBySchoolId
    )

    @$(".row-enrollments-with-spotchecks-completed-for-current-term .td-total").html "0"
    @$(".row-enrollments-with-spotchecks-completed-for-current-term .td-dadaab").html "0"
    @$(".row-enrollments-with-spotchecks-completed-for-current-term .td-kakuma").html "0"
    @$(".row-spotchecks-completed-in-last-30-days .td-total").html "0"
    @$(".row-spotchecks-completed-in-last-30-days .td-dadaab").html "0"
    @$(".row-spotchecks-completed-in-last-30-days .td-kakuma").html "0"

    Coconut.spotchecksDb.query "resultsByDate",
      startkey: Calendar.termDates[@year][@term].start
      endkey: Calendar.termDates[@year][@term].end
      reduce: false
    .then (result) =>
      total = 0
      # number of spotchecks per unique enrollment
      _(result.rows).chain().groupBy (row) =>
        enrollmentId = row.id[10..-12]
        enrollmentId
      .groupBy (spotchecks, enrollment) =>
        regionBySchoolId[enrollment[18..21]].toLowerCase()
      .each (spotchecks, region) =>
        totalEnrollmentsForRegion = parseInt @$("tr.row-enrollments-for-current-term td.td-#{region}").html()
        enrollmentsWithSpotchecksForRegion = spotchecks.length

        @$(".row-enrollments-with-spotchecks-completed-for-current-term .td-#{region}").html "
          #{enrollmentsWithSpotchecksForRegion} (#{Math.round(enrollmentsWithSpotchecksForRegion/totalEnrollmentsForRegion*100)}%)
        "
        total += enrollmentsWithSpotchecksForRegion
      
      totalEnrollments = parseInt(@$("tr.row-enrollments-for-current-term td.td-total").html())
      @$(".row-enrollments-with-spotchecks-completed-for-current-term .td-total").html "
        #{total} (#{Math.round(total/totalEnrollments*100)}%)
      "

      totalInLastMonth = 0
      _(result.rows).chain().filter (row) =>
        row.value >= moment().subtract(1,"month")
      .groupBy (spotchecks, enrollment) =>
        regionBySchoolId[enrollment[18..21]].toLowerCase()
      .each (spotchecks, region) =>

        @$(".row-spotchecks-completed-in-last-30-days .td-#{region}").html "#{spotchecks.length}"
        totalInLastMonth += enrollmentsWithSpotchecksForRegion

      @$(".row-spotchecks-completed-in-last-30-days .td-total").html totalInLastMonth

      Coconut.peopleDb.allDocs
        startkey: "followup"
        endkey: "followup\uf000"
      .then (result) =>
        followups = _(result.rows).filter (row) =>
          row.key[-19..-10] >= Calendar.termDates[@year][@term].start
          row.key[-19..-10] <= Calendar.termDates[@year][@term].end
        @$(".row-learners-on-followup-list .td-total").html followups.length
        @$(".row-learners-on-followup-list .td-kakuma").html "TODO"
        @$(".row-learners-on-followup-list .td-dadaab").html "TODO"
        

    await Coconut.peopleDb.query "transitionsByYearTerm",
      startkey: [@year,@term]
      endkey: [@year,@term,{}]
    .then (result)  =>
      @$(".row-learners-that-transitioned-to-next-class .td-total").html result.rows.length
      @$(".row-learners-with-previous-standard-8-enrollment-that-have-transitioned-to-form-1 .td-total").html(
        _(result.rows).filter (row) =>
          row.value.match(/-> f1/)
        .length
      )
      @$(".row-learners-that-transitioned-to-next-class .td-kakuma").html "TODO"
      @$(".row-learners-that-transitioned-to-next-class .td-dadaab").html "TODO"
      @$(".row-learners-with-previous-standard-8-enrollment-that-have-transitioned-to-form-1 .td-kakuma").html "TODO"
      @$(".row-learners-with-previous-standard-8-enrollment-that-have-transitioned-to-form-1 .td-dadaab").html "TODO"


    # Find all of the relevant transitions for linked people (this is one of the main points of linking)
    await Coconut.peopleDb.query "linksByPersonId"
    .then (result)  =>
      uniqueTransitionsBetweenLinkedPeopleByYearTerm = {}
      linkedPeople = _(result.rows).chain().pluck("id").uniq().map (linkId) =>
        linkId.replace(/_link.*/,"")
      .value()
      for person in await (Person.get linkedPeople,
        skipFetchAllRelevantDocs: true
      )
        continue unless person.doc
        await person.fetchAllRelevantDocs() # Need to do this manually so we can know when it's finished
        .catch (error) => 
          console.error "Couldn't fetch relevant docs for #{person.doc._id}"
        for transition, enrollmentsForTransition of person.transitions()
          enrollmentsForThisIdOnly = Object.values(person.termsEnrolledThisIdOnly())
          # If both enrollments for this transition are included for this person (not counting linked people) then it has been counted already so skip it
          # If no enrollments for this transition are included, then the transition comes from a different link which will be counted elsewhere
          if _.intersection(enrollmentsForTransition, enrollmentsForThisIdOnly).length is 1

            [match, year, term] = enrollmentsForTransition[1].match(/(\d\d\d\d)-term-(\d)/) # use second enrollment as the year/term since this is the ending place

            uniqueTransitionsBetweenLinkedPeopleByYearTerm["#{year}-t#{term}"] or= []
            uniqueTransitionsBetweenLinkedPeopleByYearTerm["#{year}-t#{term}"].push transition

       if uniqueTransitionsBetweenLinkedPeopleByYearTerm["#{@year}-t#{@term}"]
        @$(".row-learners-that-transitioned-to-next-class .td-total").html(
          parseInt(@$(".row-learners-that-transitioned-to-next-class .td-total").html()) + uniqueTransitionsBetweenLinkedPeopleByYearTerm["#{@year}-t#{@term}"].length
        )

      numberOfForm1TransitionsFromLinkedLearners = _(uniqueTransitionsBetweenLinkedPeopleByYearTerm["#{@year}-t#{@term}"]).filter (transition) =>
        transition.match(/-> Form 1/)
      .length

      if numberOfForm1TransitionsFromLinkedLearners > 0
        @$(".row-learners-with-previous-standard-8-enrollment-that-have-transitioned-to-form-1 .td-total").html( 
          parseInt(@$(".row-learners-with-previous-standard-8-enrollment-that-have-transitioned-to-form-1 .td-total").html()) + numberOfForm1TransitionsFromLinkedLearners
        )
        

        
      
    


module.exports = DashboardView
