#= require joosy/core/joosy
#= require_self
#= require joosy/core/router/drawer

#
# Router. Reacts on URI change event and loads proper pages
#
# Example:
#   Joosy.Router.map
#     404             : (path) -> alert "Page '#{path}' was not found :("
#     '/'             : Welcome.IndexPage
#     '/resources'    :
#     '/'             : Resource.IndexPage
#     '/:id'          : Resource.ShowPage
#     '/:id/edit'     : Resource.EditPage
#     '/new'          : Resource.EditPage
#
# @mixin
#
class Joosy.Router extends Joosy.Module
  @include Joosy.Modules.Events

  #
  # Registers a set of raw routes
  # The method saves hash of routes for further activation
  #
  # @param [Object] routes        Set of routes in inner format (see class description)
  #
  @map: (routes) ->
    @routes ||= {}
    Joosy.Module.merge @routes, routes

  #
  # Draws the routes similar to Ruby on Rails
  #
  # @param [Function] block   callback for child commands
  #
  @draw: (block)->
    Joosy.Router.Drawer.run block

  #
  # Clears current map of routes and deactivates instances
  #
  @reset: ->
    $(window).unbind '.JoosyRouter'
    @routes = {}

  #
  # Map of compiled rows
  #
  routes: {}
  
  #
  # The regexp to restrict routes reactions
  #
  # @see {#restrict}
  #
  restriction: false

  constructor: (@config={}) ->
    @config.prefix ||= ''
    @config.base   ||= ''
    @config.base     = @config.base.substr(1) if @config.base[0] == '/'
    @config.html5    = false unless history.pushState

  #
  # Sets the restriction pattern.
  # Makes Router ignore URI modification if it matches given regexp.
  # Set `false` to make router react on all modifications.
  #
  # @param [Regexp] restriction
  #
  restrict: (@restriction) ->

  #
  # Changes current URI and therefore triggers route loading
  #
  # @param [String] to                       Route to navigate to
  #
  # @option options [Boolean] respond        If false just changes route without responding
  # @option options [Boolean] replaceState   If true replaces history entry instead of adding. Works only in browsers supporting history.pushState
  #
  navigate: (to, options={}) ->
    path = to

    if @config.html5
      path = (@config.base+path).replace /\/{2,}/, '/'
    else
      path = path.substr(1) if path[0] == '#'

      if @config.prefix && !path.startsWith(@config.prefix)
        path = @config.prefix + path

    if @config.html5
      history.pushState {}, '', path
      $(window).trigger 'popstate'
    else
      location.hash = path
    return

  #
  # Inits the routing system and loads the current route
  #
  setup: (respond=true) ->
    @routes = {}

    @prepare @constructor.routes
    @respond @canonizeLocation() if respond

    if @config.html5
      $(window).bind 'popstate.JoosyRouter', =>
        @respond @canonizeLocation()
    else
      $(window).bind 'hashchange.JoosyRouter', =>
        @respond @canonizeLocation()

  #
  # Gets current route out of the window location
  #
  canonizeLocation: ->
    if @config.html5
      location.pathname.replace(///^#{RegExp.escape @config.base}///, '')+location.search
    else
      location.hash.replace ///^\#(#{@prefix})?///, ''

  #
  # Compiles all routes recursively
  #
  # @param [Object] routes        Raw routes to prepare
  # @param [String] namespace     Inner cursor for recursion
  #
  prepare: (routes, namespace) ->
    Object.each routes, (path, response) =>
      # 404 Route
      if !namespace && path == '404'
        @wildcardAction = response
        return

      path = '/' + (namespace || '') + path
      path = path.replace /\/{2,}/, '/' # Removing duplicated '/'

      if response?
        if Object.isFunction(response) ||
            Joosy.Module.hasAncestor(response, Joosy.Page) ||
            (response.to? && response.as?)
          Joosy.Module.merge @routes, @compileRoute(path, response)
        else
          @prepare response, path

  #
  # Compiles one single route
  #
  # @param [String] path            Full path from raw route
  # @param [Joosy.Page] response    Page that should be loaded at this route
  # @param [Function] response      Lambda to call at this route
  #
  compileRoute: (path, response) ->
    matcher = path
    result  = {}

    unless Object.isObject(response)
      response = {to: response}

    # Full RegExp matcher for the route
    matcher = matcher.replace(/\/:([^\/]+)/g, '/([^/]+)')   # Turning :params into regexp section
    matcher = matcher.replace(/^\/?/, '^/?')                # Making leading slash optional
    matcher = matcher.replace(/\/?$/, '/?$')                # Making trailing slash optional

    # Array of parameter names
    params  = (path.match(/\/:[^\/]+/g) || []).map (str) ->
      str.substr 2

    result[matcher] = Joosy.Module.merge response,
      capture: params

    @defineHelpers path, response.as if response.as?

    result

  #
  # Searches given route at compiled routes and reacts
  #
  # @param [String] hash        Hash value to search route for
  #
  respond: (path) ->
    Joosy.Modules.Log.debug "Router> Answering '#{path}'"

    if (@restriction && path.match(@restriction) == null)
      @trigger 'restricted', path
      return

    [path, query] = path.split '?'
    query = query?.split?('&') || []

    for regex, route of @routes when @routes.hasOwnProperty regex
      if match = path.match new RegExp(regex)
        @__respond route.to, @__grabParams(query, route, match)
        @trigger 'responded', path
        return

    if @wildcardAction?
      @__respond @wildcardAction, @__grabParams(query)
      @trigger 'responded'
    else
      @trigger 'missed'

  #
  # Registers Rails-like route helpers (`fooPath()`, `fooUrl()`)
  #
  # @param [String] path             String route representation to wrap into helper
  # @param [String] as               Helpers base name
  #
  defineHelpers: (path, as) ->
    helper = (options) =>
      path.match(/\/:[^\/]+/g)?.each? (param) ->
        path = path.replace(param.substr(1), options[param.substr(2)])

      if @config.html5
        "#{@config.base}#{path}"
      else
        "##{@config.prefix}#{path}"

    Joosy.Helpers.Application["#{as}Path"] = (options) ->
      helper(options)
      
    Joosy.Helpers.Application["#{as}Url"] = (options) =>
      if @config.html5
        "#{location.origin}#{helper(options)}"
      else
        "#{location.origin}#{location.pathname}#{helper(options)}"

  __respond: (action, params) ->
    if Joosy.Module.hasAncestor action, Joosy.Page
      Joosy.Application.setCurrentPage action, params
    else
      action.call @, params

  __grabParams: (query, route=null, match=[]) ->
    params = {}

    # Collect parameters from route placeholers
    match.shift() # First entry is full route regexp match that should be just skipped

    route?.capture?.each (key) ->
      params[key] = decodeURIComponent match.shift()

    # Collect parameters from URL query section
    query.each (entry) ->
      unless entry.isBlank()
        [key, value] = entry.split '='
        params[key] = value

    params

# AMD wrapper
if define?.amd?
  define 'joosy/router', -> Joosy.Router