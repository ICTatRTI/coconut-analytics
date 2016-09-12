(doc) ->
  if doc._id.lastIndexOf("case_summary_", 0) is 0 # Implements startsWith http://stackoverflow.com/a/4579228/266111
    if doc["Index Case Diagnosis Date"]?
      total = doc["Number Positive Cases Including Index"]
      under5 = doc["Number Positive Cases At Index Household And Neighbor Households Under5"]
      over5 = total - under5
      emit [doc["Index Case Diagnosis Date"], "Over 5"], over5
      emit [doc["Index Case Diagnosis Date"], "Under 5"], under5
      emit [doc["Index Case Diagnosis Date"], "Has Notification"], 1
      emit [doc["Index Case Diagnosis Date"], "Followed Up"], doc["Complete Household Visit"] ? 1 : 0
      emit [doc["Index Case Diagnosis Date"], "Number Of Positive Cases At Index Household"], doc["Number Positive Cases At Index Household"]
      emit [doc["Index Case Diagnosis Date"], "Number Household Members Tested And Untested"], doc["Number Positive Cases At Index Household"]
      emit [doc["Index Case Diagnosis Date"], "Number Household Members Tested"], doc["Number Household Members Tested"]
      emit [doc["Index Case Diagnosis Date"], "Number Household Members Tested"], doc["Number Household Members Tested and Untested"]
      emit [doc["Index Case Diagnosis Date"], "Number Positive Cases From Mass Screen"], doc["Number Positive Cases At Index Household"] if doc["Mass Screen Case"] is true
      emit [doc["Index Case Diagnosis Date"], "Number Index Cases Suspected To Be Imported"], doc["Index Case Overnight Travel Within Zanzibar 10-24 Days Before Positive Test Result"] ? 1 : 0

