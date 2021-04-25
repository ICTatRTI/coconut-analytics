Backbone = require 'backbone'
Backbone.$  = $

class AdministrativeAreaSelectorView extends Backbone.View

  events:
    "change #administrativeLevel": "updateAdministrativeNameOptions"
    "change #administrativeName": "updateAdministrativeArea"

  updateAdministrativeNameOptions: =>
    @administrativeLevel = @$("#administrativeLevel option:selected").text().trim()
    @$("#administrativeName").html @optionsForAdministrativeNames()
    @administrativeName = null
    @onChange(@administrativeName, @administrativeLevel) if @onlyOneOption

  updateAdministrativeArea: =>
    @administrativeName = @$("#administrativeName option:selected").text().trim()
    @ancestors = GeoHierarchy.findOneMatchOrUndefined(@administrativeName, @administrativeLevel)?.ancestors().map (unit) => unit.name
    @onChange(@administrativeName, @administrativeLevel)

  optionsForAdministrativeNames: =>
    @administrativeLevel or= "National"
    names = _(GeoHierarchy.findAllForLevel(@administrativeLevel)).pluck "name"
    if names.length is 1 # Select the first one if there is only one choice
      @administrativeName is names[0]
      @onlyOneOption = true
    else
      names.unshift ""
      @onlyOneOption = false

    (for name in names
      "
      <option 
        #{if name is @administrativeName then "selected='true'" else "" }
      >
        #{name}
      </option>
      "
    ).join()

  render: => 
    @$el.html "
      Administrative Area<br/>
      <select id='administrativeLevel'>
        #{
          (for level in GeoHierarchy.levels
            "
            <option
              #{if level.name is @administrativeLevel then "selected='true'" else "" }
            >
              #{level.name}
            </option>
            "
          ).join()
        }
      </select>
      <br/>
      <select id='administrativeName'>
        #{
          @optionsForAdministrativeNames()
        }
      </select>
    "

module.exports = AdministrativeAreaSelectorView
