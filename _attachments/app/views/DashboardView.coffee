$ = require 'jquery'

Backbone = require 'backbone'
Backbone.$  = $

class DashboardView extends Backbone.View
  initialize: =>
    @kakuma_boys = 0
    @kakuma_girls = 0
    @kakuma_students = 0
    @kakuma_schools = 200
    @dadaab_boys = 0
    @dadaab_girls = 0
    @dadaab_students = 0
    @dadaab_schools = 333
  #events:
    #"click button#btnSubmit": "ResetPassword"

  render: =>
    Coconut.peopleDb.query "peopleByRegionAndGender",
      reduce: true
      include_docs: false
      group: true
      group_level: 2
    .then (result) =>
      Coconut.stats = result.rows
      _.map(Coconut.stats,(stat) =>
        if stat.key[0] is 'KAKUMA' and stat.key[1] is "MALE"
          @kakuma_boys = stat.value
        if stat.key[0] is 'KAKUMA' and stat.key[1] is "FEMALE"
          @kakuma_girls = stat.value
        if stat.key[0] is 'DADAAB' and stat.key[1] is "MALE"
          @dadaab_boys = stat.value
        if stat.key[0] is 'DADAAB' and stat.key[1] is "FEMALE"
          @dadaab_girls = stat.value
        @kakuma_students = @kakuma_boys + @kakuma_girls
        @dadaab_students = @dadaab_boys + @dadaab_girls
      )

      @$el.html "
        <style>
          .mdl-button--fab.mdl-button--mini-fab {
             height: 35px;
             min-width: 35px;
             width: 35px;
           }
           .stats-card-wide {
             min-height: 176px;
             width: 100%;
             background: linear-gradient(to bottom, #fff 0%, #a7d0f1 100%);
             padding: 20px;
             margin-bottom: 10px;
           }
           .stats-card-wide.totals {
             background: linear-gradient(to bottom, #fff 0%, #dcdcdc 100%);
             min-height: 150px;
             padding: 10px;
           }
           .stats-card-wide.region {
             padding: 10px;
           }
           .demo-card-wide > .mdl-card__title {
              color: #fff;
              height: 176px;
            }
            .mdl-card__supporting-text {
              width: 100%;
              background-color: #fff;
              padding: 0px;
             }

             table td {padding: 0 10px;}
             .orange {color: orange}
        </style>
        <div class='scroll-div'>
          <div class='stats-card-wide mdl-card mdl-shadow--2dp totals'>
            <div class='mdl-card__title'>
              <h4 class='mdl-card__title-text'>Stats Totals</h4>
            </div>
            <div class='mdl-card__supporting-text'>
              <table style='height: 70px'>
                <tr>
                  <td><i class='mdi mdi-human-male-female mdi-18px'></i> Students: <span class='orange'>#{@kakuma_students + @dadaab_students}</span></td>
                  <td><i class='mdi mdi-human-female mdi-18px'></i> Girls: <span class='orange'>#{@kakuma_girls + @dadaab_girls}</span></td>
                  <td><i class='mdi mdi-human-male mdi-18px'></i> Boys: <span class='orange'>#{@kakuma_boys + @dadaab_boys}</span></td>
                  <td><i class='mdi mdi-school mdi-18px'></i> Schools: <span class='orange'>#{@kakuma_schools + @dadaab_schools}</span></td>
                </tr>
                <tr>
                  <td><i class='mdi mdi-clipboard-check mdi-18px'></i> Spot checks last month: <span class='orange'>134</span></td>
                  <td><i class='mdi mdi-clipboard-check mdi-18px'></i> Spot checks last 7 days: <span class='orange'>55</span></td>
                  <td><i class='mdi mdi-clipboard-check mdi-18px'></i> Spot checks last 24 hours: <span class='orange'>15</span></td>
                  <td><i class='mdi mdi-human-greeting mdi-18px'></i> Students requiring followup: <span class='orange'>245</span></td>
                </tr>
              </table>
             </div>
          </div>
          <div class='content-grid mdl-grid'>
            <div class='mdl-cell mdl-cell--4-col' style='margin-bottom: 10px;'>
              <div class='stats-card-wide mdl-card mdl-shadow--2dp region'>
                <div class='mdl-card__title'>
                  <h4 class='mdl-card__title-text'>Kakuma</h4>
                </div>
                <div class='mdl-card__supporting-text'>
                  <table class='mdl-data-table mdl-js-data-table mdl-shadow--2dp'>
                   <tr>
                     <td><i class='mdi mdi-human-male-female mdi-18px'></i> Students:</td>
                     <td>#{@kakuma_students}</td>
                   </tr>
                   <tr>
                     <td><i class='mdi mdi-human-female mdi-18px'></i> Girls:</td>
                     <td>#{@kakuma_girls}</td>
                   </tr>
                   <tr>
                     <td><i class='mdi mdi-human-male mdi-18px'></i> Boys:</td>
                     <td>#{@kakuma_boys}</td>
                   </tr>
                   <tr>
                     <td><i class='mdi mdi-school mdi-18px'></i> Schools:</td>
                     <td>#{@kakuma_schools}</td>
                   </tr>
                   <tr>
                     <td><i class='mdi mdi-clipboard-check mdi-18px'></i> last month:</td>
                     <td>35</td>
                   </tr>
                   <tr>
                     <td><i class='mdi mdi-clipboard-check mdi-18px'></i> last 7 days:</td>
                     <td>11</td>
                   </tr>
                   <tr>
                     <td><i class='mdi mdi-clipboard-check mdi-18px'></i> last 24 hours:</td>
                     <td>7</td>
                   </tr>
                   <tr>
                     <td><i class='mdi mdi-human-greeting mdi-18px'></i> requiring followup:</td>
                     <td>117</td>
                   </tr>
                  </table>
                </div>
              </div>
            </div>
            <div class='mdl-cell mdl-cell--4-col'>
              <div class='stats-card-wide mdl-card mdl-shadow--2dp region'>
                <div class='mdl-card__title'>
                  <h2 class='mdl-card__title-text'>Dadaab</h2>
                </div>
                <div class='mdl-card__supporting-text'>
                  <table class='mdl-data-table mdl-js-data-table mdl-shadow--2dp'>
                   <tr>
                     <td><i class='mdi mdi-human-male-female mdi-18px'></i> Students:</td>
                     <td>#{@dadaab_students}</td>
                   </tr>
                   <tr>
                     <td><i class='mdi mdi-human-female mdi-18px'></i> Girls:</td>
                     <td>#{@dadaab_girls}</td>
                   </tr>
                   <tr>
                     <td><i class='mdi mdi-human-male mdi-18px'></i> Boys:</td>
                     <td>#{@dadaab_boys}</td>
                   </tr>
                   <tr>
                     <td><i class='mdi mdi-school mdi-18px'></i> Schools:</td>
                     <td>#{@dadaab_schools}</td>
                   </tr>
                   <tr>
                     <td><i class='mdi mdi-clipboard-check mdi-18px'></i> last month:</td>
                     <td>99</td>
                   </tr>
                   <tr>
                     <td><i class='mdi mdi-clipboard-check mdi-18px'></i> last 7 days:</td>
                     <td>44</td>
                   </tr>
                   <tr>
                     <td><i class='mdi mdi-clipboard-check mdi-18px'></i> last 24 hours:</td>
                     <td>8</td>
                   </tr>
                   <tr>
                     <td><i class='mdi mdi-human-greeting mdi-18px'></i> requiring followup:</td>
                     <td>128</td>
                   </tr>
                  </table>
                </div>
              </div>
            </div>
            <div class='mdl-cell mdl-cell--4-col'>
              <div><img src='images/sample_pie1.png'></div>
              <div><img src='images/sample_pie2.png'></div>
              <div><img src='images/sample_bar1.png'></div>
            </div>
          </div>
        </div>
      "
      $('div.mdl-spinner').hide()

    .catch (error) ->
      console.error error
      $('div.mdl-spinner').hide()


module.exports = DashboardView
