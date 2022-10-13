class Followup

Followup.createFollowupDocNoSave = (options) ->
  doc = {}

  doc._id = "followup_#{options.person.longId()}_"
  doc.relevantPeople = [options.person.longId()]

  if options.relevantPeople
    for person in options.relevantPeople
      doc._id += "#{person.longId()}_"
      doc.relevantPeople.push person.longId()

  doc._id += "#{moment().format("YYYY-MM-DD:HH:mm:ss.SSSS")}"
  doc.usersToFollowup = options.usersToFollowup
  doc.date = options.date or moment().format("YYYY-MM-DD")
  doc.comments = options.comments
  doc.followedUpComplete = options.followedUpComplete or false
  doc

Followup.createFollowupDocNoSaveFindResponsibleUser = (options) ->
  doc = Followup.createFollowupDocNoSave(options)
  doc.usersToFollowup = [await options.person.responsibleUser()]
  doc

Followup.createFollowupDocAndSave = (options) ->
  Coconut.peopleDB.put Followup.createFollowupDocNoSave(options)

module.exports=Followup
