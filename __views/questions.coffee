(doc) ->
  if doc.collection and doc.collection is "question"
    emit doc.id
