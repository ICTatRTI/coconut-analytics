# db:keep-people
(doc) -> # This is used for generating the CSV and uses the people database instead of the enrollments database

  if doc._id[0..5] is "person"

    fields = [
      "Year"
      "Term"
      "Region"
      "SchoolId"
      "Class"
      "Stream"
      "PersonId"
      "Name"
      "Sex"
      "Attendance - Days Eligible"
      "Attendance - Days Present"
      "Attendance - Percent"
      "Spotcheck - Jan"
      "Spotcheck - Feb"
      "Spotcheck - Mar"
      "Spotcheck - Apr"
      "Spotcheck - May"
      "Spotcheck - Jun"
      "Spotcheck - Jul"
      "Spotcheck - Aug"
      "Spotcheck - Sep"
      "Spotcheck - Oct"
      "Spotcheck - Nov"
      "Spotcheck - Dec"
      "Spotchecks - # Performed"
      "Spotchecks - # Present For"
      "Spotchecks - Attendance Mismatches"
      "Spotchecks - Attendance Mismatch Dates"
      "Performance - english"
      "Performance - kiswahili"
      "Performance - maths"
      "Performance - science"
      "Performance - social-studies"
      "Performance - biology"
      "Performance - physics"
      "Performance - chemistry"
      "Performance - history"
      "Performance - geography"
      "Performance - christian-religious-education"
      "Performance - islamic-religious-education"
      "Performance - music"
      "Performance - home-science"
      "Performance - art-and-craft"
      "Performance - agriculture"
      "Performance - arabic"
      "Performance - german"
      "Performance - french"
      "Performance - business-studies"
      "Performance - computer"
    ]

    termDates = {
      2017:
        1:
          start: "2017-01-04"
          end: "2017-04-07"
        2:
          start: "2017-05-02"
          end: "2017-08-02"
        3:
          start: "2017-08-28"
          end: "2017-10-27"
      2018:
        1:
          start: "2018-01-02"
          end: "2018-04-06"
        2:
          start: "2018-04-30"
          end: "2018-08-03"
        3:
          start: "2018-08-27"
          end: "2018-10-26"
      2019:
        1:
          start: "2019-01-02"
          end: "2019-04-05"
        2:
          start: "2019-04-29"
          end: "2019-08-02"
        3:
          start: "2019-08-26"
          end: "2019-10-25"
      2020:
        1:
          start: "2020-01-06"
          end: "2020-04-10"
        2:
          start: "2020-05-04"
          end: "2020-08-07"
        3:
          start: "2020-10-12"
          end: "2020-12-31"
        4:
          start: "2021-01-04"
          end: "2021-03-19"
        5:
          start: "2021-05-10"
          end: "2021-07-16"
      2021:
        1:
          start: "2021-07-26"
          end: "2020-10-01"
        2:
          start: "2021-10-11"
          end: "2021-12-23"
    }


    result = {}

    enrollments = {}

    for yearTerm, enrollment of doc.enrollments
      enrollments[yearTerm] = enrollment

    for enrollment, data of doc.attendance
      match = enrollment.match(/(20\d\d)-term-(\d)/)
      enrollments["#{match[1]}-T#{match[2]}"] = enrollment if match

    for enrollment, data of doc.performance
      match = enrollment.match(/(20\d\d)-term-(\d)/)
      enrollments["#{match[1]}-T#{match[2]}"] = enrollment if match

    for yearTerm, enrollment of enrollments
      [result["Year"], result["Term"]] = yearTerm.split(/-/)
      result["Term"] = result["Term"][1] # T2 -> 2
      result["Region"] = doc.most_recent_summary["Region"]
      result["Name"] = doc.most_recent_summary.Name
      result["Sex"] = doc.most_recent_summary.Sex or "NA"

      result["PersonId"] = doc.student_id

      [e,s,result["SchoolId"],y,t,tt,c,result["Class"],s,result["Stream"]] = enrollment.split(/-/)

      attendance = doc.attendance?[enrollment]
      if attendance
        daysEligibleForAttendance = 0
        daysPresent = 0
        for date, attendanceStatus of attendance
          switch attendanceStatus
            when "Present"
              daysEligibleForAttendance+=1
              daysPresent+=1
            when "Absent"
              daysEligibleForAttendance+=1
            when "Half"
              daysEligibleForAttendance+=1
              daysPresent+=0.5
            when "Left", "Unknown", "Holiday"
              null

        result["Attendance - Days Eligible"] = daysEligibleForAttendance
        result["Attendance - Days Present"] = daysPresent
        result["Attendance - Percent"] = parseInt(daysPresent/daysEligibleForAttendance*100)

      startDateForEnrollmentTerm = termDates[result["Year"]][result["Term"]]["start"]
      endDateForEnrollmentTerm = termDates[result["Year"]][result["Term"]]["end"]


      result["Spotchecks - # Performed"] = 0
      result["Spotchecks - # Present For"] = 0
      result["Spotchecks - Attendance Mismatches"] = 0
      result["Spotchecks - Attendance Mismatch Dates"] = []
      result["Spotcheck - Jan"] = null
      result["Spotcheck - Feb"] = null
      result["Spotcheck - Mar"] = null
      result["Spotcheck - Apr"] = null
      result["Spotcheck - May"] = null
      result["Spotcheck - Jun"] = null
      result["Spotcheck - Jul"] = null
      result["Spotcheck - Aug"] = null
      result["Spotcheck - Sep"] = null
      result["Spotcheck - Oct"] = null
      result["Spotcheck - Nov"] = null
      result["Spotcheck - Dec"] = null

      spotchecksPerformed = 0
      spotchecksPresentFor = 0
      spotchecksAttendanceMismatch = false

      for date, spotcheckResult of doc.spotchecks
        if startDateForEnrollmentTerm < date and date < endDateForEnrollmentTerm

          monthNumber = date[5..-4]
          monthAbbreviation = {
            "01":"Jan"
            "02":"Feb"
            "03":"Mar"
            "04":"Apr"
            "05":"May"
            "06":"Jun"
            "07":"Jul"
            "08":"Aug"
            "09":"Sep"
            "10":"Oct"
            "11":"Nov"
            "12":"Dec"
          }[monthNumber]

          result["Spotcheck - #{monthAbbreviation}"] = if spotcheckResult is "present" then "P" else "A"
          result["Spotchecks - # Performed"] +=1
          result["Spotchecks - # Present For"] +=1 if spotcheckResult is "present"
          if doc.attendance?[enrollment]?[date]?.toLowerCase() isnt spotcheckResult
            result["Spotchecks - Attendance Mismatches"] +=1
            result["Spotchecks - Attendance Mismatch Dates"].push date

      result["Spotchecks - Attendance Mismatch Dates"] = result["Spotchecks - Attendance Mismatch Dates"].join(" ")

      performance = doc.performance?[enrollment]
      if performance
        for category, score of performance
          result["Performance - #{category}"] = score

      keyToEmit = [
        result["Year"]
        result["Term"]
        result["Region"]
        result["SchoolId"]
        result["Class"]
        result["Stream"]
        result["PersonId"]
      ]

      valueToEmit = []
      for field in fields
        valueToEmit.push result[field] or null

      emit keyToEmit, valueToEmit
