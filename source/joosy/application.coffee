#= require joosy/joosy
#= require joosy/router
#= require_tree ./templaters
#= require_tree ./resources
#= require_tree ./helpers

#
# Joosy Application container
#
# @mixin
#
Joosy.Application =
  Pages: {}
  Layouts: {}
  Controls: {}

  identity: true
  debounceForms: false

  config:
    debug:    false
    router:
      html5:  false
      base:   '/'
      prefix: ''

  #
  # Starts Joosy application by binding to element and bootstraping routes
  #
  # @param [String] name        Name of app (the dir its located in)
  # @param [String] selector    jQuery-compatible selector of root application element
  # @param [Object] options
  #
  initialize: (@name, @selector, options={}) ->
    Object.merge @config, window.JoosyEnvironment, true if window.JoosyEnvironment?
    Object.merge @config, options, true

    @templater = new Joosy.Templaters.JST @name
    @router    = new Joosy.Router @config.router
    @router.setup()

  navigate: ->
    @router.navigate arguments...

  #
  # Gets current application root node
  #
  content: ->
    $(@selector)

  #
  # Switches to given page
  #
  # @param [Joosy.Page] page      The class (not object) of page to load
  # @param [Object] params        Hash of page params
  #
  setCurrentPage: (page, params) ->
    attempt = new page(params, @page)
    @page = attempt unless attempt.halted

# AMD wrapper
if define?.amd?
  define 'joosy/application', -> Joosy.Application