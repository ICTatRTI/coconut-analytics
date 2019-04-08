_ = require 'underscore'
$ = require 'jquery'
require('jquery-ui')
Backbone = require 'backbone'
Backbone.$  = $

titleize = require "underscore.string/titleize"
slugify = require "underscore.string/slugify"

moment = require 'moment'

ExpandableObjectView = require './ExpandableObjectView'

class PersonView extends Backbone.View
  render: =>
    throw "PersonView needs a person" unless @person
    @$el.html "
      <div class='summary'/>
      <div class='expandableData'/>
    "
    expandableObject = new ExpandableObjectView(@person.doc)
    expandableObject.setElement @$(".expandableData")
    expandableObject.render()

  showSummary: =>
    @$(".summary").html "
      <style>
        .title{
          font-weight:bold;
          color: #ff4081;
          padding-right:5px;
        }
      </style>
      <table>
        <tbody>
          <tr>
            <td class='title'>Name</td>
            <td>#{@person.allNames().join(", ")}</td>
          </tr>
          <tr>
            <td class='title'>School</td>
            <td>#{@person.allSchools().join(", ")}</td>
          </tr>
          <tr>
            <td class='title'>Id</td>
            <td class='ids'/>
          </tr>
        </tbody>
      </table>

    "
    @person.allIds().then (ids) => 
      @$(".summary .ids").html ids.join(", ")

    #@$("div:contains(creation_data)").click()
    #@$("div:contains(most_recent_summary)").click()

    schoolIdSpan = $(@$("div.propertyName:contains(Transferring From School Id)")[1]).find("span span")
    if schoolIdSpan.length > 0
      schoolId = "school-#{schoolIdSpan.html().replace(/ /g,"")}"
      Coconut.schoolsDB.get(schoolId).then (school) =>
        schoolIdSpan.html("#{schoolIdSpan.html()} (#{school.Name})")


module.exports = PersonView
