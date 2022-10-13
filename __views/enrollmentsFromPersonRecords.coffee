# db:keep-people
(doc) ->
  emit doc._id
  if doc._id[0..5] is  "person" and doc.enrollments
    for yearTerm, enrollment of doc.enrollments
      emit yearTerm, enrollment
