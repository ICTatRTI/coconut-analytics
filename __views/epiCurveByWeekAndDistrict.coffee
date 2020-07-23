# db:zanzibar-reporting
(doc) ->
  if doc._id.lastIndexOf("case_summary_", 0) is 0 # Implements startsWith http://stackoverflow.com/a/4579228/266111

    ###

    if doc["Classifications By Diagnosis Date"]?
      # From https://stackoverflow.com/questions/6117814/get-week-of-year-in-javascript-like-in-php/6117889#6117889
      getWeekNumber = (d) ->
        # Copy date so don't modify original
        d = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()))
        # Set to nearest Thursday: current date + 4 - current day number
        # Make Sunday's day number 7
        d.setUTCDate(d.getUTCDate() + 4 - (d.getUTCDay()||7))
        # Get first day of year
        yearStart = new Date(Date.UTC(d.getUTCFullYear(),0,1))
        # Calculate full weeks to nearest Thursday
        weekNo = Math.ceil(( ( (d - yearStart) / 86400000) + 1)/7)
        # Return array of year and week number
        return [d.getUTCFullYear(), weekNo]


      for dateAndClassification in doc["Classifications By Diagnosis Date"].split(", ")
        [date,classification] = dateAndClassification.split(": ")
        [year,month,day] = for datePart in date.split("-")
          parseInt(datePart)

        [year,week] = getWeekNumber(new Date(year,month-1,day))

        weekString = if week < 10 then "0#{week}" else "#{week}"

    ###
    #    administrativeLevels = doc["Names Of Administrative Levels"]?.split(/, */)
    ###
        emit ["#{year}-#{weekString}"].concat(administrativeLevels), 1
    ###

    # Old method didn't use precise dates for individuals
    if doc["Index Case Diagnosis Date ISO Week"]?
      indexCaseDiagnosisWeek = doc["Index Case Diagnosis Date ISO Week"]
      administrativeLevels = doc["Names Of Administrative Levels"]?.split(/, */)
      total = doc["Number Positive Individuals"]
      #TODO don't use Number Positive Individuals, use the date of positive for each individual
      emit [indexCaseDiagnosisWeek].concat(administrativeLevels), total

