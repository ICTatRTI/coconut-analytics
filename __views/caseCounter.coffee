# db:zanzibar-reporting
(doc) ->
  if doc._id.lastIndexOf("case_summary_", 0) is 0 # Implements startsWith http://stackoverflow.com/a/4579228/266111
    if doc["Index Case Diagnosis Date"]?
      indexCaseDiagnosisDate = doc["Index Case Diagnosis Date"]
      return unless indexCaseDiagnosisDate
      administrativeLevels = doc["Names Of Administrative Levels"]?.split(/, */)

      if doc["Classifications By Diagnosis Date"]?
        if doc["Classifications By Diagnosis Date"] is ""
          emit [indexCaseDiagnosisDate, "Unclassified"].concat(administrativeLevels), 1
        else
          for positiveIndividual in doc["Classifications By Diagnosis Date"].split(", ")
            [date, classification] = positiveIndividual.split(": ")
            date or= indexCaseDiagnosisDate # 131449 and others are missing the date so just set it back to the indexCaseDiagnosisDate
            emit [date, classification].concat(administrativeLevels), 1

      emit [indexCaseDiagnosisDate, "Has Notification"].concat(administrativeLevels), 1
      emit [indexCaseDiagnosisDate, "Complete Household Visit"].concat(administrativeLevels), if doc["Complete Household Visit"] then 1 else 0

      numberBasedIndicators = [
        "Number Positive Individuals Under 5"
        "Number Positive Individuals Over 5"
        "Number Positive Individuals"
        "Number Positive Individuals At Household Excluding Index"
        "Number Household Members Tested"
        "Number Household Members Tested and Untested"
        "Number Positive Cases From Mass Screen"
        "Number Index And Household Cases Suspected To Be Imported"
      ]
      for indicator in numberBasedIndicators
        emit [indexCaseDiagnosisDate, indicator].concat(administrativeLevels), doc[indicator] or 0

      booleanBasedIndicators = [
        "Less Than One Day Between Positive Result And Notification From Facility"
        "One To Two Days Between Positive Result And Notification From Facility"
        "Two To Three Days Between Positive Result And Notification From Facility"
        "More Than Three Days Between Positive Result And Notification From Facility"
                                                                                     
        "Less Than One Day Between Positive Result And Complete Household"
        "One To Two Days Between Positive Result And Complete Household"
        "Two To Three Days Between Positive Result And Complete Household"
        "More Than Three Days Between Positive Result And Complete Household"
      ]
      for indicator in booleanBasedIndicators
        if doc[indicator]
          emit [indexCaseDiagnosisDate, indicator].concat(administrativeLevels), 1


      ###
      total = doc["Number Positive Individuals"]
      under5 = doc["Number Positive Individuals Under 5"]
      over5 = total - under5
      emit [indexCaseDiagnosisDate, "Followed Up"].concat(administrativeLevels), if doc["Complete Household Visit"] then 1 else 0
      emit [indexCaseDiagnosisDate, "Number Positive Cases Including Index"].concat(administrativeLevels), doc["Number Positive Individuals"]
      emit [indexCaseDiagnosisDate, "Number Positive Individuals At Household Excluding Index"].concat(administrativeLevels), doc["Number Positive Individuals At Household Excluding Index"] or 0
      emit [indexCaseDiagnosisDate, "Number Household Members Tested"].concat(administrativeLevels), doc["Number Household Members Tested"]
      emit [indexCaseDiagnosisDate, "Number Household Members Tested and Untested"].concat(administrativeLevels), doc["Number Household Members Tested And Untested"] or 0
      emit [indexCaseDiagnosisDate, "Number Positive Cases From Mass Screen"].concat(administrativeLevels), doc["Number Positive Cases At Index Household"] if doc["Mass Screen Case"] is true
      emit [indexCaseDiagnosisDate, "Number Index And Household Cases Suspected To Be Imported"].concat(administrativeLevels), doc["Number Suspected Imported Cases Including Household Members"]

      emit [indexCaseDiagnosisDate, "Less Than One Day Between Positive Result And Notification From Facility"].concat(administrativeLevels), 1 if doc["Less Than One Day Between Positive Result And Notification From Facility"]
      emit [indexCaseDiagnosisDate, "One To Two Days Between Positive Result And Notification From Facility"].concat(administrativeLevels), 1 if doc["One To Two Days Between Positive Result And Notification From Facility"]
      emit [indexCaseDiagnosisDate, "Two To Three Days Between Positive Result And Notification From Facility"].concat(administrativeLevels), 1 if doc["Two To Three Days Between Positive Result And Notification From Facility"]
      emit [indexCaseDiagnosisDate, "More Than Three Days Between Positive Result And Notification From Facility"].concat(administrativeLevels), 1 if doc["More Than Three Days Between Positive Result And Notification From Facility"]

      emit [indexCaseDiagnosisDate, "Less Than One Day Between Positive Result And Complete Household"].concat(administrativeLevels), 1 if doc["Less Than One Day Between Positive Result And Complete Household"]
      emit [indexCaseDiagnosisDate, "One To Two Days Between Positive Result And Complete Household"].concat(administrativeLevels), 1 if doc["One To Two Days Between Positive Result And Complete Household"]
      emit [indexCaseDiagnosisDate, "Two To Three Days Between Positive Result And Complete Household"].concat(administrativeLevels), 1 if doc["Two To Three Days Between Positive Result And Complete Household"]
      emit [indexCaseDiagnosisDate, "More Than Three Days Between Positive Result And Complete Household"].concat(administrativeLevels), 1 if doc["More Than Three Days Between Positive Result And Complete Household"]
      ###
