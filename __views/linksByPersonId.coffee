# db:keep-people
#

#
(doc) ->
  if doc._id[0..4] is "link_"
    emit doc.link[0], doc.link[1]
    emit doc.link[1], doc.link[0]
