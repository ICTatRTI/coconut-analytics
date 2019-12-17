argv = require('minimist')(process.argv.slice(2));

# Make these global so that they can be used from the javascript console
PouchDB = require 'pouchdb-core'
PouchDB.plugin(require('pouchdb-upsert'))
PouchDB.plugin(require('pouchdb-adapter-http'))
PouchDB.plugin(require('pouchdb-mapreduce'))

moment = require 'moment'

global.Coconut =
  database: new PouchDB argv.database,
    ajax:
      timeout: 1000 * 60 * 10
  reportingDatabase: new PouchDB "#{argv.database}-reporting",
    ajax:
      timeout: 1000 * 60 * 10


( =>
  console.log await Coconut.reportingDatabase.info()

  Coconut.reportingDatabase.query "caseIDsByDate",
    startkey: moment().subtract(3,"years").format("YYYY-MM-DD")
    include_docs: true
  .catch (error) => console.error error
  .then (result) =>
    console.log result

    shehiaMetadata = (await Coconut.reportingDatabase.get("shehia metadata")).Shehias

    for row in result.rows
      malariaCase = row.doc
      shehiaName = malariaCase["Shehia"]
      for dateAndClassification in malariaCase["Classifications By Diagnosis Date"].split(",")
        #Active => (With ongoing transmission – reported indigenous case within this reporting calendar year)
        #Residual Active => (Transmission interrupted recently - The last indigenous case(s) was detected in the previous calendar year or up to 3 years earlier)
        #Cleared => (No indigenous case(s) for more than 3 years, could be reporting only imported or/and relapsing or or/and induced cases may occur in the recrudescent cases current calendar year.

        [date,classification] = dateAndClassification.split(": ")
        year = date[0..3]
        currentYear = moment().year()
        threeYearsAgo = currentYear-2 # e.g. if now is 2019 then we are interested in 2017,2018,2019 hence 2019-2 = 2017

        shehiaMetadata[shehiaName] or= {}
        shehiaMetadata[shehiaName]["Focus Classification"] or= "Cleared"

        if classification is "Indigenous"
          if year >= threeYearsAgo
            shehiaMetadata[shehiaName]["Focus Classification"] = "Residual Active"
          if year is currentYear
            shehiaMetadata[shehiaName]["Focus Classification"] = "Active"

    console.log shehiaMetadata

)()
