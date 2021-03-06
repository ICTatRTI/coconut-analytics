#! /usr/bin/env coffee
request = require 'request'
glob = require 'glob'
_ = require 'underscore'

database = process.argv.pop() || "http://localhost:5984/zanzibar"

glob "**/*.coffee", (er, files) ->
  _(files).each (view) ->

    return if view.match(/__reduce/) or view is "executeViews.coffee"

    view_name = view.replace(/\.coffee/,"")
    viewUrl = "#{database}/_design/#{view_name}/_view/#{view_name}?limit=1"

    console.log "Executing view: #{viewUrl}"
    request viewUrl, (result) ->
      console.log result
      console.log "Finished #{viewUrl}"

