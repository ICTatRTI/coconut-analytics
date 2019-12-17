argv = require('minimist')(process.argv.slice(2));

PouchDB = require 'pouchdb-core'
PouchDB.plugin(require('pouchdb-upsert'))
PouchDB.plugin(require('pouchdb-adapter-http'))
PouchDB.plugin(require('pouchdb-mapreduce'))

moment = require 'moment'

Coconut =
  reportingDatabase: new PouchDB "#{argv.database}-reporting",
    ajax:
      timeout: 1000 * 60 * 10


updateShehiaMetadata = (shehiaName, date, classification,shehiaMetadata) =>
  #Active => (With ongoing transmission – reported indigenous case within this reporting calendar year)
  #Residual Active => (Transmission interrupted recently - The last indigenous case(s) was detected in the previous calendar year or up to 3 years earlier)
  #Cleared => (No indigenous case(s) for more than 3 years, could be reporting only imported or/and relapsing or or/and induced cases may occur in the recrudescent cases current calendar year.
  # For determining whether a case was indigenous or not we use the case classification when we have it, otherwise we assume that the case was indigenous.
  # Please note: THE YEAR IS CONSIDERED CALENDAR YEAR NOT PREVIOUS 12 MONTHS.

  year = date.trim()[0..3]
  currentYear = "#{moment().year()}"
  threeYearsAgo = currentYear-2 # e.g. if now is 2019 then we are interested in 2017,2018,2019 hence 2019-2 = 2017

  console.log "#{year}: #{currentYear}: #{classification}"

  shehiaMetadata[shehiaName] or= {}
  shehiaMetadata[shehiaName]["Focus Classification"] or= "Cleared"

  if classification is "Indigenous"
    if year >= threeYearsAgo
      shehiaMetadata[shehiaName]["Focus Classification"] = "Residual Active"
    if year is currentYear
      shehiaMetadata[shehiaName]["Focus Classification"] = "Active"
      console.log "ACTIVE"

updateAllCases = =>

  #TODO initialize the shehia list to Cleared based on GeoHierarchy, otherwise if a shehia has no cases it won't have an entry

  Coconut.reportingDatabase.query "caseIDsByDate",
    startkey: moment().subtract(3,"years").format("YYYY-MM-DD")
    include_docs: true
  .catch (error) => console.error error
  .then (result) =>
    console.log "DONE"

    shehiaMetadata = (await Coconut.reportingDatabase.get("shehia metadata")).Shehias

    for row in result.rows
      malariaCase = row.doc
      shehiaName = malariaCase["Shehia"]

      if malariaCase["Classifications By Diagnosis Date"] isnt ""

        for dateAndClassification in malariaCase["Classifications By Diagnosis Date"].split(",")

          [date,classification] = dateAndClassification.split(": ")
          updateShehiaMetadata(shehiaName,date,classification,shehiaMetadata)
      else
        updateShehiaMetadata(shehiaName,malariaCase["Index Case Diagnosis Date"],"Indigenous",shehiaMetadata)

    Coconut.reportingDatabase.upsert "shehia metadata", (doc) =>
      doc.Shehias = shehiaMetadata
      doc

updateAllCases()
