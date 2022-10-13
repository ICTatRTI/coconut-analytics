# db:keep
(doc) ->
  if doc._id[0..16] is "schools-for-user."
    username = doc._id[17..]
    for school in doc.schools
      if school[0..5] is "school"
        emit school, username
