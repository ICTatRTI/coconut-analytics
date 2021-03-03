# db:zanzibar-reporting
(doc) ->
  if doc._id.lastIndexOf("case_summary_", 0) is 0 # Implements startsWith http://stackoverflow.com/a/4579228/266111

    zone = doc["Names Of Administrative Levels"]?.split(",")?[1]

    for dateAndClassification in doc["Classifications By Diagnosis Date"]?.split(/, */)
      [diagnosisDate, classification] = dateAndClassification.split(': ')
      [year, month, day] = diagnosisDate.split("-")

      # https://stackoverflow.com/questions/6117814/get-week-of-year-in-javascript-like-in-php
      d = new Date(Date.UTC(year, month - 1, day))
      dayNum = d.getUTCDay() or 7
      d.setUTCDate(d.getUTCDate() + 4 - dayNum)
      yearStart = new Date(Date.UTC(d.getUTCFullYear(),0,1))
      weekNumber = Math.ceil((((d - yearStart) / 86400000) + 1)/7)
      weekNumber = "0#{weekNumber}" if weekNumber < 10

      diagnosisDateIsoWeek = "#{year}-#{weekNumber}"

      emit [diagnosisDateIsoWeek, zone, "Classification: #{classification}"], 1 
      
    emit [doc["Index Case Diagnosis Date ISO Week"], zone, "Has Case Notification"], 1 if doc["Has Case Notification"]
    emit [doc["Index Case Diagnosis Date ISO Week"], zone, "Complete Household Visit"], 1 if doc["Complete Household Visit"]
