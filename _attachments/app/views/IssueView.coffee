Case = require '../models/Case'
Issue = require '../models/Issue'

class IssueView extends Backbone.View
  el: '#content'

  events:
    "click button#edit" : "edit"
    "click button#save" : "save"
    "click button.caseBtnLg": "showCaseDialog"
    "click button#closeDialog": "closeDialog"

  showCaseDialog: (e) ->
    caseID = $(e.target).parent().attr('id') || $(e.target).attr('id')
    Case.showCaseDialog
      caseID: caseID
      success: ->
    return false

  closeDialog: () ->
    caseDialog.close() if caseDialog.open

  render: =>
    @$el.html "
      <style>
        label { display: inline-block; width: 140px; text-align: right; }
      </style>
      <dialog id='caseDialog'></dialog>
    "

    if @issue?
      @$el.append "
        <div style='display:hidden' id='message'></div>
        <h4><a href='javascript:history.back()' title='Prev screen'><i class='mdi mdi-arrow-left-bold-circle mdi-36px'></a></i> Issue: #{@issue.Description}</h4>
        #{
          if @issue["Threshold Description"] then "<h5>Threshold:#{@issue["Threshold Description"]}</h5>" else ""
        }

        <div id='responsibility'>
          <ul>
            #{
              if @issue["Assigned To"]?
                _(Issue.commonProperties).map (property) =>
                  return "" if property is "Description"
                  if property is "Assigned To"
                    "
                      <li id='assignedToValue'>
                        #{property}: #{Users.find({id: @issue["Assigned To"]}).nameOrUsernameWithDescription()}
                      </li>
                    "

                  else
                    "<li>#{property}: #{@issue[property]}</li>"
                .join ""
              else
                "Issue not yet assigned."
            }
          </ul>
<!--
          <button id='edit' type='button' class='mdl-button mdl-js-button mdl-button--raised mdl-button--colored'>Edit</button>
-->
        </div>

        <table id='caseTable' class='tablesorter mdl-data-table mdl-js-data-table mdl-shadow--2dp' id='thresholdTable'>
          <thead>
            #{
              _(["caseId","district","shehia","village","IndexCaseDiagnosisDate","indexCaseHasTravelHistory"]).map (header) ->
                "<th>#{header}</th>"
              .join ""
            }
          </thead>
          <tbody>
          </tbody>
        </table>
        <div><a href='javascript:history.back()' title='Prev screen'><i class='mdi mdi-arrow-left-bold-circle mdi-36px'></a></i></div>
        <ul id='links'></ul>
      "

      if @issue.Links?
        index = 0
        $("ul#links").append _(@issue.Links).map( (link) =>
            "<li><a href='#{link}'>#{@issue.Cases?[index++] or link}</li>"
        ).join("")

      if @issue.Cases?
        $("ul#links").hide()
        Case.getCases
          caseIDs: @issue.Cases
          error: (error) -> console.error error
          success: (cases) ->
            $("#caseTable tbody").append "
                #{
                _(cases).map (malariaCase) ->
                  "
                  <tr>
                  #{
                    _(["caseId","district","shehia","village","IndexCaseDiagnosisDate","indexCaseHasTravelHistory"]).map (property) ->
                      "<td>
                        #{
                          if property is "caseId"
                            "<button id= '#{malariaCase[property]()}' class='caseBtnLg btn btn-small'>#{malariaCase[property]()}</a>"
                          else
                            malariaCase[property]()
                        }
                       </td>"
                    .join ""
                  }
                  </tr>
                  "
                .join ""
                }
            "
    else
      @$el.append "<h4>Issue Not found</h4>"

  issueForm: => "
    <div>
      <label for='description'>Description</label>
      <textarea name='description'>#{@issue?.Description || ""}</textarea>
    </div>

    <div>
      <label for='assignedTo'>Assigned To</label>
      <select name='assignedTo'>
        <option></option>
        #{
          Users.map (user) =>
            userId = user.get "_id"
            "<option value='#{userId}' #{if @issue?["Assigned To"] is userId then "selected='true'" else ""}>
              #{user.nameOrUsernameWithDescription()}
             </option>"
          .join ""
        }
      </select>
    </div>

    <div>
      <label for='actionTaken'>Action Taken</label>
      <textarea name='actionTaken'>#{@issue?['Action Taken'] || ""}</textarea>
    </div>

    <div>
      <label for='solution'>Solution</label>
      <textarea name='solution'>#{@issue?['Solution'] || ""}</textarea>
    </div>

    <div>
      <label for='dateResolved'>Date Resolved</label>
      <input type='date' name='dateResolved' #{
        if @issue?['Date Resolved']
          "value = '#{@issue['Date Resolved']}'"
        else ""
      }
    </div>
    <div>
      <button id='save'>Save</button>
    </div>
    </input>
  "

  edit : =>
    $("#responsibility").html @issueForm()

  save: =>
    description = $("[name=description]").val()
    if description is ""
      $("#message").html("Issue must have a description to be saved")
      .show()
      .fadeOut(10)
      return

    if not @issue?
      dateCreated = moment().format("YYYY-MM-DD HH:mm:ss")

      @issue = {
        _id: "issue-#{dateCreated}-#{description.substr(0,10)}"
        "Date Created": dateCreated
      }

    @issue["Updated At"] = [] unless @issue["Updated At"]
    @issue["Updated At"].push moment().format("YYYY-MM-DD HH:mm:ss")
    @issue.Description = description
    @issue["Assigned To"] = $("[name=assignedTo]").val()
    @issue["Action Taken"] = $("[name=actionTaken]").val()
    @issue.Solution = $("[name=solution]").val()
    @issue["Date Resolved"] = $("[name=dateResolved]").val()

    Coconut.database.saveDoc @issue,
      error: (error) ->
        $("#message").html("Error saving issue: #{JSON.stringify error}")
        .show()
        .fadeOut(10000)
      success: =>
        Coconut.router.navigate "#show/issue/#{@issue._id}"
        @render()
        $("#message").html("Issue saved")
        .show()
        .fadeOut(2000)

module.exports = IssueView
