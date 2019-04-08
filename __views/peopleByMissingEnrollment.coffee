# db:keep-people
#

#
(doc) ->
  termsMissingData = {
    "2018-T1": true
    "2018-T2": true
    "2018-T3": true
  }

  isConfirmedLearner = doc._id.match(/-.+-/) is null

  region = doc.most_recent_summary?.Region
  if region
    enrollments = Object.keys(doc.attendance).concat(Object.keys(doc.performance))

    for termYear, data of doc["Performance and Attendance"]
      termsMissingData[termYear] = false

    for termYear, enrollment of doc.enrollments
      termsMissingData[termYear] = false

    for enrollment in enrollments
      enrollmentTermYear = enrollment.match(/(2\d\d\d-term-\d)/)[1]?.replace(/term-/,"T")
      termsMissingData[enrollmentTermYear] = false
  else
    emit ["noRegion", doc]

  for term, isMissingData of termsMissingData
    emit [isConfirmedLearner,region,term] if isMissingData
