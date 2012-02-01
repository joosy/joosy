#= require joosy/core/joosy

Joosy.Application =
  Pages: {}
  Layouts: {}
  Controls: {}

  selector: false

  initialize: (@name, @selector, options={}) ->
    @[key] = value for key, value of options
    @templater = new Joosy.Templaters.RailsJST @name

    Joosy.Router.setupRoutes()

    @sandboxSelector = Joosy.uuid()
    @content().after "<div id='#{@sandboxSelector}' style='display:none'/>"
    @sandboxSelector = '#' + @sandboxSelector

  content: ->
    $(@selector)

  sandbox: ->
    $(@sandboxSelector)

  setCurrentPage: (page, params) ->
    #if @page not instanceof page
    @page = new page params, @page
