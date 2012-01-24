#= require joosy/core/joosy

Joosy.Router =
  rawRoutes: Object.extended()
  routes: Object.extended()

  map: (routes) ->
    @rawRoutes.merge routes

  setupRoutes: ->
    @prepareRoutes @rawRoutes

    @respondRoute(location.hash)
    $(window).hashchange => @respondRoute(location.hash)

  prepareRoutes: (routes, namespace='') ->
    if !namespace && routes[404]
      @wildcardAction = routes[404]
      delete routes[404]
    routes.each (path, response) =>
      path = (namespace+path).replace(/\/{2,}/, '/')
      if response && (typeof(response) == 'function' || response.prototype?)
        @prepareRoute path, response
      else
        @prepareRoutes Object.extended(response), path

  prepareRoute: (path, response) ->
    matchPath = path.replace(/\/:([^\/]+)/g, '/([^/]+)').replace(/^\/?/, '^/?').replace(/\/?$/, '/?$')
    @routes[matchPath] =
      capture : (path.match(/\/:[^\/]+/g) || []).map((str) -> str.substr(2))
      action  : response

  respondRoute: (hash) ->
    fullPath = hash.replace(/^#!?/, '')

    @currentPath = fullPath
    found = false

    paramStr = fullPath.split('&')
    path = paramStr.shift()
    urlParams = @getUrlParams(paramStr)

    for regex, route of @routes when @routes.hasOwnProperty(regex)
      if vals = path.match(new RegExp(regex))
        params = @getRouteParams(vals, route).merge urlParams

        if !Joosy.Module.hasAncestor(route.action, Joosy.Page)
          route.action.call(this, params)
        else
          Joosy.Application.setCurrentPage(route.action, params)
        found = true
        break

    if !found && @wildcardAction
      @wildcardAction(path, urlParams)

  getRouteParams: (vals, route) ->
    params = Object.extended()
    vals.shift()
    for param in route.capture
      params[param] = vals.shift()
    return params

  getUrlParams: (paramStr) ->
    params = {}
    if paramStr
      $.each paramStr, () ->
        if @ != ''
          pair = @.split '='
          params[pair[0]] = pair[1]
    return params

  navigate: (to) ->
    location.hash = '!'+to
