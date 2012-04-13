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
# @module
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
  # @param [String] to            Route to navigate to
  #
  navigate: (to) ->
    location.hash = '!' + to

  #
  # Inits the routing system and loads the current route
  # Binds the window hashchange event and therefore should only be called once
  # during system startup
  #
  __setupRoutes: ->
    @__prepareRoutes @rawRoutes
    @__respondRoute location.hash
    $(window).hashchange =>
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

Joosy.Module.merge Joosy.Router, Joosy.Modules.Events