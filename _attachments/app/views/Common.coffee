class Common
  @createDialog = (content, dtitle) ->
    $("div#dialogContent").html(content)
    $('#dialog-title').html(dtitle)
    ## This is necessary for MDL switch and dynamic dom
    componentHandler.upgradeAllRegistered()

    dialog.showModal()
  
  @markTextfieldDirty = () ->
    #hack to make MDL textfield label float in edit mode
    $("input").parent().addClass('is-dirty')

module.exports = Common