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
  debounceForms: false

  config:
    debug: false
    router:
      html5: false
      base:  '/'

  #
  # Starts Joosy application by binding to element and bootstraping routes
  #
  # @param [String] name        Name of app (the dir its located in)
  # @param [String] selector    jQuery-compatible selector of root application element
  # @param [Object] options
  #
  initialize: (@name, @selector, options={}) ->
    @mergeConfig(window.JoosyEnvironment) if window.JoosyEnvironment?
    @mergeConfig(options)

    @templater = new Joosy.Templaters.JST @name

    Joosy.Router.__setupRoutes()

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

  mergeConfig: (options) ->
    for key, value of options
      if Object.isObject @config[key]
        Object.merge @config[key], value
      else
        @config[key] = value