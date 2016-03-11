$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

_ = require 'underscore'

User = require './User'

class UserCollection extends Backbone.Collection
  model: User
  pouch:
    options:
      query:
        include_docs: true
        fun: "users"

  parse: (response) ->
    _(response.rows).pluck("doc")

  district: (userId) ->
    userId = "user.#{userId}" unless userId.match(/^user\./)
    @get(userId).get("district")


module.exports = UserCollection
