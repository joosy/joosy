#= require joosy/core/joosy

Joosy.Router =
  rawRoutes: Object.extended()
  routes: Object.extended()

  reset: ->
    @rawRoutes = Object.extended()
    @routes = Object.extended()

  map: (routes) ->
    Joosy.Module.merge @rawRoutes, routes

  setupRoutes: ->
    @prepareRoutes @rawRoutes
    @respondRoute location.hash
    $(window).hashchange =>
      @respondRoute location.hash

  prepareRoutes: (routes, namespace='') ->
    if !namespace && routes[404]
      @wildcardAction = routes[404]
      delete routes[404]

    Object.each routes, (path, response) =>
      path = (namespace + path).replace /\/{2,}/, '/'
      if response && (Object.isFunction(response) || response.prototype?)
        Joosy.Module.merge @routes, @prepareRoute(path, response)
      else
        @prepareRoutes response, path

  prepareRoute: (path, response) ->
    matchPath = path.replace(/\/:([^\/]+)/g, '/([^/]+)').replace(/^\/?/, '^/?').replace(/\/?$/, '/?$')
    result    = Object.extended()

    result[matchPath] =
      capture: (path.match(/\/:[^\/]+/g) || []).map (str) ->
        str.substr 2
      action: response
    result

  respondRoute: (hash) ->
    Joosy.Modules.Log.debug "Router> Answering '#{hash}'"
    fullPath = hash.replace /^#!?/, ''
    @currentPath = fullPath
    found = false
    queryArray = fullPath.split '&'
    path       = queryArray.shift()
    urlParams  = @paramsFromQueryArray queryArray

    for regex, route of @routes when @routes.hasOwnProperty regex
      if vals = path.match new RegExp(regex)
        params = @paramsFromRouteMatch(vals, route).merge urlParams

        if Joosy.Module.hasAncestor route.action, Joosy.Page
          Joosy.Application.setCurrentPage route.action, params
        else
          route.action.call this, params

        found = true
        break

    if !found && @wildcardAction?
      @wildcardAction path, urlParams

  paramsFromRouteMatch: (vals, route) ->
    params = Object.extended()

    vals.shift()
    for param in route.capture
      params[param] = vals.shift()

    params

  paramsFromQueryArray: (queryArray) ->
    params = Object.extended()

    if queryArray
      $.each queryArray, ->
        unless @isBlank()
          pair = @split '='
          params[pair[0]] = pair[1]

    params

  navigate: (to) ->
    location.hash = '!' + to
