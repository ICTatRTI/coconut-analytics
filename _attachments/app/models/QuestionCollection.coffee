Question = require "./Question"

class QuestionCollection extends Backbone.Collection
  model: Question
  url: '/question'

module.exports = QuestionCollection