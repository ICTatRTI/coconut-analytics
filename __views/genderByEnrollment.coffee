# db:keep-people
(doc) ->
  if doc.most_recent_summary?.Sex
    for enrollmentYearTerm, enrollment of doc.enrollments
      emit [enrollment, doc.most_recent_summary.Sex], 1
