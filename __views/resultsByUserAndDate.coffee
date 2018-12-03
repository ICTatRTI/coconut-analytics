# db:zanzibar
(document) ->
 if document.collection is "result" and document.lastModifiedAt? and document.user?
    emit [document.user, document.lastModifiedAt], null
