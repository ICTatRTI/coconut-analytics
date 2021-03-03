# db:zanzibar-index-individual
(doc) ->
  if doc._id[0..3] is "ind_" and doc["Household Shehia"]
    yearWeek = doc["Year Week Of Positive Results"]
    [year,week] = yearWeek.split(/-/)

    emit [doc["Household Island"],doc["Household District"],doc["Household Shehia"], year, week],  [doc["Malaria Case ID"]?.trim(), doc.Classification, doc["Head Of Household Name"]]

# db:zanzibar
#(doc) ->
#  if doc.question is "Household Members" and doc.CaseCategory
#    emit doc.DateOfPositiveResults, [doc.MalariaCaseID?.trim(), doc.CaseCategory]
