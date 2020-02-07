Backbone = require 'backbone'
Backbone.$  = $
global.copy = require('copy-text-to-clipboard');

Tabulator = require 'tabulator-tables'

class SetsView extends Backbone.View

  events:
    "click .remove": "removeSet"
    "change .merge-with": "mergeWith"
    "click #close": "close"

  close: =>
    setsDialog.close()

  removeSet: (event) =>
    delete @sets[$(event.target).attr('data-setName')]
    @render()

  mergeWith: (event) =>
    sourceSet = $(event.target).attr('data-setName')
    targetSet = $(event.target).find("option:selected").text()
    @sets["#{sourceSet} + #{targetSet}"] = _(@sets[sourceSet].concat(@sets[targetSet])).unique()
    delete @sets[sourceSet]
    delete @sets[targetSet]
    @render()

  render: (highlightSet = null) =>
    @sets or= {}
    @$el.html "
      <style>
        td,th{
          vertical-align:top;
          border: solid 1px;
        }
        select{
          width: 100px;
        }
        #close{
          float:right;
        }
        dialog{
          width: 80%;
        }
      </style>
      <button id='close'>close</button>
      <small>This window shows the list of individual cases for each aggregate number. You can add more more sets of cases to this window by closing it and clicking another set to compare it with.</small>
      <table>
        <thead>
          <tr>
          #{
            (for setName, setList of @sets
              "
              <th>
                #{setName} <br/>
                <small>
                  <button onClick='copy(\"#{setList.join("\\n")}\");return false;' class='copy' data-setname='#{setName}'>copy</button>
                  <button class='remove' data-setName='#{setName}'>remove</button>
                  #{
                    if _(@sets).size() > 1
                      "
                      Merge with:
                      <select class='merge-with' data-setName='#{setName}'>
                        <option></option>
                        #{
                          (for name of @sets
                            continue if name is setName
                            "<option>#{name}</option>"
                          )
                        }
                      </select>
                      "
                    else ""
                  }
                </small>
              </th>
              "
            ).join("")
          }
          #{
            if _(@sets).size() > 1
              "
              <th>Items In All Sets</th>
              <th>Items In One Set</th>
              "
            else ""
          }
          <tr/>
        </thead>
        <tbody>
          <tr>
          #{
            itemHash = {}
            (for setName, setList of @sets
              "<td #{if setName is highlightSet then "class='highlight'" else ""}>
              #{
                (for setItem in setList
                  itemHash[setItem] or= []
                  itemHash[setItem].push setName
                  @caseLink(setItem)
                ).join("")
              }
              </td>"
            ).join("")
          }
          #{
            if _(@sets).size() > 1
              "
                <td>
                #{
                  (for setItem, setNames of itemHash
                    if setNames.length is _(@sets).size()
                      @caseLink(setItem)
                  ).join("")
                }
                </td>
                <td>
                #{
                  (for setItem, setNames of itemHash
                    if setNames.length is 1
                      @caseLink(setItem)
                  ).join("")
                }
                </td>
              "
            else ""
          }
          </tr>
        </tbody>
      </table>
    "

    if _(@sets).size() > 1
      @$(".highlight").css("background-color", "yellow")
      _.delay =>
        @$(".highlight").css("background-color", "#fdfd96")
      ,500
      _.delay =>
        @$(".highlight").css("background-color", "")
      ,1000

  caseLink: (caseId) =>
    "<div><a href='#show/case/#{caseId}'>#{caseId}</div>"

SetsView.showDialog =  (set) =>
  unless setsDialog?
    $("body").append "
      <dialog id='setsDialog'></dialog>
    "
  global.setsView or= new SetsView()
  setsView.sets or= {}
  setsView.sets[set.name] = set.cases
  setsView.setElement($("#setsDialog"))
  setsView.render(set.name)
  if (Env.is_chrome)
     setsDialog.showModal() if !setsDialog.open
  else
     setsDialog.show() if !setsDialog.open
  options?.success()

module.exports = SetsView
