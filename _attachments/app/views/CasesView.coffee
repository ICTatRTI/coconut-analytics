DateSelectorView = require './DateSelectorView'
TabulatorView = require './TabulatorView'

class CasesView extends Backbone.View

  el: "#content"

  events:
    "click .shortcut": "shortcut"

  shortcut: (event) =>
    target = $(event.target).attr("data-target")
    switch target 
      when "All" then @tabulatorView.tabulator.setHeaderFilterValue("Island","")
      else
        @tabulatorView.tabulator.setHeaderFilterValue("Island",target)

  render: =>
    @options.startDate or= Coconut.router.defaultStartDate()
    @options.endDate or= Coconut.router.defaultEndDate()

    @$el.html "
      <div id='dateSelector' style='display:inline-block'></div>
      <div id='dateDescription' style='display:inline-block;vertical-align:top;margin-top:10px'></div>
      <div style='display:inline;vertical-align:top'>
        Island: #{
          (for place in ["All","Pemba","Unguja"]
            "<button class='shortcut' data-target='#{place}'>#{place}</button>"
          ).join("")
        }
      </div>
      <div id='tabulatorView'>
      </div>
    "

    @dateSelectorView = new DateSelectorView()
    @dateSelectorView.setElement "#dateSelector"
    @dateSelectorView.startDate = @options.startDate
    @dateSelectorView.endDate = @options.endDate
    @dateSelectorView.onChange = (startDate, endDate) =>
      @options.startDate = startDate.format("YYYY-MM-DD")
      @options.endDate = endDate.format("YYYY-MM-DD")
      @renderData()
    @dateSelectorView.render()

    @renderData()

  renderData: =>
    Coconut.router.navigate "cases/startDate/#{@options.startDate}/endDate/#{@options.endDate}"
    @renderTabulator()

  renderTabulator: =>
    @tabulatorView = new TabulatorView()
    @tabulatorView.tabulatorFields = [
      "Island"
      "District"
      "Malaria Case ID"
      "Index Case Diagnosis Date"
      "Classifications By Household Member Type"
    ]
    @tabulatorView.data = await Coconut.reportingDatabase.query "caseIDsByDate",
      startkey: @dateSelectorView.startDate
      endkey: @dateSelectorView.endDate
      include_docs: true
    .then (result) =>
      console.log "Adding GPS Shehias"
      for row in result.rows
        longitude = row.doc["Household Location - Longitude"]
        latitude = row.doc["Household Location - Latitude"]
        if longitude? and latitude?
          row.doc["Shehia From GPS"] = GeoHierarchy.findByGPS(longitude, latitude, "SHEHIA")?.name
          row.doc["Village From GPS"] = GeoHierarchy.villagePropertyFromGPS(longitude, latitude)
        row.doc
      console.log "DONE"
      Promise.resolve result.rows

    @tabulatorView.setElement("#tabulatorView")
    @tabulatorView.render()

module.exports = CasesView
