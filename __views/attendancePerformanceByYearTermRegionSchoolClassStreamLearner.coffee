# db:keep-people

# This is used for generating the CSV and uses the people database instead of the enrollments database
(doc) ->
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

  if doc._id[0..5] is "person"
    result = {}

    for yearTerm, enrollment of doc.enrollments
      [result["Year"], result["Term"]] = yearTerm.split(/-/)
      result["Term"] = result["Term"][1] # T2 -> 2
      result["Region"] = doc.most_recent_summary["Region"]
      result["Name"] = doc.most_recent_summary.Name
      result["Sex"] = doc.most_recent_summary.Sex

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
