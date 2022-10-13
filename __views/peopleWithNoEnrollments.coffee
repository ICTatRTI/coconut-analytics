# db:keep-people
#

#
(doc) ->
  if doc.id[0..5] is "person"
    #unless doc.attendance? or doc.performance? or doc.enrollments?
    numberOfEnrollments = 0
    for enrollment of doc.enrollments
      numberOfEnrollments+=1

    for enrollment of doc.attendance
      numberOfEnrollments+=1

    for enrollment of doc.performance
      numberOfEnrollments+=1

    for enrollment of doc.spotchecks
      numberOfEnrollments+=1

    if numberOfEnrollments is 0
      emit numberOfEnrollments
