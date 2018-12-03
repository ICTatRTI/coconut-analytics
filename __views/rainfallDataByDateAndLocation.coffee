# db:zanzibar
(doc) ->
  if doc.type? and doc.type is "rainfall_report"
    emit [doc.year,doc.week], [doc.station, parseInt(doc.rainfall_amount)]
