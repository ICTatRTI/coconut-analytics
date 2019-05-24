# db:zanzibar-reporting
(doc) ->
  if doc._id.lastIndexOf("case_summary_", 0) is 0 # Implements startsWith http://stackoverflow.com/a/4579228/266111
    emit [doc["Index Case Diagnosis Date"]].concat(doc["Names Of Administrative Levels"].split(',')), doc["Number Positive Cases Including Index"] or 0
