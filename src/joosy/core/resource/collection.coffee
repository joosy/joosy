#
# Basic collection of Resources.
# Turns JSON array into array of Resources and manages them.
#
# @note You should not use Collection directly. It will be
#   automatically created by things like {Joosy.Resource.Generic.map}
#   or {Joosy.Resource.REST.find}.
#
# @example Basic sample
#   class R extends Joosy.Resource.Generic
#     @entity 'r'
#
#   collection = new Joosy.Resource.Collection(R)
#
#   collection.load [{foo: 'bar'}, {foo: 'baz'}]
#   collection.each (resource) ->
#     resource('foo')
#
# @include Joosy.Modules.Events
#
class Joosy.Resource.Collection extends Joosy.Module
  @include Joosy.Modules.Events

  #
  # Allows to modify data before it gets stored
  #
  # @note Supposed to be used in descendants
  #
  # @param [Function] action    `(Object) -> Object` to call
  #
  @beforeLoad: (action) -> @::__beforeLoad = action

  #
  # Sets the default model for collection
  #
  # @note Supposed to be used in descendants
  #
  # @param [Class] model     Model class
  #
  @model: (model) -> @::model = model

  #
  # If model param was empty it will fallback to `@model`
  # If both param and `@model` were empty it will throw an exception.
  #
  # @param [Class] model    Resource class which this collection will handle
  #
  constructor: (model=false, @findOptions) ->
    @model = model if model

    #
    # Modelized data storage
    #
    @data = []

    if !@model
      throw new Error "#{Joosy.Module.__className @}> model can't be empty"

  #
  # Clears the storage and attempts to import given array
  #
  # @param [Array, Hash] entities         Array of entities to import.
  #                                       If hash was given will seek for moodel name camelized and pluralized.
  # @param [Boolean] notify               Indicates whether to trigger 'changed' event
  #
  # @return [Joosy.Resource.Collection]   Returns self.
  #
  load: (entities, notify=true) ->
    if @__beforeLoad?
      entities = @__beforeLoad entities

    @data = @modelize entities

    @trigger 'changed' if notify
    this

  #
  # Turns Objects array into array of Resources
  #
  # @param [Array] collection     Array of Objects
  #
  modelize: (collection) ->
    root = @model::__entityName.pluralize()

    if collection not instanceof Array
      collection = collection?[root.camelize(false)]

      if collection not instanceof Array
        throw new Error "Can not read incoming JSON"

    collection.map (x) =>
      @model.build x

  #
  # Calls callback for each Resource inside Collection
  #
  # @param [Function] callback        `(mixed) -> mixed` to call for each Resource in collection
  #
  each: (callback) ->
    @data.each callback

  #
  # Returns number of Resources inside Collection
  #
  size: ->
    @data.length

  #
  # Gets first resource matching description (see Sugar.js Array#find)
  #
  # @param [Function] description       Callback matcher
  #
  # @return [Joosy.Resource.Generic]
  #
  find: (description) ->
    @data.find description

  sortBy: (params...) ->
    @data.sortBy params...

  #
  # Gets resource by id
  #
  # @param [Integer] id       Id to find
  #
  # @return [Joosy.Resource.Generic]
  #
  findById: (id) ->
    @data.find (x) -> x.id().toString() == id.toString()

  #
  # Gets resource by its index inside collection
  #
  # @param [Integer] i    Index
  #
  # @return [Joosy.Resource.Generic]
  #
  at: (i) ->
    @data[i]

  #
  # Removes resource from collection by its index or by === comparison
  #
  # @param [Integer] target     Index
  # @param [Resource] target    Resource by itself
  # @param [Boolean] notify     Indicates whether to trigger 'changed' event
  #
  # @return [Joosy.Resource.Generic]        Removed element
  #
  remove: (target, notify=true) ->
    if Object.isNumber target
      index = target
    else
      index = @data.indexOf target
    if index >= 0
      result = @data.splice(index, 1)[0]
      if notify
        @trigger 'changed'
    result

  #
  # Adds resource to collection to given index or to the end
  #
  # @param [Resource] element       Resource to add
  # @param [Integer] index          Index to add to. If omited will be pushed to the end
  # @param [Boolean] notify         Indicates whether to trigger 'changed' event
  #
  # @return [Joosy.Resource.Generic]    Added element
  #
  add: (element, index=false, notify=true) ->
    if typeof index is 'number'
      @data.splice index, 0, element
    else
      @data.push element

    if notify
      @trigger 'changed'
    element
