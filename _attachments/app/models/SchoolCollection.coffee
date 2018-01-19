$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

_ = require 'underscore'

User = require './User'

class SchoolCollection extends Backbone.Collection
  model: School
  pouch:
    options:
      query:
        include_docs: true
        fun: "zanzibar/users"

      changes:
        include_docs: true

  parse: (response) ->
    _(response.rows).pluck("doc")

  district: (schoolId) ->
    schoolId = "school.#{schoolId}" unless schoolId.match(/^school\./)
    @get(schoolId).get("district")

module.exports = SchoolCollection
