# db:zanzibar
(document) ->
  if document.question is "Facility" and (document.DateofPositiveResults or document.DateOfPositiveResults or document.DateAndTimeOfPositiveResults)
    dateOfPositiveResults = document.DateofPositiveResults or document.DateOfPositiveResults or document.DateAndTimeOfPositiveResults[0..9]
    emit dateOfPositiveResults, [document.MalariaCaseID, document.FacilityName, document.Shehia, document.Village, document.Age]
