# db:zanzibar-index-individual
(doc) ->
  if doc._id[0..3] is "ind_"
    if doc["Classification"]? and doc["Administrative Levels"]
        # Administrative Levels Uses focal shehia if within Zanzibar. If focal is outside, then use household shehia
        emit [doc["Classification"]].concat(doc["Administrative Levels"]?.split(",")), 1
