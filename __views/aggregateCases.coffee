(doc) ->
  if doc.id.match(/spreadsheet_row/) and doc.Facility
    emit(doc.Facility.split(/,/)[6].split(/-/),null)
