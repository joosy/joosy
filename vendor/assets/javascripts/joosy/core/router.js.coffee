#= require joosy/core/joosy

Joosy.Router =
  raw_routes: Object.extended()
  routes: Object.extended()

  map: (routes) ->
    @raw_routes.merge routes

  setupRoutes: ->
    @prepareRoutes @raw_routes

    @respondRoute(location.hash)
    $(window).hashchange => @respondRoute(location.hash)

  prepareRoutes: (routes, namespace='') ->
    if !namespace && routes[404]
      @wildcardAction = routes[404]
      delete routes[404]
    routes.each (path, response) =>
      path = (namespace+path).replace(/\/{2,}/, '/')
      if typeof(response) == 'function' || response.prototype?
        @prepareRoute path, response
      else
        @prepareRoutes Object.extended(response), path

  prepareRoute: (path, response) ->
    matchPath = path.replace(/\/:([^\/]+)/g, '/([^/]+)').replace(/^\/?/, '^/?').replace(/\/?$/, '/?$')
    @routes[matchPath] =
      capture : (path.match(/\/:[^\/]+/g) || []).map((str) -> str.substr(2))
      action  : response

  respondRoute: (hash) ->
    full_path = hash.replace(/^#!?/, '')

    if @currentPath != full_path
      @currentPath = full_path
      found = false

      param_str = full_path.split('&')
      path = param_str.shift()
      url_params = @getUrlParams(param_str)

      for regex, route of @routes when @routes.hasOwnProperty(regex)
        if vals = path.match(new RegExp(regex))
          params = @getRouteParams(vals, route).merge url_params

          if !Joosy.Module.hasAncestor(route.action, Joosy.Page)
            route.action.call(this, params)
          else
            Joosy.Application.setCurrentPage(route.action, params)
          found = true
          break

      if !found && @wildcardAction
        @wildcardAction(path, url_params)

  getRouteParams: (vals, route) ->
    params = Object.extended()
    vals.shift()
    for param in route.capture
      params[param] = vals.shift()
    return params

  getUrlParams: (param_str) ->
    params = {}
    if param_str
      $.each param_str, () ->
        if @ != ''
          pair = @.split '='
          params[pair[0]] = pair[1]
    return params

  navigate: (to) ->
    location.hash = '!'+to