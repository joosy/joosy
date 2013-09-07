#= require joosy/joosy
#= require joosy/router
#= require joosy/templaters/jst
#= require joosy/helpers

#
# Joosy Application container
#
class Joosy.Application
  @Pages: {}
  @Layouts: {}
  @Controls: {}

  @initialized: false
  @loading: true

  @defaultConfig:
    test:     false
    debug:    false
    templater:
      prefix: ''
    router:
      html5:  false
      base:   ''
      prefix: ''

  #
  # Starts Joosy application by binding to element and bootstraping routes
  #
  # @param [String] name        Name of app (the dir its located in)
  # @param [String] selector    jQuery-compatible selector of root application element
  # @param [Object] options
  #
  @initialize: (@selector, options={}) ->
    if @initialized
      throw new Error 'Attempted to initialize Application twice'

    @config = {}

    Joosy.Module.merge @config, @defaultConfig, true, true
    Joosy.Module.merge @config, window.JoosyEnvironment, true, true if window.JoosyEnvironment?
    Joosy.Module.merge @config, options, true, true

    @forceSandbox() if @config.test

    Joosy.templater new Joosy.Templaters.JST(@config.templater)
    Joosy.debug @config.debug

    Joosy.Router.setup @config.router, (action, params) =>
      if Joosy.Module.hasAncestor action, Joosy.Page
        @changePage action, params
      else if typeof(action) == 'function'
        action(params)
      else
        throw new Error "Unknown kind of route action: #{action}"

    @initialized = true

  #
  # Shuts down current application and clears state
  #
  @reset: ->
    Joosy.Router.reset()
    Joosy.templater false
    Joosy.debug false

    @page?.__unload()
    delete @page

    @loading = true
    @initialized = false

  #
  # Gets current application root node
  #
  @content: ->
    $(@selector)

  #
  # Switches to given page
  #
  # @param [Joosy.Page] page      The class (not object) of page to load
  # @param [Object] params        Hash of page params
  #
  @changePage: (page, params) ->
    attempt = new page params, @page

    unless attempt.halted
      if attempt.layoutShouldChange && attempt.layout
        attempt.layout.__bootstrapDefault attempt, @content()
      else
        attempt.__bootstrapDefault @content()

      @page = attempt

  # @private
  @forceSandbox: ->
    sandbox   = Joosy.uid()
    @selector = "##{sandbox}"
    $('body').append $('<div/>').attr('id', sandbox).css
      height:   '0px'
      width:    '0px'
      overflow: 'hidden'

# AMD wrapper
if define?.amd?
  define 'joosy/application', -> Joosy.Application