# db:keep-enrollments
(doc) ->
  emit doc._id
  if doc._id[0..9] is "enrollment" and doc.students
    for index, student of doc.students
      emit doc._id[23..33], student
