# db:zanzibar
(doc) ->
  if (doc.question == "Facility" && doc.DateofPositiveResults && doc.Age < 5)
    dateStr = doc.DateofPositiveResults.split("-");
    if (dateStr.length == 3)
       if (dateStr[0].length == 4)
          datepositive = new Date(dateStr[0],dateStr[1]-1,dateStr[2])
       else 
         if (dateStr[2].length == 4)
          datepositive = new Date(dateStr[2],dateStr[1]-1,dateStr[0])
          
    emit(datepositive)
