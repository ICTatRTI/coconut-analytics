$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

global._ = require 'underscore'

Question = require './Question'

class QuestionCollection extends Backbone.Collection
  model: Question

  fetch: (options) =>
    Coconut.database.query "questions",
      include_docs: true
    .then (result) =>
      for row in result.rows
        @add(new Question(row.doc))
      options.success()
    .catch (error) =>
      options.error(error)

module.exports = QuestionCollection
