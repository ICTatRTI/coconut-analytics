# db:zanzibar
(doc) ->
  if (doc.question == "Facility" && doc.DateofPositiveResults && doc.Age < 5)
    emit(doc.DateofPositiveResults, doc.MalariaCaseID)
  
  if (doc.question == "Household Members" && doc.MalariaTestResult == "PF" && document.Age < 5)
    emit(doc.lastModifiedAt, doc.MalariaCaseID)
