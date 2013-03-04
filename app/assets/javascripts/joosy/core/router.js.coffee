#= require joosy/core/joosy

#
# Router. Reacts on a hash change event and loads proper pages
#
# Example:
#   Joosy.Router.map
#     404             : (path) -> alert "Page '#{path}' was not found :("
#     '/'             : Welcome.IndexPage
#     '/resources'    :
#     '/'           : Resource.IndexPage
#     '/:id'        : Resource.ShowPage
#     '/:id/edit'   : Resource.EditPage
#     '/new'        : Resource.EditPage
#
# @mixin
#
Joosy.Router =
  #
  # The Object containing route parts in keys and pages/lambdas in values
  #
  rawRoutes: Object.extended()

  #
  # Flattern routes mapped to regexps (to check if current route is what we
  # need) and actual executors
  #
  routes: Object.extended()

  #
  # The regexp to restrict the next loading url. By default set to false and
  # therefore no restrictions apply.
  #
  restrictPattern: false

  #
  # TODO: Write readme
  #
  __namespace: ""
  __asNamespace: ""

  #
  # Set the restriction pattern. If the requested url does not match this it
  # will not load. Set `false` to avoid check.
  #
  restrict: (@restrictPattern) ->

  #
  # Clears the routes
  #
  reset: ->
    @rawRoutes = Object.extended()
    @routes = Object.extended()
    @__namespace = ""
    @__asNamespace = ""


  #
  # Draws the routes similar to Ruby on Rails
  #
  # @param [Function] block   callback for child commands
  #
  draw: (block)->
    block.call(this) if Object.isFunction(block)

  #
  # Registers the set of raw routes
  # This method will only store routes and will not make them act immediately
  # Routes get registered only once at system initialization during #__setupRoutes call
  #
  # @param [Object] routes        Set of routes in inner format (see class description)
  #
  map: (routes) ->
    Joosy.Module.merge @rawRoutes, routes

  #
  # Changes current hash with shebang (#!) and therefore triggers new route loading
  # to be loaded
  #
  # @param [String] to                       Route to navigate to
  #
  # @option options [Boolean] respond        If false just changes hash without responding
  # @option options [Boolean] replaceState   If true uses replaces history entry instead of adding. Works only in browsers supporting history.pushState
  #
  navigate: (to, options={}) ->
    path = to.replace /^\#?\!?/, '!'
    if options.respond != false
      location.hash = path
    else
      if !history.pushState
        @__ignoreRequest = to
        location.hash = path
        setTimeout =>
          @__ignoreRequest = false
        , 2 # jQuery.hashchange checks hash changing every 1ms
      else
        history[if options.replaceState then 'replaceState' else 'pushState'] {}, '', '#'+path

  #
  # Match route (adds it to @rawRoutes)
  #
  # @param [String] route       similar to ones sent in map hash
  #
  # @param  options [String] to  function to which the route routes
  # @option options [String] as  name of the route, used for reverse routing
  #
  match: (route, options={}) ->
    if @__asNamespace
      as = @__asNamespace + options.as.capitalize()
    else
      as = options.as

    routeName = @__namespace + route

    map = {}
    map[route] = options.to

    Joosy.Module.merge @rawRoutes, map

    @__injectReverseUrl(as, routeName)

  #
  # Shortcut to match "/"
  #
  # @param  options [String] to  function to which the route routes
  # @option options [String] as  name of the route, used for reverse routing
  #                              default it is "root"
  #
  root: (options={}) ->
    as = options.as || "root"
    @match("/", to: options.to, as: as)

  #
  # Routes the 404
  #
  # @param options [String] to  function to which the route routes
  #
  notFound: (options={}) ->
    @match(404, to: options.to)

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

    newScope = $.extend({}, this)
    newScope.rawRoutes = {}
    newScope.__namespace += name
    newScope.__asNamespace += "#{options.as}" if options.as
    block.call(newScope) if Object.isFunction(block)
    @rawRoutes[name] = newScope.rawRoutes

  #
  # Inits the routing system and loads the current route
  # Binds the window hashchange event and therefore should only be called once
  # during system startup
  #
  __setupRoutes: ->
    $(window).hashchange =>
      unless @__ignoreRequest && location.hash.match(@__ignoreRequest)
        @__respondRoute location.hash

    @__prepareRoutes @rawRoutes
    @__respondRoute location.hash

  #
  # Compiles routes to map object
  # Object will contain regexp string as key and lambda/Page to load as value
  #
  # @param [Object] routes        Raw routes to prepare
  # @param [String] namespace     Inner cursor for recursion
  #
  __prepareRoutes: (routes, namespace='') ->
    if !namespace && routes[404]
      @wildcardAction = routes[404]
      delete routes[404]

    Object.each routes, (path, response) =>
      path = (namespace + path).replace /\/{2,}/, '/'
      if response && (Object.isFunction(response) || response.prototype?)
        Joosy.Module.merge @routes, @__prepareRoute(path, response)
      else
        @__prepareRoutes response, path

  #
  # Compiles one single route
  #
  # @param [String] path            Full path from raw route
  # @param [Joosy.Page] response    Page that should be loaded at this route
  # @param [Function] response      Lambda to call at this route
  #
  __prepareRoute: (path, response) ->
    matchPath = path.replace(/\/:([^\/]+)/g, '/([^/]+)').replace(/^\/?/, '^/?').replace(/\/?$/, '/?$')
    result    = Object.extended()

    result[matchPath] =
      capture: (path.match(/\/:[^\/]+/g) || []).map (str) ->
        str.substr 2
      action: response
    result

  #
  # Searches the corresponding route through compiled routes
  #
  # @param [String] hash        Hash value to search route for
  #
  __respondRoute: (hash) ->
    Joosy.Modules.Log.debug "Router> Answering '#{hash}'"
    fullPath = hash.replace /^#!?/, ''

    if (@restrictPattern && fullPath.match(@restrictPattern) == null)
      @trigger 'restricted', fullPath
      return
    else
      @trigger 'responded', fullPath

    @currentPath = fullPath
    found = false
    queryArray = fullPath.split '&'
    path       = queryArray.shift()
    urlParams  = @__paramsFromQueryArray queryArray

    for regex, route of @routes when @routes.hasOwnProperty regex
      if vals = path.match new RegExp(regex)
        params = @__paramsFromRouteMatch(vals, route).merge urlParams

        if Joosy.Module.hasAncestor route.action, Joosy.Page
          Joosy.Application.setCurrentPage route.action, params
        else
          route.action.call this, params

        found = true
        break

    if !found && @wildcardAction?
      if Joosy.Module.hasAncestor @wildcardAction, Joosy.Page
        Joosy.Application.setCurrentPage @wildcardAction, urlParams
      else
        @wildcardAction path, urlParams

  #
  # Collects params from route placeholders (/foo/:placeholder)
  #
  # @param [Array] vals         Array of value gathered by regexp
  # @param [Object] route       Compiled route
  # @returns [Object]           Hash of params
  #
  __paramsFromRouteMatch: (vals, route) ->
    params = Object.extended()

    vals.shift()
    for param in route.capture
      params[param] = vals.shift()

    params

  #
  # Collects params from query routes (/foo/&a=b)
  #
  # @param [Array] queryArray   Array of query string split by '&' sign
  # @returns [Object]           Hash of params
  #
  __paramsFromQueryArray: (queryArray) ->
    params = Object.extended()

    if queryArray
      $.each queryArray, ->
        unless @isBlank()
          pair = @split '='
          params[pair[0]] = pair[1]

    params

  #
  # Injects reverse routing function into global namespace
  # @param [String] as     The name for the route, ex: for "projects"
  #                        builds "projectsUrl" and "projectsPath" functions
  # @param [String] route  Entire route, joined by namespaces, ex:
  #                        "/projects/":
  #                             "/:id" :
  #                               "/edit": TestPage
  #                        joins to "/projects/:id/edit"
  #
  __injectReverseUrl: (as, route) ->
    return if as == undefined

    fnc = (options) ->
      url = route
      (route.match(/\/:[^\/]+/g) || []).each (str) ->
        url = url.replace(str.substr(1), options[str.substr(2)])
      "#!#{url}"

    Joosy.Helpers.Application["#{as}Path"] = (options) ->
      fnc(options)

    Joosy.Helpers.Application["#{as}Url"] = (options) ->
      url = location.protocol + '//' + window.location.host + window.location.pathname
      "#{url}#{fnc(options)}"

Joosy.Module.merge Joosy.Router, Joosy.Modules.Events
