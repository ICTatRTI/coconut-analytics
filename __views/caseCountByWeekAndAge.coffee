# db:zanzibar-reporting
(doc) ->
  if doc._id.lastIndexOf("case_summary_", 0) is 0 # Implements startsWith http://stackoverflow.com/a/4579228/266111

    total = doc["Number Positive Cases Including Index"]
    under5 = doc["Number Positive Cases At Index Household And Neighbor Households Under5"]
    over5 = total - under5
    emit [doc["Index Case Diagnosis Date Iso Week"], "Over 5"], over5
    emit [doc["Index Case Diagnosis Date Iso Week"], "Under 5"], under5
