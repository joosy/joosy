#= require ../resources

Joosy.Modules.Resources.IdentityMap =

  extended: ->
    @::__identityHolder = @
    @aliasStaticMethodChain 'build', 'identityMap'

  #
  # Clears the identity map cache. Recomended to be called during layout switch to
  # ensure correct garbage collection.
  #
  identityReset: ->
    @::__identityHolder.identity = {}

  identityPath: (data) ->
    [
      @::__entityName,         # entity name as a first-level entry to make inheritance safe
      "s#{@__source || ''}",   # save identity from overlaping on `@at` calls
      data[@::__primaryKey]    # direct identifier as a main distinguisher
    ]

  #
  # Wraps instance of resource inside shim-function allowing to track
  # data changes. See class example
  #
  # @return [Joosy.Resources.REST]
  #
  buildWithIdentityMap: (data={}) ->
    elements = @identityPath(data)

    if elements.filter((element) -> !element?).length == 0
      location    = @::__identityHolder.identity ?= {}
      destination = elements.pop()
      location    = location[element] ?= {} for element in elements

      # Data can be circulary referenced so we have to
      # init identity cell as a first step...
      preload = {}
      preload[@::__primaryKey] = data[@::__primaryKey]
      location[destination] ?= @buildWithoutIdentityMap preload

      # ...and load data as a second
      location[destination].load data
    else
      @buildWithoutIdentityMap data