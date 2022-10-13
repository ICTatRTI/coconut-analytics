# db:keep-people
(doc) ->
  if doc._id[0..8] is "followup_"
    if doc.usersToFollowup?
      for userId in doc.usersToFollowup
        emit userId,null
