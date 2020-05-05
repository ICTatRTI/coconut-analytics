# db:keep-people
(doc) ->
  if doc._id.indexOf("_link_") isnt -1
    emit doc.link[0], doc.link[1]
    emit doc.link[1], doc.link[0]
