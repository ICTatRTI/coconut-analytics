# db:zanzibar
(doc) ->

  id = if doc.MalariaCaseID
    doc.MalariaCaseID
  else if doc.caseid
    doc.caseid

  if id
    id = id.trim()
    if id.length > 3
      emit id
