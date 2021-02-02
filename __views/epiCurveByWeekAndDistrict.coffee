# db:zanzibar-index-individual
(doc) ->
  if doc._id[0..3] is "ind_"
    if doc["Year Week Of Positive Results"]?
      # Administrative Levels Uses focal shehia if within Zanzibar. If focal is outside, then use household shehia
      emit [doc["Year Week Of Positive Results"]].concat(doc["Administrative Levels"]?.split(",")), 1

