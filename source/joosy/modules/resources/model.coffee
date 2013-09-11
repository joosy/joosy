#= require ../resources

# @mixin
Joosy.Modules.Resources.Model =

  included: ->
    #
    # Sets the field containing primary key.
    #
    # @note It has no direct use inside the REST resource itself and can be omited.
    #   But it usually should not since we have plans on adding some kind of Identity Map to Joosy.
    #
    # @param [String] primary     Name of the field
    #
    @primaryKey = (primaryKey) ->
      @::__primaryKey = primaryKey

    #
    # Sets the collection to use
    #
    # @param [Class] klass       Class to use as a collection wrapper
    #
    @collection = (klass) ->
      @::__collection = klass

    #
    # Sets the entity text name:
    #   required to do some magic like skipping the root node.
    #
    # @param [String] name    Singular name of resource
    #
    @entity = (name) ->
      @::__entityName = name

    #
    # Dynamically creates collection of inline resources.
    #
    # Inline resources share the instance with direct data and therefore can be used
    #   to handle inline changes with triggers and all that resources stuff
    #
    # @example Basic usage
    #   class Zombie extends Joosy.Resources.REST
    #     @entity 'zombie'
    #   class Puppy extends Joosy.Resources.REST
    #     @entity 'puppy'
    #     @map 'zombies'
    #
    #   p = Puppy.build {zombies: [{foo: 'bar'}]}
    #
    #   p('zombies')            # Direct access: [{foo: 'bar'}]
    #   p.zombies               # Wrapped Collection of Zombie instances
    #   p.zombies.at(0)('foo')  # bar
    #
    # @param [String] name    Pluralized name of property to define
    # @param [Class] klass    Resource class to instantiate
    #
    @map = (name, klass=false) ->
      unless klass

        klass = window[inflection.camelize inflection.singularize(name)]

      if !klass
        throw new Error "#{Joosy.Module.__className @}> class can not be detected for '#{name}' mapping"

      @beforeLoad (data) ->
        klass = klass() unless klass.build?

        if data[name] instanceof Array
          entries = data[name].map (x) -> klass.build x
          data[name] = new klass::__collection entries...
        else if data[name]
          data[name] = klass.build data[name]
        data

    #
    # Creates new instance of Resource using values from form
    #
    # @param [DOMElement] form      Form to grab
    #
    @grab = (form) ->
      @build({}).grab form

    @attrAccessor = ->
      for attribute in arguments
        do (attribute) =>
          @::[attribute] = (value) ->
            if value
              @set attribute, value
            else
              @get attribute


  #
  # Default primary key field 'id'
  #
  __primaryKey: 'id'

  #
  # Default collection: Joosy.Resources.Array
  #
  __collection: Joosy.Resources.Array

  id: ->
    @data?[@__primaryKey]

  knownAttributes: ->
    Object.keys @data

  #
  # Set the resource data manually
  #
  # @param [Object] data      Data to store
  #
  # @return [Object]          Returns self
  #
  load: (data, clear=false) ->
    @data = {} if clear
    @__fillData data
    @

  #
  # Defines how exactly prepared data should be saved
  #
  # @param [Object] data    Raw data to store
  #
  __fillData: (data, notify=true) ->
    @raw  = data
    @data = {} unless @hasOwnProperty 'data'

    Joosy.Module.merge @data, @__applyBeforeLoads(data)
    @trigger 'changed' if notify
    null

  #
  # Updates the Resource with a data from given form
  #
  # @param [DOMElement] form      Form to grab
  #
  grab: (form) ->
    data = {}
    for field in $(form).serializeArray()
      unless data[field.name]
        data[field.name] = field.value
      else
        data[field.name] = [data[field.name]] unless data[field.name] instanceof Array
        data[field.name].push field.value

    @load data

  toString: ->
    "<Resource #{@__entityName}> #{JSON.stringify(@data)}"