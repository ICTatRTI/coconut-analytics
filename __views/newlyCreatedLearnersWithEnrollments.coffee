# db:keep-people
(doc) ->
  if doc.most_recent_summary
    if doc._id.match(/-.+-/) # two dashes matches people-33423-2
      if doc.enrollments
        if Object.keys(doc.enrollments).length > 0
          emit [doc.most_recent_summary.Region.toUpperCase(), doc.most_recent_summary.Sex.toUpperCase()], doc.most_recent_summary
