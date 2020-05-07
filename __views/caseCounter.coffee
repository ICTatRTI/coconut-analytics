# db:zanzibar-reporting
(doc) ->
  if doc._id.lastIndexOf("case_summary_", 0) is 0 # Implements startsWith http://stackoverflow.com/a/4579228/266111
    if doc["Index Case Diagnosis Date"]?
      indexCaseDiagnosisDate = doc["Index Case Diagnosis Date"]
      district = doc["District (if no household district uses facility)"]
      shehia = doc["Shehia"]
      total = doc["Number Positive Individuals"]
      under5 = doc["Number Positive Individuals Under 5"]
      over5 = total - under5

      if doc["Classifications By Diagnosis Date"]?
        if doc["Classifications By Diagnosis Date"] is ""
          emit [indexCaseDiagnosisDate, "Unclassified", district, shehia], 1
        else
          for positiveIndividual in doc["Classifications By Diagnosis Date"].split(", ")
            [date, classification] = positiveIndividual.split(": ")
            emit [date, classification, district, shehia], 1

      emit [indexCaseDiagnosisDate, "Over 5", district, shehia], over5
      emit [indexCaseDiagnosisDate, "Under 5", district, shehia], under5
      emit [indexCaseDiagnosisDate, "Has Notification", district, shehia], 1
      emit [indexCaseDiagnosisDate, "Followed Up", district, shehia], if doc["Complete Household Visit"] then 1 else 0
      emit [indexCaseDiagnosisDate, "Number Positive Cases Including Index", district, shehia], doc["Number Positive Individuals"]
      emit [indexCaseDiagnosisDate, "Number Positive Individuals At Household Excluding Index", district, shehia], doc["Number Positive Individuals At Household Excluding Index"] or 0
      emit [indexCaseDiagnosisDate, "Number Household Members Tested", district, shehia], doc["Number Household Members Tested"]
      emit [indexCaseDiagnosisDate, "Number Household Members Tested and Untested", district, shehia], doc["Number Household Members Tested And Untested"] or 0
      emit [indexCaseDiagnosisDate, "Number Positive Cases From Mass Screen", district, shehia], doc["Number Positive Cases At Index Household"] if doc["Mass Screen Case"] is true
      emit [indexCaseDiagnosisDate, "Number Index And Household Cases Suspected To Be Imported", district, shehia], doc["Number Suspected Imported Cases Including Household Members"]

      emit [indexCaseDiagnosisDate, "Less Than One Day Between Positive Result And Notification From Facility", district, shehia], 1 if doc["Less Than One Day Between Positive Result And Notification From Facility"]
      emit [indexCaseDiagnosisDate, "One To Two Days Between Positive Result And Notification From Facility", district, shehia], 1 if doc["One To Two Days Between Positive Result And Notification From Facility"]
      emit [indexCaseDiagnosisDate, "Two To Three Days Between Positive Result And Notification From Facility", district, shehia], 1 if doc["Two To Three Days Between Positive Result And Notification From Facility"]
      emit [indexCaseDiagnosisDate, "More Than Three Days Between Positive Result And Notification From Facility", district, shehia], 1 if doc["More Than Three Days Between Positive Result And Notification From Facility"]

      emit [indexCaseDiagnosisDate, "Less Than One Day Between Positive Result And Complete Household", district, shehia], 1 if doc["Less Than One Day Between Positive Result And Complete Household"]
      emit [indexCaseDiagnosisDate, "One To Two Days Between Positive Result And Complete Household", district, shehia], 1 if doc["One To Two Days Between Positive Result And Complete Household"]
      emit [indexCaseDiagnosisDate, "Two To Three Days Between Positive Result And Complete Household", district, shehia], 1 if doc["Two To Three Days Between Positive Result And Complete Household"]
      emit [indexCaseDiagnosisDate, "More Than Three Days Between Positive Result And Complete Household", district, shehia], 1 if doc["More Than Three Days Between Positive Result And Complete Household"]

