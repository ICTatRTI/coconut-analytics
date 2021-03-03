# db:zanzibar-index-individual
(doc) =>
  if doc._id[0..3] is "ind_"
    if doc["Focal Shehia"] and doc["Focal Shehia"] isnt "Outside Zanzibar"

      dateOfPositiveResults = doc["Date And Time Of Positive Results"]?[0..9] or doc["Date Of Positive Results"] or doc["Date Of Malaria Results"]
      emit [dateOfPositiveResults,doc["Focal District"],doc["Focal Shehia"]], null
