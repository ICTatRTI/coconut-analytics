_ = require 'underscore'
$ = require 'jquery'
moment = require 'moment'

Reports = require './Reports'

class Issues

  @resetEpidemicThreshold = =>
    Coconut.database.allDocs
      startkey: "threshold-"
      endkey:   "threshold-\ufff0"
    .then (result) ->
      docsToDelete = for row in result.rows
          _id: row.id
          _rev: row.value.rev
          _deleted: true

      console.log "Resetting epidemic thresholds: Removing #{docsToDelete.length} thresholds."

      Coconut.database.bulkDocs docsToDelete
      .catch (error) -> console.error error


  @updateEpidemicAlertsAndAlarmsForLastXDaysShowResult = (days) =>
    @updateEpidemicAlertsAndAlarmsForLastXDays days,
      success: (result) ->
        $("body").html result

  @updateEpidemicAlertsAndAlarmsForLastXDays = (days, options) =>
    new Promise (resolve, reject) =>
      allResults = {}
      for daysAgo in [days..0]
        console.log "Days remaining to check: #{daysAgo}"
        endDate = moment().subtract(daysAgo, 'days').format("YYYY-MM-DD")
        _(allResults).extend (await Issues.updateEpidemicAlertsAndAlarms
            save: if options?.save? then options.save else true
            endDate: endDate
          .catch (error) -> console.error error
        )
      resolve(allResults)

  @updateEpidemicAlertsAndAlarms = (options) =>
    new Promise (resolve, reject) ->
      endDate = options?.endDate   or moment().subtract(2,'days').format("YYYY-MM-DD")

      thresholds = (await Coconut.reportingDatabase.get "epidemic_thresholds"
        .catch =>
          console.log "Thresholds missing, so creating it in the database"
          thresholds = {
            "_id": "epidemic_thresholds"
            "data":
              "7-days": [
                {
                  type: "Alert"
                  aggregationArea: "facility"
                  indicator: "Has Notification"
                  threshold: 10
                }
                {
                  type: "Alert"
                  aggregationArea: "shehia"
                  indicator: "Number Positive Individuals Under 5"
                  threshold: 5
                }
                {
                  type: "Alert"
                  aggregationArea: "shehia"
                  indicator: "Number Positive Individuals"
                  threshold: 10
                }
              ]
              "14-days": [
                {
                  type: "Alarm"
                  aggregationArea: "facility"
                  indicator: "Has Notification"
                  threshold: 20
                }
                {
                  type: "Alarm"
                  aggregationArea: "shehia"
                  indicator: "Number Positive Individuals Under 5"
                  threshold: 10
                }
                {
                  type: "Alarm"
                  aggregationArea: "shehia"
                  indicator: "Number Positive Individuals"
                  threshold: 20
                }
              ]
          }
                
          await Coconut.reportingDatabase.put thresholds
          Promise.resolve thresholds
      ).data

      docsToSave = {}

      for range, thresholdsForRange of thresholds
        [amountOfTime,timeUnit] = range.split(/-/)

        startDate = moment(endDate).subtract(amountOfTime,timeUnit).format("YYYY-MM-DD")
        yearAndIsoWeekOfEndDate = moment(endDate).format("GGGG-WW")

        console.log "#{startDate} - #{endDate}"

        aggregatedResults = await Reports.positiveCasesAggregated
          thresholds: thresholdsForRange
          startDate: startDate
          endDate: endDate
        .catch (error) -> 
          console.error "ERROR"
          console.error error

        for aggregationAreaType, r1 of aggregatedResults
          for aggregationArea, r2 of r1
            for indicator, r3 of r2
              if r3.length > 9
                console.log "#{aggregationAreaType} #{aggregationArea} #{indicator} #{r3.length}"

        for threshold in thresholdsForRange
          aggregationArea = threshold.aggregationArea

          for locationName, indicatorData of aggregatedResults[aggregationArea]

            # console.log "#{indicatorData[threshold.indicator]?.length} > #{threshold.threshold}"
            if indicatorData[threshold.indicator]?.length > threshold.threshold
              id = "threshold-#{yearAndIsoWeekOfEndDate}-#{threshold.type}-#{range}-#{aggregationArea}-#{threshold.indicator}.#{locationName}"
              console.log id
              #id = "threshold-#{startDate}--#{endDate}-#{threshold.type}-#{range}-#{aggregationArea}-#{threshold.indicator}.#{locationName}"
              docsToSave[id] =
                _id: id
                Range: range
                LocationType: aggregationArea
                ThresholdName: threshold.indicator
                ThresholdType: threshold.type
                LocationName: locationName
                District: indicatorData[threshold.indicator][0].district
                StartDate: startDate
                EndDate: endDate
                YearWeekEndDate: yearAndIsoWeekOfEndDate 
                Amount: indicatorData[threshold.indicator].length
                Threshold: threshold.threshold
                "Threshold Description": "#{threshold.type}: #{aggregationArea} with #{threshold.threshold} or more '#{threshold.indicator}' within #{range}"
                Description: "#{aggregationArea}: #{locationName}, Cases: #{indicatorData[threshold.indicator].length}, Period: #{startDate} - #{endDate}"
                Links: _(indicatorData[threshold.indicator]).pluck "link"
                "Date Created": moment().format("YYYY-MM-DD HH:mm:ss")
                AdditionalIncidents: []
              docsToSave[id][aggregationArea] = locationName

        # In case of alarm, then remove the alert that was also created
        for id, docToSave of docsToSave
          #console.log id
          if docToSave.ThresholdType is "Alarm"
            #console.log "Removing #{id.replace(/Alarm/, "Alert")} since we also crossed alarm threshold"
            delete docsToSave[docToSave._id.replace(/Alarm/,"Alert")]

          existingThresholdForSameWeek = await Coconut.database.get docToSave._id
          .catch (error) => # Threshold doesn't exist, so don't do anything


          if existingThresholdForSameWeek # don't save the new one
            # Add additional information
            existingThresholdForSameWeek.AdditionalIncidents.push
              StartDate: docsToSave[docToSave._id].StartDate
              EndDate: docsToSave[docToSave._id].EndDate
              Amount: docsToSave[docToSave._id].Amount
              Links: docsToSave[docToSave._id].Links
            docsToSave[docToSave._id] = existingThresholdForSameWeek


        ###
        # Note that this is inside the thresholds loop so that we have the right amountOfTime and timeUnit
        Coconut.database.allDocs
          startkey: "threshold-#{moment(startDate).subtract(2*amountOfTime,timeUnit).format("GGGG-WW")}"
          endkey:   "threshold-#{yearAndIsoWeekOfEndDate}"
        .then (result) ->
          _(docsToSave).each (docToSave) ->
            #console.debug "Checking for existing thresholds that match #{docToSave._id}"
            if (_(result.rows).some (existingThreshold) ->
              # If after removing the date, the ids match, then it's a duplicate
              existingThresholdIdNoDates = existingThreshold.id.replace(/\d\d\d\d-\d\d-\d\d/g,"")
              docToSaveIdNoDates = docToSave._id.replace(/\d\d\d\d-\d\d-\d\d/g,"")

              return true if existingThresholdIdNoDates is docToSaveIdNoDates
              # If an alarm has already been created, don't also create an Alert
              if docToSave.ThresholdType is "Alert"
                return true if existingThresholdIdNoDates.replace(/Alarm/,"") is docToSaveIdNoDates.replace(/Alert/,"")
              return false
            )
              delete docsToSave[docToSave._id]            
          Promise.resolve()
        .catch (error) -> console.error error
        ###

      unless options.save
        #console.log "RESULT:"
        #console.log JSON.stringify docsToSave, null, 1
        #console.log "Not saving."
        return resolve(docsToSave)

      await Coconut.database.bulkDocs _(docsToSave).values()
      .catch (error) -> console.error error
      resolve(docsToSave)

module.exports = Issues
