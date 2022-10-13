SES = require 'node-ses'
DEBUG = 'node-ses'
$ = require 'jquery'

Backbone = require 'backbone'
Backbone.$  = $

class SendEmailView extends Backbone.View
  el: "#content"

  events:
    "click #send": "send"

  send: =>

    client = SES.createClient
      key: "AKIATJQ2GNPY7YXSKVTX"
      secret: "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"

    client.sendEmail({
       to: 'mikeymckay@gmail.com'
       from: 'mikeymckay@gmail.com'
       subject: 'greetings'
       message: 'telephone?'
       altText: 'plain text'
    },  (err, data, res) =>
      console.log res
    )


  render: =>
    @$el.html "
      <button id='send'>Send</button>
    "

module.exports = SendEmailView
