PersonView = require './PersonView'
Tabulator = require 'tabulator-tables'
SlimSelect = require 'slim-select'

class NewLearnerView extends Backbone.View

  render: =>
    Person.get(@personId).then (@person) =>
      firstTermEnrolled = @person.firstTermEnrolled()
      @$el.html "
        <style>
          .side-by-side{
            display:inline-block;
            vertical-align:top;
            margin-right: 20px;
          }
          #{@style()}
        </style>
        <div id='peopleDetails'>
          <div class='side-by-side' id='targetPerson'></div>
          <div class='side-by-side' id='potentialPerson'></div>
        </div>
        <hr/>
        <div id='actions'>
          <div class='side-by-side' style='width:40%;' id='followupActions'></div>
          <div class='side-by-side' style='width:40%;' id='linkActions'></div>
        </div>
        <div style='margin-top:10px' id='searchArea'>
          <button id='automatedSearchButton'>Automated Search</button> 
          <button id='manualSearchButton'>Manual Search</button>
          <div id='searchResults'/>
        </div>
      "

      personView = new PersonView()
      personView.person = @person
      personView.setElement $("#targetPerson")
      personView.render()
      personView.showSummary()

      @automatedSearch()

  automatedSearch: =>
    @$("#searchResults").html "
      Automated search in progress...
    "
    @person.findPotentialDuplicatePeople()
    .catch (error) => console.error error
    .then (results) =>
      @$("#searchResults").html "
        (Automated search uses school data, sex and name information. Brighter yellow means a stronger match.)<br/>
        <ul style='width:50%'>
          #{
            (for result in results
              "
              <li id='#{result.item.id}' class='searchResult' style='background-color:RGBA(240,255,0,#{1-(result.score)}'>
                #{result.item.value.Name}
              </li>
              "
            ).join("")
          }
        </ul>
      "

  manualSearch: =>
    @$("#searchResults").html "
      Manual search in progress...
    "
    Coconut.peopleDB.query "peopleByRegionAndGender",
      include_docs: false
      reduce:false
      startkey: [@person.region().toUpperCase()]
      endkey: [@person.region().toUpperCase(),{}]
    .then (result) =>
      tableData = _(result.rows).chain().map (row) =>
        return if row.id.match(/-.+-/) # only get confirmed people
        row.value.id = row.id
        row.value
      .compact().value()

      @table = new Tabulator "#searchResults",
        height:600
        data: tableData
        layout:"fitColumns"
        columns: [
          {title: "Name", field: "Name", headerFilter: true}
          {title: "ID", field: "id"}
          #{title: "Region", field: "Region", headerFilter: true},
          {title: "School Name", field: "School Name", headerFilter: true}
          {title: "School Class", field: "School Class", headerFilter: true}
          {title: "Sex", field: "Sex", headerFilter: "select", headerFilterParams:{"Male":"Male", "Female":"Female", "":""}, headerFilterFunc: "="},
        ]

        rowClick: (e, row) =>
          @showPotentialMatchDetailsForPerson(row.getData().id)

  events: =>
    "click #delete": "delete"
    "click .filter": "filter"
    "click .searchResult": "showPotentialMatchDetails"
    "click button#link": "link"
    "click button#followup-action": "createFollowupAction"
    "click #automatedSearchButton": "automatedSearch"
    "click #manualSearchButton": "manualSearch"

  showPotentialMatchDetails: (event) =>
    @showPotentialMatchDetailsForPerson(@$(event.target).attr("id"))

  showPotentialMatchDetailsForPerson: (personId) =>
    Person.get(personId).then (@selectedPerson) =>
      personView = new PersonView()
      personView.person = @selectedPerson
      personView.setElement $("#potentialPerson")
      personView.render()
      personView.showSummary()

      Coconut.database.allDocs
        startkey: "user.",
        endkey: "user.\ufff0"
        include_docs: true
      .then (result) =>

        @$("#followupActions").html "
          If more information is needed for this link, then a followup action may be requested here.
          Responsible people:<br/>
          <select id='responsible-people' multiple>
            #{
              (for row in result.rows
                "<option value='#{row.doc._id}'>#{row.doc.name}</option>"
              ).join("")
            }
          </select>
          Comments:<br/>
          <textarea id='followupComments'></textarea><br/>
          <button id='followup-action'>
            Request Followup
          </button>
        "
        @peopleSelector = new SlimSelect 
          select: "#responsible-people"
          allowDeselect: true,
          deselectLabel: '<span class="red">✖</span>'

      @$("#linkActions").html "
        To create a link between #{@selectedPerson.shortId()} with #{@person.shortId()} you may enter comments and then click the link button:<br/>
        Comments:<br/>
        <textarea id='linkComments'></textarea><br/>
        <button id='link'>
          Link #{@selectedPerson.shortId()} with #{@person.shortId()}
        </button>
      "

  link: =>
    if confirm "Are you sure you want to link #{@selectedPerson.shortId()} and #{@person.shortId()}?"
      Coconut.peopleDB.put
        _id: "link_#{@person.longId()}_#{@selectedPerson.longId()}_#{moment().format("YYYY-MM-DD:HH:mm:ss")}"
        link: [
          @person.longId()
          @selectedPerson.longId()
        ]
        "created-by": Coconut.currentUser.id
        date: moment().format("YYYY-MM-DD")
        comments: @$("#linkComments").val()

  # create followup action document
  createFollowupAction: =>
    Coconut.peopleDB.put
      _id: "followup_#{@person.doc._id}_#{@selectedPerson._id}_#{moment().format("YYYY-MM-DD:HH:mm:ss")}"
      peopleToFollowup: @peopleSelector.selected()
      "relevant-learners": [
        @selectedPerson._id
        @person.doc._id
      ]
      date: moment().format("YYYY-MM-DD")
      comments: @$("#followupComments").val()
      followedUpComplete: false

  filter: (event) =>
    clickTarget = $(event.target)
    target = clickTarget.attr("data-target")
    value = clickTarget.attr("data-value")
    @table.setHeaderFilterValue(target, value)

  style: => "
.ss-main {
  position: relative;
  display: inline-block;
  user-select: none;
  color: #666666;
  width: 100%; }
  .ss-main .ss-single-selected {
    display: flex;
    cursor: pointer;
    width: 100%;
    height: 30px;
    padding: 6px;
    border: 1px solid #dcdee2;
    border-radius: 4px;
    background-color: #ffffff;
    outline: 0;
    box-sizing: border-box;
    transition: background-color .3s; }
    .ss-main .ss-single-selected.ss-disabled {
      background-color: #dcdee2;
      cursor: not-allowed; }
    .ss-main .ss-single-selected.ss-open-above {
      border-top-left-radius: 0px;
      border-top-right-radius: 0px; }
    .ss-main .ss-single-selected.ss-open-below {
      border-bottom-left-radius: 0px;
      border-bottom-right-radius: 0px; }
    .ss-main .ss-single-selected .placeholder {
      display: flex;
      flex: 1 1 100%;
      align-items: center;
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
      text-align: left;
      width: calc(100% - 30px);
      line-height: 1em;
      -webkit-user-select: none;
      -moz-user-select: none;
      -ms-user-select: none;
      user-select: none; }
      .ss-main .ss-single-selected .placeholder * {
        display: flex;
        align-items: center;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
        width: auto; }
      .ss-main .ss-single-selected .placeholder .ss-disabled {
        cursor: pointer;
        color: #8a8a8a; }
    .ss-main .ss-single-selected .ss-deselect {
      display: flex;
      align-items: center;
      justify-content: flex-end;
      flex: 0 1 auto;
      margin: 0 6px 0 6px;
      font-weight: bold; }
      .ss-main .ss-single-selected .ss-deselect.ss-hide {
        display: none; }
    .ss-main .ss-single-selected .ss-arrow {
      display: flex;
      align-items: center;
      justify-content: flex-end;
      flex: 0 1 auto;
      margin: 0 6px 0 6px; }
      .ss-main .ss-single-selected .ss-arrow span {
        border: solid #666666;
        border-width: 0 2px 2px 0;
        display: inline-block;
        padding: 3px;
        transition: transform .2s, margin .2s; }
        .ss-main .ss-single-selected .ss-arrow span.arrow-up {
          transform: rotate(-135deg);
          margin: 3px 0 0 0; }
        .ss-main .ss-single-selected .ss-arrow span.arrow-down {
          transform: rotate(45deg);
          margin: -3px 0 0 0; }
  .ss-main .ss-multi-selected {
    display: flex;
    flex-direction: row;
    cursor: pointer;
    min-height: 30px;
    width: 100%;
    padding: 0 0 0 3px;
    border: 1px solid #dcdee2;
    border-radius: 4px;
    background-color: #ffffff;
    outline: 0;
    box-sizing: border-box;
    transition: background-color .3s; }
    .ss-main .ss-multi-selected.ss-disabled {
      background-color: #dcdee2;
      cursor: not-allowed; }
      .ss-main .ss-multi-selected.ss-disabled .ss-values .ss-disabled {
        color: #666666; }
      .ss-main .ss-multi-selected.ss-disabled .ss-values .ss-value .ss-value-delete {
        cursor: not-allowed; }
    .ss-main .ss-multi-selected.ss-open-above {
      border-top-left-radius: 0px;
      border-top-right-radius: 0px; }
    .ss-main .ss-multi-selected.ss-open-below {
      border-bottom-left-radius: 0px;
      border-bottom-right-radius: 0px; }
    .ss-main .ss-multi-selected .ss-values {
      display: flex;
      flex-wrap: wrap;
      justify-content: flex-start;
      flex: 1 1 100%;
      width: calc(100% - 30px); }
      .ss-main .ss-multi-selected .ss-values .ss-disabled {
        display: flex;
        padding: 4px 5px;
        margin: 2px 0px;
        line-height: 1em;
        align-items: center;
        width: 100%;
        color: #8a8a8a;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap; }

@keyframes scaleIn {
  0% {
    transform: scale(0);
    opacity: 0; }
  100% {
    transform: scale(1);
    opacity: 1; } }

@keyframes scaleOut {
  0% {
    transform: scale(1);
    opacity: 1; }
  100% {
    transform: scale(0);
    opacity: 0; } }
      .ss-main .ss-multi-selected .ss-values .ss-value {
        display: flex;
        user-select: none;
        align-items: center;
        font-size: 12px;
        padding: 3px 5px;
        margin: 3px 5px 3px 0px;
        color: #ffffff;
        background-color: #5897fb;
        border-radius: 4px;
        animation-name: scaleIn;
        animation-duration: .2s;
        animation-timing-function: ease-out;
        animation-fill-mode: both; }
        .ss-main .ss-multi-selected .ss-values .ss-value.ss-out {
          animation-name: scaleOut;
          animation-duration: .2s;
          animation-timing-function: ease-out; }
        .ss-main .ss-multi-selected .ss-values .ss-value .ss-value-delete {
          margin: 0 0 0 5px;
          cursor: pointer; }
    .ss-main .ss-multi-selected .ss-add {
      display: flex;
      flex: 0 1 3px;
      margin: 9px 12px 0 5px; }
      .ss-main .ss-multi-selected .ss-add .ss-plus {
        display: flex;
        justify-content: center;
        align-items: center;
        background: #666666;
        position: relative;
        height: 10px;
        width: 2px;
        transition: transform .2s; }
        .ss-main .ss-multi-selected .ss-add .ss-plus:after {
          background: #666666;
          content: '';
          position: absolute;
          height: 2px;
          width: 10px;
          left: -4px;
          top: 4px; }
        .ss-main .ss-multi-selected .ss-add .ss-plus.ss-cross {
          transform: rotate(45deg); }
  .ss-main .ss-content {
    position: absolute;
    width: 100%;
    margin: -1px 0 0 0;
    box-sizing: border-box;
    border: solid 1px #dcdee2;
    z-index: 1010;
    background-color: #ffffff;
    transform-origin: center top;
    transition: transform .2s, opacity .2s;
    opacity: 0;
    transform: scaleY(0); }
    .ss-main .ss-content.ss-open {
      display: block;
      opacity: 1;
      transform: scaleY(1); }
    .ss-main .ss-content .ss-search {
      display: flex;
      flex-direction: row;
      padding: 8px 8px 6px 8px; }
      .ss-main .ss-content .ss-search.ss-hide {
        height: 0px;
        opacity: 0;
        padding: 0px 0px 0px 0px;
        margin: 0px 0px 0px 0px; }
        .ss-main .ss-content .ss-search.ss-hide input {
          height: 0px;
          opacity: 0;
          padding: 0px 0px 0px 0px;
          margin: 0px 0px 0px 0px; }
      .ss-main .ss-content .ss-search input {
        display: inline-flex;
        font-size: inherit;
        line-height: inherit;
        flex: 1 1 auto;
        width: 100%;
        min-width: 0px;
        height: 30px;
        padding: 6px 8px;
        margin: 0;
        border: 1px solid #dcdee2;
        border-radius: 4px;
        background-color: #ffffff;
        outline: 0;
        text-align: left;
        box-sizing: border-box;
        -webkit-box-sizing: border-box;
        -webkit-appearance: textfield; }
        .ss-main .ss-content .ss-search input::placeholder {
          color: #bdbdbd;
          vertical-align: middle; }
        .ss-main .ss-content .ss-search input:focus {
          box-shadow: 0 0 5px #5897fb; }
      .ss-main .ss-content .ss-search .ss-addable {
        display: inline-flex;
        justify-content: center;
        align-items: center;
        cursor: pointer;
        font-size: 22px;
        font-weight: bold;
        flex: 0 0 30px;
        height: 30px;
        margin: 0 0 0 8px;
        border: 1px solid #dcdee2;
        border-radius: 4px;
        box-sizing: border-box; }
    .ss-main .ss-content .ss-addable {
      padding-top: 0px; }
    .ss-main .ss-content .ss-list {
      max-height: 200px;
      overflow-x: hidden;
      overflow-y: auto;
      text-align: left; }
      .ss-main .ss-content .ss-list .ss-optgroup .ss-optgroup-label {
        padding: 6px 10px 6px 10px;
        font-weight: bold; }
      .ss-main .ss-content .ss-list .ss-optgroup .ss-option {
        padding: 6px 6px 6px 25px; }
      .ss-main .ss-content .ss-list .ss-optgroup-label-selectable {
        cursor: pointer; }
        .ss-main .ss-content .ss-list .ss-optgroup-label-selectable:hover {
          color: #ffffff;
          background-color: #5897fb; }
      .ss-main .ss-content .ss-list .ss-option {
        padding: 6px 10px 6px 10px;
        cursor: pointer;
        user-select: none; }
        .ss-main .ss-content .ss-list .ss-option * {
          display: inline-block; }
        .ss-main .ss-content .ss-list .ss-option:hover, .ss-main .ss-content .ss-list .ss-option.ss-highlighted {
          color: #ffffff;
          background-color: #5897fb; }
        .ss-main .ss-content .ss-list .ss-option.ss-disabled {
          cursor: default;
          color: #bdbdbd;
          background-color: #ffffff; }
        .ss-main .ss-content .ss-list .ss-option.ss-hide {
          display: none; }
        .ss-main .ss-content .ss-list .ss-option .ss-search-highlight {
          background-color: #fff70062; }
"




  #delete: =>
  #  if confirm "Are you sure want to delete #{JSON.stringify @person.doc.most_recent_summary}?"
  #    Coconut.peopleDB.remove(@person.doc).then =>
  #      Coconut.router.navigate "#new_learners", {trigger:true}


module.exports = NewLearnerView
