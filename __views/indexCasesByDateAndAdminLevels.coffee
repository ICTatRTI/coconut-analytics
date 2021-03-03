# db:zanzibar-reporting
(doc) ->
  if doc._id[0..12] is "case_summary_"
    if doc["Index Case Diagnosis Date ISO Week"] and doc["Names Of Administrative Levels"]
      adminLevels = doc["Names Of Administrative Levels"].split(",")
      return unless adminLevels.length is 6
      adminLevels.shift()
      emit([doc["Index Case Diagnosis Date ISO Week"]].concat(adminLevels), null)

