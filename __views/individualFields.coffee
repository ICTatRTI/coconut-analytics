# db:zanzibar-index-individual
(doc) ->
  if doc._id[0..3] is "ind_"
    for key in Object.keys(doc)
      if key? and key isnt ""
        emit key
