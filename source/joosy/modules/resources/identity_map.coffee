#= require ../resources

#
# The basic implementation of Identity Map allowing you to automatically
# make all the instances of the same model to be a single JS Object.
#
# @example
#   class Model extends Joosy.Resources.Hash
#      @concern Joosy.Modules.Resources.Model
#      @concern Joosy.Modules.Resources.IdentityMap
#
#   foo = Test.build id: 1
#   bar = Test.build id: 1   # bar === foo
#
# @mixin
#
Joosy.Modules.Resources.IdentityMap =

  ClassMethods:
    # @nodoc
    extended: ->
      @::__identityHolder = @
      @aliasStaticMethodChain 'build', 'identityMap'

    #
    # Clears the identity map cache. Recomended to be called during layout switch to
    # ensure correct garbage collection.
    #
    identityReset: ->
      @::__identityHolder.identity = {}

    #
    # Defines the array of values identifying a unique object within a set
    #
    # @param [Mixed] data            The data given upon object creation
    # @return [Array<Mixed>]         Uniqueness path
    #
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
    # @private
    # @return [Mixed]
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