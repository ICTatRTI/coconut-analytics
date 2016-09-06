$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

global._ = require 'underscore'

Question = require './Question'

class QuestionCollection extends Backbone.Collection
  model: Question
  pouch:
    options:
      query:
        include_docs: true
        fun: "questions/questions"

      changes:
        include_docs: true

  parse: (response) ->
    _(response.rows).map (question) ->
      question.doc

module.exports = QuestionCollection
