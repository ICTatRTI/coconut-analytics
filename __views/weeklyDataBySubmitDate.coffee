# db:zanzibar
(doc) ->
  if doc.type is "Weekly Facility Report"
    key = [
      doc["Year"]
      # Make sure to prepend 0 for single digit weeks
      ('0' + doc["Week"]).slice(-2)
    ]
    emit(key,doc["Submit Date"])
