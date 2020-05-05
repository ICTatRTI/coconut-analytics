global.Tabulator = require 'tabulator-tables'
Followup = require '../models/Followup'

class FollowupsView extends Backbone.View
  events:
    "change select": "updateYearTerm"
    "click #createFollowups": "createFollowups"
    "click #saveFollowups": "saveFollowups"
    "click #downloadFollowups": "downloadFollowups"
    "click #downloadPotentialFollowups": "downloadPotentialFollowups"

  downloadFollowups: =>
    @tabulatorAllFollowups.download("csv", "allFollowups_#{moment().format('YYYY-MM-DD')}.csv")

  downloadPotentialFollowups: =>
    @tabulatorPotentialFollowups.download("csv", "potentialFollowups_#{moment().format('YYYY-MM-DD')}.csv")

  createFollowups: =>
    numberOfFollowups = @tabulatorPotentialFollowups.getSelectedData().length
    if numberOfFollowups > 0
      @$("#createFollowups").hide()
      @$("#followupForm").show()
    else
      alert "Select learners from the table in order to create followups"

  saveFollowups: =>
    learnersAndReasons = for selectedRow in @tabulatorPotentialFollowups.getSelectedData()
      id: selectedRow.Learner
      reason: selectedRow.Reason

    @$("#potentialFollowups").html "<h2>Retrieving #{learnersAndReasons.length} learner documents"
    followupDocs = for person,index in await Person.get(_(learnersAndReasons).pluck("id"), skipFetchAllRelevantDocs: true)
      @$("#potentialFollowups").append "."
      @$("#potentialFollowups").append "#{index}<br/>" if index % 100 is 0
      learnersAndReasons[index]["person"] = person
      await Followup.createFollowupDocNoSaveFindResponsibleUser
        person: person
        comments: "#{@$('#followupComment').val()} Reason: #{learnersAndReasons[index].reason}"
      .catch (error) =>
        @$("#potentialFollowups").append "<br/>Failed to get data for person: #{person.id()}<br/>"
        Promise.resolve()

    followupDocs = _(followupDocs).compact()

    console.log followupDocs
    await Coconut.peopleDB.bulkDocs followupDocs
    alert("#{followupDocs.length} followups created, updating followup table.")
    @render()

  updateYearTerm: =>
    @year = parseInt @$("#year").val()
    @term = parseInt @$("#term").val()
    @potentialFollowups()

  render: =>
    [currentYear, currentTerm] = Calendar.getYearAndTerm().map (value) => parseInt(value)
    @year or= currentYear
    @term or= currentTerm

    @$el.html "
      <h1>Followups</h1>
      <h2>All Followups</h2>
      <button id='downloadFollowups'>csv</button>
      <div id='followupTable'/>
      <h2>Create New Followups</h2>
      Learners with an active followup (e.g. in the above table) are removed from table below. To request a followup, select the learners to followup using the checkbox and click create followups. The followup will be assigned to the last user that updated that learner's information.
      <button id='createFollowups'>Create Followups</button>
      <div id='followupForm' style='display:none'>
        <h3>Creating <span style='text-decoration:bold' id='numberOfFollowups'></span> Followups</h3>
        <label>Additional comments for followup (automatically includes information in reason column).</label><br/>
        <textarea id='followupComment'></textarea>
        <button id='saveFollowups'>Save Followup(s)</button>
      </div>
      <h3>Learners that might require a followup based on attendance</h3>
      <div>
        <select id='year'>
          #{
            (for year in [2018..currentYear]
              "<option #{if year is @year then "selected" else ""}>#{year}</option>"
            ).join("")
          }
        </select>
        <select id='term'>
          #{
            (for term in [1..3]
              "<option #{if term is @term then "selected" else ""}>#{term}</option>"
            ).join("")
          }
        </select>
      </div>
      <button id='downloadPotentialFollowups'>csv</button>
      <div id='potentialFollowups'/>
    "

    @allFollowups()
    @potentialFollowups()

  allFollowups: =>


    Coconut.peopleDB.allDocs
      startkey: "followup_person"
      endkey: "followup_person\uf000"
      include_docs:true
    .then (result) =>

      columns = [
        {
          title: "Complete"
          field: "followedUpComplete"
          headerFilter:true
          headerFilterParams:{initial:"false"}
          formatter: "tickCross"
        }
      ]

      columns = columns.concat( for column in [
        "Complete"
        "Learners"
        "Assignees"
        "Comments"
      ]
        title: column
        field: column.toLowerCase()
        headerFilter:true
      )

      @learnersWithActiveFollowup = {}

      @tabulatorAllFollowups = new Tabulator "#followupTable",
        height: 400 # set this to force the virtual dom to load
        columns: columns
        data: for row in result.rows
          if row.doc.relevantPeople
            for person in row.doc.relevantPeople
              @learnersWithActiveFollowup[person] = true unless row.doc.followedUpComplete is true

          learners: row.doc.relevantPeople?.join(", ")
          assignees: row.doc.usersToFollowup?.join?(", ")
          comments: row.doc.comments
          followedUpComplete: row.doc.followedUpComplete

  potentialFollowups: =>

    unless @schoolNamesById
      await Coconut.schoolsDB.query "schoolsByName"
      .then (result) =>
        @schoolNamesById = {}
        for row in result.rows
          @schoolNamesById[row.id[-4..]] = row.key

    Coconut.peopleDB.query "peopleNeedingFollowup",
      startkey: ["#{@year}","#{@term}"]
      endkey: ["#{@year}","#{@term}",{}]
      include_docs:false
    .then (result) =>

      columns = for column in [
        "Date"
        "Learner"
        "Name"
        "Gender"
        "School"
        "Class"
        "Stream"
        "Reason"
      ]
        title: column
        field: column
        headerFilter:true

      columns.push {
        formatter:"rowSelection"
        titleFormatter:"rowSelection"
        align:"center"
        headerSort:false
        cellClick: (e, cell) =>
          cell.getRow().toggleSelect()
        titleFormatter: (cell) ->
          checkbox = document.createElement("input")
          checkbox.type = 'checkbox'

          checkbox.addEventListener "click", (e) =>
            e.stopPropagation()

          checkbox.addEventListener "change", (e) =>
            if(this.table.modules.selectRow.selectedRows.length)
              this.table.deselectRow()
            else
              this.table.selectRow("active")

          this.table.modules.selectRow.registerHeaderSelectCheckbox(checkbox);
            
          return checkbox;
      }

      @tabulatorPotentialFollowups = new Tabulator "#potentialFollowups",
        height: 400 # set this to force the virtual dom to load
        columns: columns
        data: _(for row in result.rows
          continue if @learnersWithActiveFollowup[row.id] # remove learners already involved in an active followup
          {
            Learner: row.id
            Date: row.key[2]
            School: @schoolNamesById[row.key[3]]
            Class: row.key[4]
            Stream: row.key[5]
            Name: row.key[6]
            Gender: row.key[7]
            Reason: row.value
          }
        ).compact()
        rowSelectionChanged: (row) -> # Use single arrow to keep Tabulator object as this
          $("#numberOfFollowups").html @.getSelectedData().length

module.exports = FollowupsView
