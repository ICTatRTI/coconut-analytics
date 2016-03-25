$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

_ = require 'underscore'

User = require './User'

class UserCollection extends Backbone.Collection
  model: User
  pouch:
    fetch: 'query'
    options:
      query:
        include_docs: true
        fun:
          map: (doc) ->
            if (doc.collection && doc.collection == 'user')
              emit(doc.name + " - " + doc.district, null)

  parse: (response) ->
    _(response.rows).pluck("doc")

  district: (userId) ->
    userId = "user.#{userId}" unless userId.match(/^user\./)
    @get(userId).get("district")


module.exports = UserCollection
