#! /usr/local/bin/coffee
request = require 'request'
glob = require 'glob'
_ = require 'underscore'
CoffeeScript = require 'coffeescript'
fs = require 'fs'
PouchDB = require 'pouchdb-core'
.plugin(require('pouchdb-adapter-http'))

database_location = process.argv[2] or fs.readFileSync("credentials.txt", "utf8").replace(/\r?\n|\r/,"")

#Get all .coffee files
glob "*.coffee", (er, files) ->
  _(files).each (view) ->

    return if view.match(/__reduce/)
    return if view is "executeViews.coffee"
    return if view is "pushViews.coffee"
    return if view is "runTests.coffee"
    console.log view

    view_name = view.replace(/\.coffee/,"")
    document_id = "_design/#{view_name}"
    map = fs.readFileSync(view, 'utf8')

    local_view_doc =
      _id: document_id
      language: "javascript" # prefer javascript for cloudant compatibility
      views:
        "#{view_name}":
          map:  CoffeeScript.compile(map, {bare:true})

    reduce_file = view.replace(/\.coffee/,"__reduce.coffee")
    if fs.existsSync "./#{reduce_file}"
      console.log "***" +  reduce_file
      reduce = fs.readFileSync(view.replace(/\.coffee/,"__reduce.coffee"), 'utf8')
      local_view_doc["views"][view_name]["reduce"] = CoffeeScript.compile(reduce, {bare:true})

    # Look for something like this to specify the database
    # db:wusc-people
    match = map.match(/^.*(db|dbname):(.*)/)
    if match
      database_name = match[2]
      console.log "#{database_location}/#{database_name}"
      db = new PouchDB("#{database_location}/#{database_name}")
      db.get(document_id).then (db_view_doc) =>
        local_view_doc["_rev"] = db_view_doc["_rev"]
      .catch (error) => 
        console.error error
        console.log "Creating new view"
      .then =>
        #puts local_view_doc.to_json
        console.log "Saving view #{view} in #{database_name}"

        db.put(local_view_doc)
        .catch (error) =>
          if error.name is "compilation_error"
            console.log "Compilation error for #{view_name}, pushing as coffeescript"
            local_view_doc["views"][view_name]["map"] = map
            local_view_doc["views"][view_name]["reduce"] = reduce
            local_view_doc["language"] = "coffeescript"
            db.put(local_view_doc)
      .catch (error) -> console.error error
