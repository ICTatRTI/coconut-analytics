Tabulator = require 'tabulator-tables'

class NewLearnersView extends Backbone.View
  events:
    "click #region": "setRegion"

  setRegion: =>
    @region = @$("#region").val()
    @render()

  regionSelector: => "
    Select the region: 
    <select id='region'>
      <option></option>
      <option>Kakuma</option>
      <option>Dadaab</option>
    </select>
  "

  render: =>
    unless @region
      @$el.html @regionSelector()
    else
      @$el.html "
        #{@regionSelector()}
        <h3 id='titleStatus'>
          Loading unconfirmed learners from #{@region}
        </h3>
        <div id='newLearners'/>
        <hr/>
        <div id='potentialMatches'/>
      "

      Coconut.peopleDB.query "peopleByRegionAndGender",
        include_docs: false
        reduce:false
        startkey: [@region.toUpperCase()]
        endkey: [@region.toUpperCase(),{}]

      .then (result) =>
        tableData = _(result.rows).chain().map (row) =>
          return unless row.id.match(/-.+-/) # only get unconfirmed people
          row.value.id = row.id
          row.value
        .compact().value()

        @renderTable(tableData)
        @findPotentialMatches()

  findPotentialMatches: =>
    return unless @table
    @$("#potentialMatches").html "<h3>Searching for potential matches for visible elements</h3>"
    Coconut.peopleDB.query "peopleByRegionAndGender",
      include_docs: false
      reduce:false
      startkey: [@region.toUpperCase()]
      endkey: [@region.toUpperCase(),{}]
    .then (result) =>
      people = _(result.rows).pluck "value"

      for rowComponent in @table.getRows(true)[0..15]
        await Person.get(rowComponent.getData().id).then (person) =>
          console.log person.name()
          potentialDuplicates = await(person.findPotentialDuplicateFromArrayOfPeople(result.rows))
          console.log potentialDuplicates
          if potentialDuplicates.length > 0

            console.log "RGBA(240,255,0,#{1-(potentialDuplicates[0].score)}"
            rowComponent.getElement().style["background-color"] = "RGBA(240,255,0,#{1-(potentialDuplicates[0].score)}"
            #for result in potentialDuplicates
            #  console.log "#{result.score.toFixed(1)} #{result.item.value.Name}"



  renderTable: (tableData) =>
    @$("#titleStatus").html "Unconfirmed learners from #{@region} (#{tableData.length})"

    @table = new Tabulator "#newLearners",
      height:400
      data: tableData
      layout:"fitColumns"
      columns: [
        {title: "Name", field: "Name", headerFilter: true}
        {title: "ID", field: "id", headerFilter: true}
        #{title: "Region", field: "Region", headerFilter: true},
        {title: "School Name", field: "School Name", headerFilter: true}
        {title: "School Class", field: "School Class", headerFilter: true}
        #{title: "Sex", field: "Sex", headerFilter: "select", headerFilterParams:{"Male":"Male", "Female":"Female", "":""}, headerFilterFunc: "="},
      ]
      rowClick: (e, row) =>
        Coconut.router.navigate "admin/new_learner/#{row.getData().id}", trigger:true
      renderComplete: =>
        @findPotentialMatches()

module.exports = NewLearnersView
