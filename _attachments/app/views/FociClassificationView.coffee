_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
Tabulator = require 'tabulator-tables'
MapView = require './MapView'
CasesTabulatorView = require './CasesTabulatorView'

dasherize = require 'underscore.string/dasherize'

class FociClassificationView extends Backbone.View
  el: "#content"

  events:
    "click #download": "csv"
    "change .addAlias": "addAliasForShehia"
    "click .disaggregate": "disaggregate"
    "click .analyzeCases": "showCases"

  disaggregate: (event) =>
    keys = for key in $(event.target).attr("data-keys")?.split(";")
      key.split(",")
    summaryCases = await Coconut.reportingDatabase.query "shehiasWithLocalCasesByYearWeek",
      reduce: false
      keys: keys

    cases = for summaryCase in summaryCases.rows
      summaryCase.id[-6..]
    console.log cases
    CasesTabulatorView.showDialog
      cases: cases
    return false

  showCases: (event) =>
    CasesTabulatorView.showDialog
      cases: $(event.target).attr("data-caseIds").split(',')
      fields: [
        "Malaria Case ID"
        "District"
        "Shehia"
        "Classifications By Iso Year Iso Week Foci District Foci Shehia"
      ]

  addAliasForShehia: (event) =>
    alias = $(event.target)[0].getAttribute("data-unknown-shehia")
    shehia = $(event.target)[0].selectedOptions[0].innerHTML
    if confirm "Do you want to add #{alias} as an alias for #{shehia}?"
      await GeoHierarchy.addAlias(shehia, alias)
      document.location.reload()

  csv: => @tabulator.download "csv", "CoconutTableExport.csv"

  classifications: [
    {
      name: "Active"
      longDescription: "If a shehia has had any positive individual classified as indigenous within the past twelve months then that foci is categorized as 'active'."
      shortDescription: "Indigenous within past 12 months"
      color: "red"
    }
    {
      name: "Residual non-active"
      longDescription: "If a shehia's most recent positive individual with an indigenous classification is between 12 and 48 months ago then it is categorized as 'residual non-active'."
      shortDescription: "Indigenous between 12 and 36 months"
      color: "yellow"
    }
    {
      name: "Cleared"
      longDescription: "If a shehia had no positive individuals with has been more than 48 months since an indigenous classification then the focal area is categorized as 'cleared'."
      shortDescription: "No Indigenous case within 36 months"
      color: "green"
    }
  ]


  render: =>
    @$el.html "
      <style>
        .mapViewWrapper{
          width: 500px;
          height: 800px;
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
        Focal areas in Zanzibar are aligned with shehias. <br/>
        #{
          _(@classifications).pluck("longDescription").join(" ")
        }
        <br/>
        Note that while Shehia is used as the focal area, <span style='font-weight:bold'>the shehia of the household is not always the shehia used for foci classification</span>. DMSOs may change the focal area when interviewing the positive individual on the Household Member question set.
        <br/>
          <table>
            #{
              (for classification in @classifications
                "
                <tr>
                  <td>
                    <span style='background-color:#{classification.color}'>
                      &nbsp;
                      &nbsp;
                    </span>
                    <span style='margin:10px;'>
                      #{classification.name}
                    </span>
                  </td>
                  <td>#{classification.shortDescription}</td>
                </tr>
                "
              ).join("")
            }
          </table>
          <br/>
        </div>
        <div>
          <h4>
          #{
            (for classification in @classifications
              "
              <span style='margin:20px;'>
                <span style='background-color: #{classification.color};'>&nbsp;&nbsp;&nbsp;</span> #{classification.name}:
                <span id='number#{dasherize(classification.name)}'></span>
              </span>
              "
            ).join("")
          }
          </h4>
        </div>

        <div class='mapViewWrapper'>
          <div class='mapView' id='map-Unguja'></div>
        </div>
        <div class='mapViewWrapper'>
          <div class='mapView' id='map-Pemba'></div>
        </div>


        <button id='download'>CSV ↓</button> <small>Add more fields by clicking the box below</small>
        <div id='tabulator'></div>
        <br/>
      "

    await @renderTabulator()
    for classification in @classifications
      @$("#number#{dasherize(classification.name)}").html @classificationCount[classification.name]

    @maps = for island in ["Unguja","Pemba"]

      mapView = new MapView()
      mapView.setElement "#map-#{island}"
      mapView.initialBoundary = "Shehias"
      mapView.dontShowCases = true
      mapView.shehiaClassifications = @shehiaClassifications
      await mapView.render()
      mapView.showFociClassifications()
      @$(".controlBox").hide() # Remove the map options to simplify
      @$(".controlBox.labels").show() # Except for the label option
      @$("#map-#{island} #zoom#{island}").click()

      mapView

    # Determine how different our shehia list in GeoHierarchy.allShehias is from the boundaries and labels we have for the maps, and see how much can be fixed by adding aliases to make them match
    if (shehiasInDHIS2NotGIS = _(GeoHierarchy.allShehias()).difference(@maps[0].shehiasWithBoundaries)).length > 1
      @$el.append "
        <br/></br>
        Shehias that are in DHIS2 but have no boundary in our GIS map boundaries:<br/>
        #{shehiasInDHIS2NotGIS.join("<br/>")}
      "

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
        formatter: (cell, formatterParams, onRendered) ->
          "<button class='disaggregate' data-keys='#{cell.getRow().getData().keys.join(';')}'>#{cell.getValue()}</button>"
      }
    ]

    data = await @shehiasWithClassifications()

    @tabulator = new Tabulator "#tabulator",
      height: 400
      columns: columns
      data: data

    @shehiaClassifications = {}
    @classificationCount = {}
    for shehiaWithClassification in data
      @shehiaClassifications[shehiaWithClassification.Classification] or= []
      @shehiaClassifications[shehiaWithClassification.Classification].push shehiaWithClassification.Shehia

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
        keys: []
      }

    dateToday = moment()
    dateForClearedPeriod = moment().subtract(36,"months")
    yearClearedPeriod = dateForClearedPeriod.year().toString()
    weekClearedPeriod = dateForClearedPeriod.isoWeek().toString()

    console.log classificationByDistrictAndShehia

    Coconut.reportingDatabase.query "shehiasWithLocalCasesByYearWeek",
      reduce: true
      group_level: 4
      startkey: [yearClearedPeriod, weekClearedPeriod]
      endkey: [dateToday.year().toString(),dateToday.isoWeek().toString()]
    .catch (error) -> console.error error
    .then (result) =>
      for row in result.rows
        key = row.key
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
          console.log key
          continue

        unless classificationByDistrictAndShehia[district]?[shehia]?
          findByAlias = GeoHierarchy.find(shehia, "SHEHIA")
          if findByAlias.length is 1
            shehia = findByAlias[0].name
          else if findByAlias.length > 1
            shehiaByAncestor = GeoHierarchy.findShehiaWithAncestor(shehia,district,"DISTRICT")
            if shehiaByAncestor
              shehia = shehiaByAncestor.name
            else
              # Use facility and district to determine which island, then select shehia based on island
              # Do the district and shehia agree on the levels above district (REGION or ISLAND)? If, so use the shehia that agrees with that level. The non-unique shehias are from different islands so this should work fine
              islandFromDistrict = GeoHierarchy.findFirst(district, "DISTRICT").ancestorAtLevel("ISLANDS")
              islandsFromShehia = for shehiaUnit in GeoHierarchy.find(shehia,"SHEHIA")
                shehiaUnit.ancestorAtLevel("ISLANDS")

              if _(islandsFromShehia).contains(islandFromDistrict)
                shehiaByAncestor = GeoHierarchy.findShehiaWithAncestor(shehia,islandFromDistrict.name,"ISLANDS")
                if shehiaByAncestor
                  district = shehiaByAncestor.ancestorAtLevel("DISTRICT").name
                  shehia = shehiaByAncestor.name
              else
                @nonUniqueShehiasWithDistrictNotFoundInDHIS2 or= []
                @nonUniqueShehiasWithDistrictNotFoundInDHIS2.push "#{shehia}:#{district}:#{key}"
                continue
          else
            @shehiasNotFoundInDHIS2 or= []
            @shehiasNotFoundInDHIS2.push "#{district}: #{shehia}"
            continue

        unless classificationByDistrictAndShehia[district]?[shehia]?
          # Try using the district for the shehia
          districtForShehia = GeoHierarchy.findFirst(shehia,"SHEHIA").ancestorAtLevel("DISTRICT").name
          if classificationByDistrictAndShehia[districtForShehia]?[shehia]?
            district = districtForShehia
          else
            @shehiasNotFoundInDHIS2 or= []
            @shehiasNotFoundInDHIS2.push "#{district}: #{shehia}"
            console.log "#{district}: #{shehia} missing, so skipping"
            console.log
            continue

        classificationByDistrictAndShehia[district][shehia]["Months Since Most Recent Positive Individual"] = monthsAgo
        classificationByDistrictAndShehia[district][shehia].keys.push key
        if classificationByDistrictAndShehia[district][shehia]["Classification"] is currentClassificationRange
          classificationByDistrictAndShehia[district][shehia]["Number Indigenous Positive Individuals"] += row.value
        else # Update the classification and reset the count
          classificationByDistrictAndShehia[district][shehia]["Classification"] = currentClassificationRange
          classificationByDistrictAndShehia[district][shehia]["Number Indigenous Positive Individuals"] = row.value

      if @shehiasNotFoundInDHIS2?
        shehias = _(@shehiasNotFoundInDHIS2).uniq().sort()
        @$el.append "
          <h2>Classification Issues Requiring Cleaning/Updating</h2>
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

      if @nonUniqueShehiasWithDistrictNotFoundInDHIS2?
        shehiasWithDistrict = _(@nonUniqueShehiasWithDistrictNotFoundInDHIS2).uniq().sort()
        @$el.append "
          <br/></br>
          Cases with shehias that are non-unique, but the district doesn't have any shehias with that name (shehia, district):<br/>
          #{
            caseIds = []
            (for shehiaWithDistrict in shehiasWithDistrict
              [shehia,district,key] = shehiaWithDistrict.split(":")
              key = key.split(",")

              caseId = await Coconut.reportingDatabase.query "shehiasWithLocalCasesByYearWeek",
                reduce: false
                key: key
              .then (result) ->
                caseId = result.rows?[0].id[-6..]
                Promise.resolve(caseId)

              caseIds.push caseId

              "#{shehia} #{district} <a href='#show/case/#{caseId}'>#{caseId}</a>"
            ).join("<br/>") + "
            <button class='analyzeCases' data-caseIds='#{caseIds.join(',')}'>Analyze Cases</button>
            "
          }
        "

      console.log classificationByDistrictAndShehia

      result = _(for district, shehiaData  of classificationByDistrictAndShehia
        _(shehiaData).values()
      ).flatten()

      Promise.resolve result



module.exports = FociClassificationView
