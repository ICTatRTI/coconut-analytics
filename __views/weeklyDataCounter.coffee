(doc) ->
  if doc.type is "Weekly Facility Report"
    week = if doc.Week.length is 1 then "0#{doc.Week}" else doc.Week
    emit [doc.Year, week, doc.Zone, "All OPD < 5"], parseInt(doc["All OPD < 5"])
    emit [doc.Year, week, doc.Zone, "All OPD >= 5"], parseInt(doc["All OPD >= 5"])
    emit [doc.Year, week, doc.Zone, "Mal POS < 5"], parseInt(doc["Mal POS < 5"])
    emit [doc.Year, week, doc.Zone, "Mal NEG < 5"], parseInt(doc["Mal NEG < 5"])
    emit [doc.Year, week, doc.Zone, "Mal POS >= 5"], parseInt(doc["Mal POS >= 5"])
    emit [doc.Year, week, doc.Zone, "Mal NEG >= 5"], parseInt(doc["Mal NEG >= 5"])
