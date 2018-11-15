(doc) ->
  if doc._id.lastIndexOf("threshold-", 0) is 0 # Implements startsWith http://stackoverflow.com/a/4579228/266111
    emit [doc.StartDate, doc.ThresholdType], 1
