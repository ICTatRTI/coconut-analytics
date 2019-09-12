# db:zanzibar-reporting
(doc) ->
  if doc._id.lastIndexOf("case_summary_", 0) is 0 # Implements startsWith http://stackoverflow.com/a/4579228/266111

    for dateAndClassification in doc["Classifications By Diagnosis Date"]?.split(/, */)
      [diagnosisDate, classification] = dateAndClassification.split(/: */)
      latLong = [doc["Household Location - Latitude"], doc["Household Location - Longitude"]]
      if latLong[0] is "" or latLong[0] is null
        latLong = null

      emit diagnosisDate,
        classification: classification
        latLong: latLong
        ageUnderFive: doc['Is Index Case Under 5']


