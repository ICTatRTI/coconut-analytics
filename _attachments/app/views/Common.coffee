dialogPolyfill = require 'dialog-polyfill'

class Common
  @createDialog = (content, dtitle) ->
    $("div#dialogContent").html(content)
    $('#dialog-title').html(dtitle)
    ## This is necessary for MDL switch and dynamic dom
    dialogPolyfill.registerDialog(dialog)
    componentHandler.upgradeAllRegistered()

    # Temporary hack for polyfill issue on non-chrome browsers
    if (Env.is_chrome)
       dialog.showModal()
    else
       dialog.show()
  
  @markTextfieldDirty = () ->
    #hack to make MDL textfield label float in edit mode
    $("input").parent().addClass('is-dirty')

module.exports = Common