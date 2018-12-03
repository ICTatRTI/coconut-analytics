#class AppView
class AppView
  @showView = (view) =>
    if @currentView && @currentView != view
      #@currentView.remove()
      @currentView.unbind()
      @currentView.onClose?()
    @currentView = view
    @currentView.render()
   # $('#content').html @currentView.el
        
module.exports = AppView