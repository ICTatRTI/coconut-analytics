# db:zanzibar-reporting
(doc) ->
  if doc._id.lastIndexOf("case_summary_", 0) is 0 # Implements startsWith http://stackoverflow.com/a/4579228/266111
    if doc["Household Location - Latitude"] and doc["Household Location - Longitude"]
        emit doc["Index Case Diagnosis Date"],
        { latLong: [doc["Household Location - Latitude"], doc["Household Location - Longitude"]],
        ageUnderFive: doc['Is Index Case Under 5'],
        overnightTravelPastYear: doc['Overnight Travel Outside of Zanzibar In The Past Year']
        }
