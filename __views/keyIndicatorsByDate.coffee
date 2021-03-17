# db:zanzibar-index-individual
(doc) ->
  if doc._id[0..3] is "ind_" and doc["Malaria Positive"] is true

    latLong = [doc["Household Location - Latitude"], doc["Household Location - Longitude"]]
    if latLong[0] is "" or latLong[0] is null
      latLong = null

    emit doc["Date Of Positive Results"],
      classification: doc["Classification"]
      latLong: latLong
      ageUnderFive: doc['Is Under 5']


