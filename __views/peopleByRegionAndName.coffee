# db:keep-people
(doc) ->
  region = doc.most_recent_summary?.Region
  names = {}
  if region
    names[doc.most_recent_summary.Name.toUpperCase()] = true
    for term, termData of doc.verifications
      names[termData["Student Name"].toUpperCase()] = true
    for term, termData of doc["Performance and Attendance"]
      names[termData["Student Name"].toUpperCase()] = true

    for name, bool of names
      emit [region,name]
