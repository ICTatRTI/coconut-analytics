# db:zanzibar-reporting
(doc) ->
  if doc._id.lastIndexOf("case_summary_", 0) is 0 # Implements startsWith http://stackoverflow.com/a/4579228/266111
    if doc["Index Case Diagnosis Date ISO Week"]?
      indexCaseDiagnosisWeek = doc["Index Case Diagnosis Date ISO Week"]
      administrativeLevels = doc["Names Of Administrative Levels"]
      total = doc["Number Positive Individuals"]
      emit [indexCaseDiagnosisWeek].concat(administrativeLevels), total

