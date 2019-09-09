# db:zanzibar
(document) ->
  if document.question is "Facility" and (document.DateofPositiveResults or document.DateOfPositiveResults)
    dateOfPositiveResults = document.DateofPositiveResults or document.DateOfPositiveResults
    emit dateOfPositiveResults, [document.MalariaCaseID, document.FacilityName, document.Shehia, document.Village, document.Age]
