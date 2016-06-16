request = require 'request'
glob = require 'glob'
_ = require 'underscore'

views = [
  "byCollection"
  "byValue"
  "docIDsForUpdating"
  "results"
  "resultsByQuestionAndComplete"
  "zanzibar/byValue"
  "zanzibar-server/byValue"
]

_(views).each (view) ->

  [design_doc, view_name] = view.split(/\//)
  view_name = design_doc unless design_doc?

  viewUrl = "http://cococloud.co/zanzibar/_design/#{design_doc}/_view/#{view_name}?limit=1"

  console.log "Executing view: #{viewUrl}"
  request viewUrl, (result) ->
    console.log "Finished #{viewUrl}"

