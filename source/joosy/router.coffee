#= require joosy/joosy
#= require joosy/modules/events
#= require joosy/page
#= require joosy/helpers/routes

#
# Router. Reacts on URI change event and loads proper pages
#
# Internal storage rules:
#
#  * HTML5 Prefix option is stored with both leading and trailing slashes
#  * Helpers' paths are stored without leading trailing slash
#  * Route matchers declare leading and trailing slashes as optional
#
# @example
#   Joosy.Router.map
#     404             : (path) -> alert "Page was not found :("
#     '/'             : Welcome.IndexPage
#     '/resources'    :
#     '/'             : Resource.IndexPage
#     '/:id'          : Resource.ShowPage
#     '/:id/edit'     : Resource.EditPage
#     '/new'          : Resource.EditPage
#
class Joosy.Router extends Joosy.Module
  @extend Joosy.Modules.Events

  # We need to be constantly subscribed to popstate event to filter
  # the first event that always happens on the initial load
  $(window).bind 'popstate', (event) =>
    if window.history.loaded?
      @trigger 'popstate', event
    else
      window.history.loaded = true

  $(document).on 'click', 'a[data-joosy]', (event) ->
    event.preventDefault()
    Joosy.Router.navigate @getAttribute('href')

  #
  # Rails-like wrapper around internal raw routes representation
  # @private
  #
  class Drawer
    @run: (block, namespace='', alias='') ->
      context = new Drawer namespace, alias
      block.call(context)

    constructor: (@__namespace, @__alias) ->

    #
    # Match route (ads it to @rawRoutes)
    #
    # @param [String] route       similar to ones sent in map hash
    #
    # @param  options [String] to  function to which the route routes
    # @option options [String] as  name of the route, used for reverse routing
    #
    match: (route, options={}) ->
      if options.as?
        if @__alias
          as = @__alias + options.as.charAt(0).toUpperCase() + options.as.slice(1)
        else
          as = options.as

      route = @__namespace + route

      Joosy.Router.compileRoute route, options.to, as

    #
    # Shortcut to match "/"
    #
    # @param  options [String] to  function to which the route routes
    # @option options [String] as  name of the route, used for reverse routing
    #                              default it is "root"
    #
    root: (options={}) ->
      @match "/", to: options.to, as: options.as || 'root'

    #
    # Routes the 404
    #
    # @param options [String] to  function to which the route routes
    #
    notFound: (options={}) ->
      @match 404, to: options.to

    #
    # Namespaces a match route
    #
    # @param [String] name     name of the namespace, prefixes other commands
    #
    # @option [Hash] options   "as", prefixes all other "as" commands
    # @param [Function] block  callback for child commands
    namespace: (name, options={}, block) ->
      if Object.isFunction(options)
        block = options
        options = {}

      Drawer.run block, @__namespace+name, options.as?.toString()

  #
  # Registers a set of raw routes
  # The method saves hash of routes for further activation
  #
  # @param [Object] routes        Set of routes in inner format (see class description)
  #
  @map: (routes, namespace) ->
    Object.each routes, (path, to) =>
      path = namespace + '/' + path if namespace?
      if Object.isFunction(to) || to.prototype
        @compileRoute path, to
      else
        @map to, path

  #
  # Draws the routes similar to Ruby on Rails
  #
  # @param [Function] block   callback for child commands
  #
  @draw: (block) ->
    Drawer.run block

  #
  # Inits the routing system and loads the current route
  #
  @setup: (@config, @responder, respond=true) ->
    # Fallback to hashchange if we are unlucky
    # enough to work in IE...
    unless history.pushState
      @config.prefix = @config.hashSuffix
      @config.html5 = false

    # ... or for some reason it was explicitly turned off
    unless @config.html5
      @config.prefix = @config.hashSuffix

    @config.prefix ||= ''

    if @config.html5
      # Canonical form of HTML5 prefix is '/any/thing/'
      @config.prefix = ('/'+@config.prefix+'/').replace /\/{2,}/g, '/'

      @listener = @bind 'popstate pushstate', =>
        @respond @canonizeLocation()
    else
      # Canonical form of hash suffix is 'any/thing'
      @config.prefix = @config.prefix.replace(/^\#?\/?/, '').replace /\/?$/, ''

      $(window).bind 'hashchange.JoosyRouter', =>
        @respond @canonizeLocation()

    @respond @canonizeLocation() if respond

  #
  # Clears current map of routes and deactivates bindings
  #
  @reset: ->
    @unbind @listener
    $(window).unbind '.JoosyRouter'
    @restriction = false
    @routes = {}

  #
  # Sets the restriction pattern.
  # Makes Router ignore URI modification if it matches given regexp.
  # Set `false` to make router react on all modifications.
  #
  # @param [Regexp] restriction
  #
  @restrict: (@restriction) ->

  #
  # Changes current URI and therefore triggers route loading
  #
  # @param [String] to                       Route to navigate to
  #
  # @option options [Boolean] respond        If false just changes route without responding
  # @option options [Boolean] replaceState   If true replaces history entry instead of adding. Works only in browsers supporting history.pushState
  #
  @navigate: (to, options={}) ->
    path = to

    if @config.html5
      # omit html5 relative links
      if @config.prefix && path[0] == '/' && !path.match(RegExp("^#{@config.prefix.replace(/\/$/, '')}(/|$)"))
        path = path.replace /^\//, @config.prefix
      history.pushState {}, '', path
      @trigger 'pushstate'
    else
      if @config.prefix && !path.match(RegExp("^#?/?#{@config.prefix}(/|$)"))
        path = path.replace /^\#?\/?/, "#{@config.prefix}/"
      location.hash = path

    return

  #
  # Gets current route out of the window location
  #
  # @note canonized location always starts with leading /
  #
  @canonizeLocation: ->
    if @config.html5
      location.pathname.replace(RegExp("^(#{@config.prefix}?)?/?"), '/')+location.search
    else
      location.hash.replace RegExp("^#?/?(#{@config.prefix}(/|$))?"), '/'

  #
  # Compiles one single route
  #
  # @param [String] path            Full path from raw route
  # @param [Class] response         Class that should be instantiated at this route
  # @param [Function] response      Lambda to call at this route
  #
  @compileRoute: (path, to, as) ->
    if path.toString() == '404'
      @wildcardAction = to
      return

    path = path.substr(1) if path[0] == '/'

    matcher = path.replace /\/{2,}/g, '/'
    result  = {}

    # Full RegExp matcher for the route
    matcher = matcher.replace(/\/:([^\/]+)/g, '/([^/]+)')   # Turning :params into regexp section
    matcher = matcher.replace(/^\/?/, '^/?')                # Making leading slash optional
    matcher = matcher.replace(/\/?$/, '/?$')                # Making trailing slash optional

    # Array of parameter names
    params  = (path.match(/\/:[^\/]+/g) || []).map (str) ->
      str.substr 2

    @routes ||= {}
    @routes[matcher] =
      to: to,
      capture: params
      as: as

    @defineHelpers path, as if as?

  #
  # Searches given route at compiled routes and reacts
  #
  # @param [String] hash        Hash value to search route for
  #
  @respond: (path) ->
    Joosy.Modules.Log.debug "Router> Answering '#{path}'"

    if (@restriction && path.match(@restriction) == null)
      @trigger 'restricted', path
      return

    [path, query] = path.split '?'
    query = query?.split?('&') || []

    for regex, route of @routes when @routes.hasOwnProperty regex
      if match = path.match new RegExp(regex)
        @responder route.to, @__grabParams(query, route, match)
        @trigger 'responded', path
        return

    if @wildcardAction?
      @responder @wildcardAction, path
      @trigger 'responded'
    else
      @trigger 'missed'

  #
  # Registers Rails-like route helpers (`fooPath()`, `fooUrl()`)
  #
  # @param [String] path             String route representation to wrap into helper
  # @param [String] as               Helpers base name
  #
  @defineHelpers: (path, as) ->
    helper = (options) ->
      result = path

      path.match(/\/:[^\/]+/g)?.each? (param) ->
        result = result.replace(param.substr(1), options[param.substr(2)])

      if Joosy.Router.config.html5
        "#{Joosy.Router.config.prefix}#{result}"
      else
        "##{Joosy.Router.config.prefix}#{result}"

    Joosy.helpers 'Routes', ->
      @["#{as}Path"] = helper

      @["#{as}Url"] = (options) ->
        if Joosy.Router.config.html5
          "#{location.origin}#{helper(options)}"
        else
          "#{location.origin}#{location.pathname}#{helper(options)}"

  @__grabParams: (query, route=null, match=[]) ->
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
