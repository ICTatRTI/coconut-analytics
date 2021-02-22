# db:zanzibar-index-individual
(doc) ->
  if doc._id[0..3] is "ind_"
    emit doc["Date Of Malaria Results"], [doc["Malaria Case ID"]?.trim(), doc.Classification]

# db:zanzibar
#(doc) ->
#  if doc.question is "Household Members" and doc.CaseCategory
#    emit doc.DateOfPositiveResults, [doc.MalariaCaseID?.trim(), doc.CaseCategory]
