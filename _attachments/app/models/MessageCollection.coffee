Message = require './Message'

class MessageCollection extends Backbone.Collection
  model: Message
  
  pouch:
    options:
      query:
        include_docs: true
        fun: 
          map: (doc) ->
            if (doc.collection && doc.collection == 'message')
              emit(doc, null)

      changes:
        include_docs: true

  parse: (response) ->
    _(response.rows).pluck("doc")
    
module.exports = MessageCollection