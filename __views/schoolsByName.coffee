# db:keep-schools
(doc) ->
  if doc._id[0..5] is "school"
    emit doc.Name
