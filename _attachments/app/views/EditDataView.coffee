humanize = require "underscore.string/humanize"

class EditDataView extends Backbone.View
  el: '#content'

  render: =>
    console.log(humanize(@document._id))
    @$el.html "
      <h3>Manage: #{humanize(@document._id)}</h3>

      Select the year and month for the data that will be entered. Then list she relevant shehias, with one on each line (pasting from a spreadsheet should work fine).

      <div>
        Year and month:
        <input type='month' id='month'></input>
        <textarea style='width:100%; height:400px' id='data'></textarea>
        <button type='button' id='save'>Save</button>
      </div>


      <div id='message'></div>
    "

  events:
    "click #save": "save"
    "change #month": "updateMonth"

  updateMonth: ->
    $("#data").html @document[$('#month').val()]?.join("\n")

  save: ->
    $("#message").html ""
    data = _.compact $("#data").val().split("\n")
    allShehiasValid = true
    _(data).each (shehia) ->
      if GeoHierarchy.findShehia(shehia).length is 0
        allShehiasValid = false
        $("#message").append "#{shehia} is not a valid shehia<br/>"
    if allShehiasValid
      @document[$('#month').val()] = data
      Coconut.database.put @document
      .catch(error) ->
          $("#message").append "Error while saving data: #{JSON.stringify error}"
      .then() ->
          $("#message").append "Shehia list is valid, data saved"
    else
      alert "Shehia list is not valid, must resolve before saving."

    
module.exports = EditDataView