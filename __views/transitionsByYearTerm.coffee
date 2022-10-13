# db:keep-people
(doc) ->

  if doc.enrollments

    allTermsEnrolled = {}

    for performanceTerm, data of doc.performance
      allTermsEnrolled[performanceTerm.match(/(2\d\d\d-term-\d)/)?[1].replace(/term-/,"T")] = performanceTerm

    for attendanceTerm, data of doc.attendance
      allTermsEnrolled[attendanceTerm.match(/(2\d\d\d-term-\d)/)?[1].replace(/term-/,"T")] = attendanceTerm

    for term, enrollment of doc.enrollments
      allTermsEnrolled[term] = enrollment

    for term, data of doc["Performance and Attendance"]
      allTermsEnrolled[term] = "performance_and_attendance-school-#{data["School Code"]}-#{term.replace(/-T.*/,"")}-term-#{term.replace(/.*-T/,"")}-class-#{data["Class"]}"

    classes = [
      "Standard 5"
      "Standard 6"
      "Standard 7"
      "Standard 8"
      "Form 1"
      "Form 2"
      "Form 3"
      "Form 4"
    ]

    transitions = {}

    for index in [1..classes.length]
      startClass = classes[index-1]
      endClass = classes[index]
      startEnrollmentDescription = null
      endEnrollmentDescription = null

      for term, enrollmentDescription of allTermsEnrolled
        startEnrollmentDescription = enrollmentDescription if enrollmentDescription.indexOf(startClass) isnt -1
        endEnrollmentDescription = enrollmentDescription if enrollmentDescription.indexOf(endClass) isnt -1
        break if startEnrollmentDescription and endEnrollmentDescription

      transitions["#{startClass} -> #{endClass}"] = [startEnrollmentDescription, endEnrollmentDescription] if startEnrollmentDescription and endEnrollmentDescription

    for transition, description of transitions
      [match, year, term] = description[1].match(/(\d\d\d\d)-term-(\d)/) # use second enrollment as the year/term since this is the ending place
      transition = transition.replace(/Standard /g,'s').replace(/Form /g,'f')
      emit [year, term], transition
