SES = require 'node-ses'

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
