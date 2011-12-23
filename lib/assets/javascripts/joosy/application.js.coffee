Joosy.Application =
  Pages: {}
  Layouts: {}
  Controls: {}

  selector: false

  initialize: (selector) ->
    @selector = selector
    Joosy.Router.setupRoutes()

    @sandboxSelector = Joosy.uuid()
    @content().after("<div id='#{@sandboxSelector}' style='display:none'></div>")
    @sandboxSelector = '#'+@sandboxSelector

  content: ->
    $(@selector)

  sandbox: ->
    $(@sandboxSelector)

  setCurrentPage: (page, params) ->
    #if @page not instanceof page
    @page = new page(params, @page)