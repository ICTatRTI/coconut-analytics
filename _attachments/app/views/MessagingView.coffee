Message = require '../models/Message'
MessageCollection = require '../models/MessageCollection'
User = require '../models/User'
UserCollection = require '../models/UserCollection'
DataTables = require( 'datatables.net' )()
humanize = require 'underscore.string/humanize'
moment = require 'moment'

class MessagingView extends Backbone.View

  initialize: ->
    @userCollection = new UserCollection()
    @messageCollection = new MessageCollection()
    @max = 140

  el: '#content'

  events:
    "click #check-all": "checkAll"
    "click .phone-number": "updateToField"
    "click input[value=Send]": "send"
    "keyup #message": "checkLength"

  checkLength: ->
    $("#charCount").html "Characters used: #{$("#message").val().length}. Maximum allowed: #{140}"
    if $("#message").val().length > @max
      $("#charCount").css("color","red")
    else
      $("#charCount").css("color","")

  send: ->
    messageText = $("#message").val()
    return false if messageText.length > @max or messageText.length is 0
    _.each @phoneNumbers, (phoneNumber) ->
      message = new Message
        date: moment(new Date()).format(Coconut.config.dateFormat)
        text: messageText
        to: phoneNumber
      message.sendSMS
        success: ->
          message.save()
          $("#messageBox").append "Sent '#{messageText}' to #{phoneNumber}"
        error: (error) ->
          $("#messageBox").append "Error: [#{error}] while sending '#{messageText}' to #{phoneNumber}"

    return false

  checkAll: =>
    $("input[type=checkbox].phone-number").prop("checked", $("#check-all").is(":checked"))
    @updateToField()

  updateToField: ->
    @phoneNumbers = _.map $("input[type=checkbox].phone-number:checked"), (item) ->
      $(item).attr("id").replace(/check-user\./,"")
    $("#to").html @phoneNumbers.join(", ")
  
  render: =>
    fields =  "_id,district,name,inactive".split(",")
    messageFields =  "date,to,text".split(",")
    @$el.html "
      <h4>Send Message</h4>
      <h5>Select Recipients</h5>
      <table class='mdl-data-table mdl-js-data-table mdl-shadow--2dp' id= 'recipients'>
        <thead>
          <th class='mdl-data-table__cell--non-numeric'><input id='check-all' type='checkbox'></input></th>
          <th class='mdl-data-table__cell--non-numeric'>Phone Number</th>
          <th class='mdl-data-table__cell--non-numeric'>District</th> 
          <th class='mdl-data-table__cell--non-numeric'>Name</th>
          <th class='mdl-data-table__cell--non-numeric'>Inactive</th>
        </thead>
        <tbody>
        </tbody>
      </table>
      <div class='m-t-30'>
        <form id='message-form'>
          Recipients selected:
          <div id='to' style='border: 1px solid; padding: 15px'></div>
          <div class='m-t-30'>
            <label style='display:block' for='message'>Message</label>
            <textarea style='width:100%' id='message' name='message'></textarea>
            <div id='messageBox'></div>
            <input type='submit' value='Send'></input>
            <span id='charCount'></span>
          </div>
        </form>
      </div>
      <div class='m-t-30'>
        <h4>Messages Sent</h4>
        <table class='sent-messages tablesorter mdl-data-table mdl-js-data-table mdl-shadow--2dp'>
          <thead>
            <th class='mdl-data-table__cell--non-numeric'>Date</th>
            <th class='mdl-data-table__cell--non-numeric'>To</th>
            <th class='mdl-data-table__cell--non-numeric'>Text Message</th>
          </thead>
          <tbody>
          </tbody>
        </table>
      </div>
    "
    
    @userCollection.fetch
      success: =>
        @userCollection.sortBy (user) ->
          user.get "district"
        .forEach (user) ->
          return unless user.get("_id").match(/\d\d\d/)
          $("#recipients tbody").append "
            <tr>
              <td class='mdl-data-table__cell--non-numeric'><input class='phone-number' id='check-#{user.get("_id")}' type='checkbox'></input></td>
              <td class='mdl-data-table__cell--non-numeric'>#{user.get('_id').replace(/user\./,'')}</td>
              <td class='mdl-data-table__cell--non-numeric'>#{user.get('district')}</td>
              <td class='mdl-data-table__cell--non-numeric'>#{user.get('name')}</td>
              <td class='mdl-data-table__cell--non-numeric'>#{User.inactiveStatus(user.get('inactive'))}</td>
            </tr>
            "
        $(".recipients tbody").append "
          <tr>
            <td><input class='phone-number' id='check-user.0787263670' type='checkbox'></input></td>
            <td class='mdl-data-table__cell--non-numeric'>0787263670</td>
            <td class='mdl-data-table__cell--non-numeric'></td>
            <td class='mdl-data-table__cell--non-numeric'>Ritha</td>
            <td class='mdl-data-table__cell--non-numeric'>RTI</td>
          </tr>
          <tr>
            <td><input class='phone-number' id='check-user.3141' type='checkbox'></input></td>
            <td class='mdl-data-table__cell--non-numeric'>31415926</td>
            <td class='mdl-data-table__cell--non-numeric'></td>
            <td class='mdl-data-table__cell--non-numeric'>Test</td>
            <td class='mdl-data-table__cell--non-numeric'>Doesn't actually work</td>
          </tr>
        "
        $("a").button()

    @messageCollection.fetch
      success: => 
        @messageCollection.forEach (item) ->
          $(".sent-messages tbody").append "
            <tr>
              <td class='mdl-data-table__cell--non-numeric'>#{item.get('date')}</td>
              <td class='mdl-data-table__cell--non-numeric'>#{item.get('to')}</td>
              <td class='mdl-data-table__cell--non-numeric'>#{item.get('text')}</td>
            </tr>
        "
        
module.exports = MessagingView