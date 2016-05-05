class Common
  @createDialog = (content, dtitle) ->
    $("div#dialogContent").html(content)
    $('#dialog-title').html(dtitle)
    dialog.showModal()
  
module.exports = Common