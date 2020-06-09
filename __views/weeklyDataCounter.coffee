# db:zanzibar-weekly-facility
###
{
  "_id": "2020-19-UNGUJA-WEST B-MAGOGONI",
  "_rev": "1-c95f3c7c1d8791e3af659f12cab64353",
  "source": "meedsWeekly.rb",
  "type": "Weekly Facility Report",
  "Year": "2020",
  "Week": "19",
  "Submit Date": "2020-05-11 05:57:45",
  "Zone": "UNGUJA",
  "District": "WEST B",
  "Facility": "MAGOGONI",
  "All OPD < 5": "118",
  "Mal POS < 5": "0",
  "Mal NEG < 5": "14",
  "Test Rate < 5": "11.9%",
  "Pos Rate < 5": "0",
  "All OPD >= 5": "305",
  "Mal POS >= 5": "1",
  "Mal NEG >= 5": "26",
  "Test Rate >= 5": "8.9%",
  "Pos Rate >= 5": "3.7%"
}
###
(doc) ->
  if doc.type is "Weekly Facility Report"
    administrativeLevels = [
      "ZANZIBAR" # NATIONAL
      doc.Zone # ISLANDS
      null # REGIONS
      doc.District # DISTRICT
      null # SHEHIAS
      doc.Facility # HEALTH FACILITIES
      # CLINICS & WARDS
    ]
    week = if doc.Week.length is 1 then "0#{doc.Week}" else doc.Week

    for indicator in [
      "All OPD < 5"
      "All OPD >= 5"
      "Mal POS < 5"
      "Mal NEG < 5"
      "Mal POS >= 5"
      "Mal NEG >= 5"
    ]
      emit [doc.Year, week, indicator].concat(administrativeLevels), parseInt(doc[indicator])
