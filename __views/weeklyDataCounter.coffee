(doc) ->
  if doc.type is "Weekly Facility Report"
    emit [doc.Zone, "All OPD < 5", doc.Year, if doc.Week.length is 1 then "0#{doc.Week}" else doc.Week], parseInt(doc["All OPD < 5"])
    emit [doc.Zone, "All OPD >= 5", doc.Year, if doc.Week.length is 1 then "0#{doc.Week}" else doc.Week], parseInt(doc["All OPD >= 5"])
