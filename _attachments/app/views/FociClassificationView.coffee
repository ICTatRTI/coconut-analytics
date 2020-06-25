_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
Tabulator = require 'tabulator-tables'

class FociClassificationView extends Backbone.View
  el: "#content"

  events:
    "click #download": "csv"

  csv: => @tabulator.download "csv", "CoconutTableExport.csv"

  render: =>
    @$el.html "
      <h2 onClick='$(\"#foci-classification-description\").toggle()'>Foci Classifications ▶</h2>
      <br/>
      <div id='foci-classification-description' style='display:none'>
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
      <button id='download'>CSV ↓</button> <small>Add more fields by clicking the box below</small>
      <div id='tabulator'>
      </div>
      <div id='map'>
      </div>
    "

    @renderTabulator()

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
        Classification: "Cleared"
      }
      if shehiaName is "KINYASINI"
        console.log classificationByDistrictAndShehia[districtName][shehiaName]

    dateToday = moment()
    dateForClearedPeriod = moment().subtract(36,"months")
    yearClearedPeriod = dateForClearedPeriod.year()
    monthClearedPeriod = dateForClearedPeriod.month() + 1 # 0 index months

    Coconut.reportingDatabase.query "shehiasWithLocalCasesByYearWeek",
      reduce: true
      group_level: 4
      startkey: [yearClearedPeriod, monthClearedPeriod]
    .catch (error) -> console.error error
    .then (result) =>
      for row in result.rows
        [year,month,district,shehia] = row.key
        shehia = shehia.trim()
        localCaseDate = moment("#{year} #{month}", "YYYY MM")
        monthsAgo = dateToday.diff(localCaseDate, "months")

        currentClassificationRange = if monthsAgo > 12
          "Residual non-active"
        else
          "Active"


        unless classificationByDistrictAndShehia[district]?
          console.log "DISTRICT not found:"
          console.log district

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
              @shehiasNotFoundInDHIS2 or= []
              @shehiasNotFoundInDHIS2.push shehia
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


        if classificationByDistrictAndShehia[district][shehia]["Classification"] is currentClassificationRange
          classificationByDistrictAndShehia[district][shehia]["Number Indigenous Positive Individuals"] += row.value
        else # Update the classification and reset the count
          classificationByDistrictAndShehia[district][shehia]["Classification"] = currentClassificationRange
          classificationByDistrictAndShehia[district][shehia]["Number Indigenous Positive Individuals"] = row.value

      if @shehiasNotFoundInDHIS2?
        shehias = _(@shehiasNotFoundInDHIS2).uniq().sort()
        @$el.append "
          Shehias (#{shehias.length}) referred to in cases but not known (not in DHIS2 and or requires aliases to be hooked up here):<br/>
          #{shehias.join("<br/>")}
        "

      console.log classificationByDistrictAndShehia

      result = _(for district, shehiaData  of classificationByDistrictAndShehia
        _(shehiaData).values()
      ).flatten()


      Promise.resolve result



module.exports = FociClassificationView
