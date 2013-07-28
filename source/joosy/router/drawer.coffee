#
# Rails-like wrapper around internal raw routes representation
#
class Joosy.Router.Drawer
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