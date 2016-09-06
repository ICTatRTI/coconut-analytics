(document) ->
  if document.question is "Facility" and document.DateofPositiveResults
    emit document.DateofPositiveResults, [document.MalariaCaseID, document.FacilityName, document.Shehia, document.Village, document.Age]
