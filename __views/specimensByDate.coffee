# db:entomology_surveillance
(doc) ->
  if doc._id.lastIndexOf("result-adult_mosquitoes", 0) is 0
    sharedData = {}
    docsToEmit = {}
    for property,value of doc
      if match = property.match(/Mosquito Specimen\[(\d+)\]/)
        specimenNumber = parseInt(match[1])
        property = property.replace(/.*\]\./,"")
        docsToEmit[specimenNumber] or= {}
        docsToEmit[specimenNumber][property] = value
      else
        sharedData[property] = value

    for index, docToEmit of docsToEmit
      #Object.assign(docToEmit, sharedData)
      for property,value of sharedData
        docToEmit[property] = value
      delete docToEmit["_id"]
      delete docToEmit["_rev"]
      emit doc["date-of-collection"], docToEmit

