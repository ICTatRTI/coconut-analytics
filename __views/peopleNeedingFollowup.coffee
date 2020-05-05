# db:keep-people
(doc) =>
  if doc.attendance
    for enrollment, attendanceData of doc.attendance
      daysInRowMissing = 0
      fiveDaysInRowMissing = false
      for date,attendanceStatus of attendanceData
        if daysInRowMissing >= 5
          fiveDaysInRowMissing = true

        if attendanceStatus is "Absent"
          daysInRowMissing += 1
          if daysInRowMissing >= 5
            lastDateForFiveDaysMissing = date
        else if attendanceStatus is "Present"
          daysInRowMissing = 0
        # If Holiday/Half/Unknown - just ignore for counting purposes
        #
        #
      daysMissingInLast30 = 0
      sevenDaysInLast30Missing = false
      index = 0
      # Check all continuous 30 day ranges
      while (ThirtyDayRange = Object.keys(attendanceData)[index..30]).length >= 30
        for date in ThirtyDayRange
          attendanceStatus = attendanceData[date]
          if attendanceStatus is "Absent"
            daysMissingInLast30+=1
            lastDateForSevenDaysInLast30Missing = date
        sevenDaysInLast30Missing = true if daysMissingInLast30 >= 7
        index+=1

      [a,b,schoolId,year,c,term,d,className,e,stream,streamGender] = enrollment.split(/-/)

      if sevenDaysInLast30Missing
        name = doc.most_recent_summary?.Name
        gender = doc.most_recent_summary?.Sex
        emit [year,term,lastDateForSevenDaysInLast30Missing,schoolId,className,stream,name,gender], "7 Days in 30 Absent"

      if fiveDaysInRowMissing
        emit [year,term,lastDateForFiveDaysMissing, schoolId,className,stream,name,gender], "5 Consecutive Days Absent"
