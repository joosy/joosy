#= require joosy/core/joosy

#
# Joosy Application container
#
# @mixin
#
Joosy.Application =
  Pages: {}
  Layouts: {}
  Controls: {}
  
  loading: true
  identity: true
  debug: false

  #
  # Starts Joosy application by binding to element and bootstraping routes
  #
  # @param [String] name        Name of app (the dir its located in)
  # @param [String] selector    jQuery-compatible selector of root application element
  # @param [Object] options
  #
  initialize: (@name, @selector, options={}) ->
    @[key] = value for key, value of options
    @templater = new Joosy.Templaters.RailsJST @name

    Joosy.Router.__setupRoutes()

    @sandboxSelector = Joosy.uuid()
    @content().after "<div id='#{@sandboxSelector}' style='display:none'></div>"
    @sandboxSelector = '#' + @sandboxSelector

  #
  # Gets current application root node
  #
  content: ->
    $(@selector)

  #
  # Gets current application sandbox node
  #
  sandbox: ->
    $(@sandboxSelector)

  #
  # Switches to given page
  #
  # @param [Joosy.Page] page      The class (not object) of page to load
  # @param [Object] params        Hash of page params
  #
  setCurrentPage: (page, params) ->
    #if @page not instanceof page
    @page = new page params, @page