#= require joosy/core/joosy

Joosy.Application =
  Pages: {}
  Layouts: {}
  Controls: {}

  selector: false

  initialize: (@name, @selector) ->
    Joosy.Router.setupRoutes()

    @templater = new Joosy.Templaters.RailsJST(@name)

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