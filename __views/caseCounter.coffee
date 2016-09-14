(doc) ->
  if doc._id.lastIndexOf("case_summary_", 0) is 0 # Implements startsWith http://stackoverflow.com/a/4579228/266111
    if doc["Index Case Diagnosis Date"]?
      total = doc["Number Positive Cases Including Index"]
      under5 = doc["Number Positive Cases At Index Household And Neighbor Households Under5"]
      over5 = total - under5
      emit [doc["Index Case Diagnosis Date"], "Over 5"], over5
      emit [doc["Index Case Diagnosis Date"], "Under 5"], under5
      emit [doc["Index Case Diagnosis Date"], "Has Notification"], 1
      emit [doc["Index Case Diagnosis Date"], "Followed Up"], if doc["Complete Household Visit"] then 1 else 0
      emit [doc["Index Case Diagnosis Date"], "Number Household Members Tested Positive"], doc["Number Positive Cases At Index Household"]
      emit [doc["Index Case Diagnosis Date"], "Number Household Members Tested"], doc["Number Household Members Tested"]
      emit [doc["Index Case Diagnosis Date"], "Number Household Members Tested and Untested"], doc["Number Household Members Tested And Untested"] or 0
      emit [doc["Index Case Diagnosis Date"], "Number Positive Cases From Mass Screen"], doc["Number Positive Cases At Index Household"] if doc["Mass Screen Case"] is true
      emit [doc["Index Case Diagnosis Date"], "Number Index And Household Cases Suspected To Be Imported"], doc["Number Suspected Imported Cases Including Household Members"]

