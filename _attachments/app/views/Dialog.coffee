dialogPolyfill = require 'dialog-polyfill'

class Dialog
  @create = (content, dtitle) ->
    $("div#dialogContent").html(content)
    $('#dialog-title').html(dtitle)
    ## This is necessary for MDL switch and dynamic dom
    dialogPolyfill.registerDialog(dialog)
    componentHandler.upgradeAllRegistered()

    # Temporary hack for polyfill issue on non-chrome browsers
    if !dialog.open
      if (Env.is_chrome) then dialog.showModal() else dialog.show()
    

  @markTextfieldDirty = () ->
    #hack to make MDL textfield label float in edit mode
    $("input").parent().addClass('is-dirty')
    $("textarea").parent().addClass('is-dirty')
    $("select").parent().addClass('is-dirty')

  @confirm = (dtext,dtitle,actionBtns) ->
    $("div#dialogContent").html "
      <form method='dialog'>
        <div id='dialog-title'>#{dtitle}</div>
        <div id='alertText'>#{dtext}</div>
        <div id='dialogActions'>
          #{
              _.map(actionBtns, (btn) =>
                "<button type='submit' id='button#{btn}' class='mdl-button mdl-js-button mdl-button--primary' value='#{btn}'>#{btn}</button>"
               ).join("")
          }
        </div>
      </form>
    "
    if !dialog.open
      if (Env.is_chrome) then dialog.showModal() else dialog.show()

module.exports = Dialog