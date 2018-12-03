# db:zanzibar
(doc) ->
  if doc._id.lastIndexOf("case_summary_", 0) is 0 # Implements startsWith http://stackoverflow.com/a/4579228/266111
    emit doc["Index Case Diagnosis Date"], doc["Malaria Case ID"]
