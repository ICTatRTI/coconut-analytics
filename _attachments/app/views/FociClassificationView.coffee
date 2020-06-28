_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
Tabulator = require 'tabulator-tables'
MapView = require './MapView'

class FociClassificationView extends Backbone.View
  el: "#content"

  events:
    "click #download": "csv"
    "change .addAlias": "addAliasForShehia"

  addAliasForShehia: (event) =>
    alias = $(event.target)[0].getAttribute("data-unknown-shehia")
    shehia = $(event.target)[0].selectedOptions[0].innerHTML
    if confirm "Do you want to add #{alias} as an alias for #{shehia}?"
      await GeoHierarchy.addAlias(shehia, alias)
      document.location.reload()

  csv: => @tabulator.download "csv", "CoconutTableExport.csv"

  render: =>
    @$el.html "
      <style>
        .mapViewWrapper{
          width: 810px;
          height: 1000px;
          position: relative;
          display:inline-block;
          border: 1px solid black;
          padding: 10px;
          margin: 20px;
        }
        .mapView{
          width: 100%%;
          height: 100%;
          position: relative;
        }
      </style>



      <h2 onClick='$(\"#foci-classification-description\").toggle()'>Foci Classifications ▶</h2>
      <br/>
      <div id='foci-classification-description' style='display:none'>
        Foci classification is a strategy to identify places that may require extra planning and prioritization in order to achieve elimination goals.<br/>
        Focal areas in Zanzibar are aligned with shehias. If a shehia has had any positive individual classified as indigenous within the past twelve months then that foci is categorized as 'active'. If a shehia's most recent positive individual with an indigenous classification is between 12 and 48 months ago then it is categorized as 'residual non-active'. If it has been more than 48 months since an indigenous classification then the focal area is categorized as 'cleared'.


        <br/>
        <table
          <tr>
            <td>Active</td>
            <td>Indigenous within past 12 months</td>
          </tr>
          <tr>
            <td>Residual non-active</td>
            <td>Indigenous between 12 and 36 months</td>
          </tr>
          <tr>
            <td>Cleared</td>
            <td>No Indigenous case within 36 months</td>
          </tr>
        </table>
        <br/>
      </div>
      <div>
        <h4>
        #{
          (for classification in [
            "Cleared"
            "Residual non-active"
            "Active"
          ]
            "# #{classification}: <span id='number#{classification.replace(/\s/,"-")}'></span><br/>"
          ).join("")
        }
        </h4>
      </div>
      <button id='download'>CSV ↓</button> <small>Add more fields by clicking the box below</small>
      <div id='tabulator'></div>
      Labeling the shehias on the map is still a work in progress
      <div class='mapViewWrapper'>
        <div class='mapView' id='map'></div>
      </div>
      <br/>
    "

    await @renderTabulator()
    for classification in [
      "Cleared"
      "Residual non-active"
      "Active"
    ]
      @$("#number#{classification.replace(/\s/,"-")}").html @classificationCount[classification]

    @mapView = new MapView()
    @mapView.setElement "#map"
    @mapView.initialBoundary = "Shehias"
    @mapView.dontShowCases = true
    @mapView.render()

    # TODO
    # Color shehias according to classification (red,yellow,green)
    # Add legend for colors
    # Determine how different our shehia list in GeoHierarchy.allShehias is from the boundaries and labels we have for the maps, and see how much can be fixed by adding aliases to make them match
    # Consider adding this shading feature to the MapView so that it becomes just another option like the way "Sprayed Shehias" appears when you click Shehias in the control at the top of the map
  

  renderTabulator: =>
    columns = [
      {
        title: "Shehia"
        field: "Shehia"
        headerFilter: "input"
        formatter: "link"
        formatterParams:
          urlPrefix: "#dashboard/administrativeLevel/SHEHIA/administrativeName/"
      }
      {
        title: "District"
        field: "District"
        headerFilter: "input"
        formatter: "link"
        formatterParams:
          urlPrefix: "#dashboard/administrativeLevel/DISTRICT/administrativeName/"
      }
      {
        title: "Island"
        field: "Island"
        headerFilter: "input"
        formatter: "link"
        formatterParams:
          urlPrefix: "#dashboard/administrativeLevel/ISLANDS/administrativeName/"
      }
      {
        title: "Classification"
        field: "Classification"
        headerFilter: "input"
      }
      {
        title: "Months Since Most Recent Positive Individual"
        field: "Months Since Most Recent Positive Individual"
        headerFilter: "input"
      }
      {
        title: "Number Indigenous Positive Individuals"
        field: "Number Indigenous Positive Individuals"
        headerFilter: "input"
      }
    ]

    data = await @shehiasWithClassifications()

    @tabulator = new Tabulator "#tabulator",
      height: 400
      columns: columns
      data: data

    @classificationCount = {}
    for shehiaWithClassification in data
      @classificationCount[shehiaWithClassification.Classification] or= 0
      @classificationCount[shehiaWithClassification.Classification] += 1

  shehiasWithClassifications: =>

    # Need to include district since shehias are not unique
    classificationByDistrictAndShehia = {}
    for shehia in GeoHierarchy.findAllForLevel("shehia")
      shehiaName = shehia.name
      districtName = shehia.ancestorAtLevel("DISTRICT").name
      classificationByDistrictAndShehia[districtName] or= {}
      classificationByDistrictAndShehia[districtName][shehiaName] = {
        "Shehia": shehiaName
        "District": districtName
        "Island": shehia.ancestorAtLevel("ISLANDS").name
        "Number Indigenous Positive Individuals": 0
        "Most Recent Positive Individual" : null
        Classification: "Cleared"
      }

    dateToday = moment()
    dateForClearedPeriod = moment().subtract(36,"months")
    yearClearedPeriod = dateForClearedPeriod.year()
    weekClearedPeriod = dateForClearedPeriod.isoWeek()

    Coconut.reportingDatabase.query "shehiasWithLocalCasesByYearWeek",
      reduce: true
      group_level: 4
      startkey: [yearClearedPeriod, weekClearedPeriod]
    .catch (error) -> console.error error
    .then (result) =>
      for row in result.rows
        [year,isoWeek,district,shehia] = row.key
        shehia = shehia.trim()
        localCaseDate = moment("#{year} #{isoWeek}", "YYYY WW")
        monthsAgo = dateToday.diff(localCaseDate, "months")

        currentClassificationRange = if monthsAgo > 12
          "Residual non-active"
        else
          "Active"


        unless classificationByDistrictAndShehia[district]?
          console.log "DISTRICT not found: #{district}"

        unless classificationByDistrictAndShehia[district]?[shehia]?
          findByAlias = GeoHierarchy.find(shehia, "SHEHIA")
          if findByAlias.length is 1
            shehia = findByAlias[0].name
          else if findByAlias.length > 1
            shehiaMatch = null
            for shehiaUnit in findByAlias
              if shehiaUnit.ancestorAtLevel("DISTRICT") is district
                shehiaMatch = shehiaUnit.name
            if shehiaMatch
              shehia = shehiaMatch
            else
              @nonUniqueShehiasNotFoundInDHIS2 or= []
              @nonUniqueShehiasNotFoundInDHIS2.push shehia
              continue
          else
            @shehiasNotFoundInDHIS2 or= []
            @shehiasNotFoundInDHIS2.push shehia
            continue

        unless classificationByDistrictAndShehia[district]?[shehia]?
          @shehiasNotFoundInDHIS2 or= []
          @shehiasNotFoundInDHIS2.push "#{district}: #{shehia}"
          console.log "#{district}: #{shehia} missing, so skipping"
          continue


        classificationByDistrictAndShehia[district][shehia]["Months Since Most Recent Positive Individual"] = monthsAgo
        if classificationByDistrictAndShehia[district][shehia]["Classification"] is currentClassificationRange
          classificationByDistrictAndShehia[district][shehia]["Number Indigenous Positive Individuals"] += row.value
        else # Update the classification and reset the count
          classificationByDistrictAndShehia[district][shehia]["Classification"] = currentClassificationRange
          classificationByDistrictAndShehia[district][shehia]["Number Indigenous Positive Individuals"] = row.value

      if @shehiasNotFoundInDHIS2?
        shehias = _(@shehiasNotFoundInDHIS2).uniq().sort()
        @$el.append "
          Shehias (#{shehias.length}) referred to in cases but not known (not in DHIS2 and or requires aliases to be hooked up here). You can add an alias for the unknown shehia to an actual alias, which will then be reused throughout Coconut.<br/>
          #{
            (for unknownShehia in shehias
              "
                #{unknownShehia} - 
                <select class='addAlias' data-unknown-shehia='#{unknownShehia}'>
                  <option></option>
                  #{
                    (for shehia in GeoHierarchy.allShehias()
                      "<option>#{shehia}</option>"
                    ).join("")

                  }
                </select>
              "
            ).join("<br/>")

          }
        "

      if @nonUniqueShehiasNotFoundInDHIS2?
        shehias = _(@nonUniqueShehiasNotFoundInDHIS2).uniq().sort()
        @$el.append "
          <br/></br>
          Shehias that are non-unique, and hence not classified:<br/>
          #{shehias.join("<br/>")}
        "

      console.log classificationByDistrictAndShehia

      result = _(for district, shehiaData  of classificationByDistrictAndShehia
        _(shehiaData).values()
      ).flatten()

      Promise.resolve result



module.exports = FociClassificationView
