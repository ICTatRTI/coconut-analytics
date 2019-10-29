_ = require 'underscore'
$ = require 'jquery'
require('jquery-ui')
Backbone = require 'backbone'
Backbone.$  = $

titleize = require "underscore.string/titleize"
slugify = require "underscore.string/slugify"
cloneDeep = require "lodash/cloneDeep"

moment = require 'moment'

ExpandableObjectView = require './ExpandableObjectView'

class PersonView extends Backbone.View
  render: =>
    throw "PersonView needs a person" unless @person
    @$el.html "
      <div class='summary'/>
      <div class='linkedPeople'/>
      <div class='comments'/>
      <div class='expandableData'/>
    "
    @showSummary()
    expandableObject = new ExpandableObjectView(@person.doc)
    expandableObject.setElement @$(".expandableData")
    expandableObject.substitutions = [
      [/^(person-[a-zA-Z0-9-_ ]+)/, "<a href='#person/$1'>$1</a>"]
      [/^(enrollment-[a-zA-Z0-9- ]+)/, "<a href='#enrollment/$1'>$1</a>"]
    ]
    expandableObject.render()
    @addSchoolNames()
    @showComments()
    @showLinkedPeople()

  showComments: =>
    allComments = @person.allComments()
    console.log allComments
    if allComments.length > 0
      @$(".comments").html JSON.stringify(allComments)

  showLinkedPeople: =>
    @$(".linkedPeople").html(
      (for person in @person.linkedPeople?
        "<a href='#person/#{person.shortId()}'>#{person.shortId()}</a>"
      ).join("<br/>")
    )


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
            <td class='ids'>#{@person.allIds().join(", ")}</a>
          </tr>
        </tbody>
      </table>

    "


  addSchoolNames: =>
    schoolIdSpan = $(@$("div.propertyName:contains(Transferring From School Id)")[1]).find("span span")
    if schoolIdSpan.length > 0
      schoolId = "school-#{schoolIdSpan.html().replace(/ /g,"")}"
      Coconut.schoolsDB.get(schoolId).then (school) =>
        schoolIdSpan.html("#{schoolIdSpan.html()} (#{school.Name})")

  addLinks: =>


module.exports = PersonView
