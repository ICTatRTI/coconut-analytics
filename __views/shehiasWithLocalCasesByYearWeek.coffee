# db:zanzibar-reporting
(doc) ->
  if doc._id.lastIndexOf("case_summary_", 0) is 0 # Implements startsWith http://stackoverflow.com/a/4579228/266111
    if doc["Classifications By Iso Year Iso Week Foci District Foci Shehia"]?
      for classification in doc["Classifications By Iso Year Iso Week Foci District Foci Shehia"].split(", ")

        classificationData = classification.split(":")
        [isoYear, isoWeek, fociDistrict, fociShehia, classification] = classificationData
        if classification is "Indigenous" or classification is "Unclassified" or classification is "Introduced"
          emit [isoYear,isoWeek, fociDistrict, fociShehia], 1
      ###
      indexCaseDiagnosisDate = doc["Index Case Diagnosis Date"]
      district = doc["District (if no household district uses facility)"]
      shehia = doc["Shehia"]?.toUpperCase()

      return unless indexCaseDiagnosisDate and shehia and district
        # Copy date so don't modify original
        d = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()))
        # Set to nearest Thursday: current date + 4 - current day number
        # Make Sunday's day number 7
        d.setUTCDate(d.getUTCDate() + 4 - (d.getUTCDay()||7))
        # Get first day of year
        yearStart = new Date(Date.UTC(d.getUTCFullYear(),0,1))
        # Calculate full weeks to nearest Thursday
        weekNo = Math.ceil(( ( (d - yearStart) / 86400000) + 1)/7)
        # Return array of year and week number
        [d.getUTCFullYear(), weekNo]

      if doc["Classifications By Diagnosis Date"]?
        if doc["Classifications By Diagnosis Date"] is ""
          #emit [indexCaseDiagnosisDate, "Unclassified"].concat(administrativeLevels), 1
        else
          for positiveIndividual in doc["Classifications By Diagnosis Date"].split(", ")
            [date, classification] = positiveIndividual.split(": ")
            if classification is "Indigenous" or classification is "Unclassified"
              # 131449 and others are missing the date so just set it back to the indexCaseDiagnosisDate
              if not date? or date is "undefined"
                date = indexCaseDiagnosisDate
              date or= indexCaseDiagnosisDate 
              [year,month,day] = date.split("-")
              date = new Date(year, month-1, day)
              [isoYear,isoWeek] = getYearISOWeek(date)
              emit [isoYear,isoWeek, district, shehia], 1
      ###
