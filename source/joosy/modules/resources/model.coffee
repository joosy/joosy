#= require ../resources

#
# The collection of methods extending basic implemenetation of resources
# adding typical model features and making it aware of primary key and collection.
#
# @example
#   class Test extends Joosy.Resources.Hash
#     @concern Joosy.Modules.Resources.Model
#
# @mixin
Joosy.Modules.Resources.Model =

  #
  # Tiny class created to contain deep fields properties
  # for nested attributes accessors
  #
  # @see Joosy.Modules.Resources.Model#attrAccessor
  #
  AttrAccessorProxy: class
    @parentFor: (object) ->
      object = object.parent while object instanceof @
      object

    constructor: ->
      Object.defineProperty @, 'parent',
        enumerable: false
        writable: true

  ClassMethods:
    #
    # Sets the field containing primary key.
    #
    # @param [String] primary     Name of the field
    #
    primaryKey: (primaryKey) ->
      @::__primaryKey = primaryKey

    #
    # Sets the collection to use
    #
    # @param [Class] klass       Class to use as a collection wrapper
    #
    collection: (klass) ->
      @::__collection = klass

    #
    # Sets the entity text name:
    #   required to do some magic like skipping the root node.
    #
    # @param [String] name    Singular name of resource
    #
    entity: (name) ->
      @::__entityName = name

    #
    # Dynamically creates collection of inline resources.
    #
    # Inline resources share the instance with direct data and therefore can be used
    #   to handle inline changes with triggers and all that resources stuff
    #
    # @example Basic usage
    #   class Model extends Joosy.Resources.Hash
    #     @concern Joosy.Modules.Resources.Model
    #
    #   class Zombie extends Model
    #     @entity 'zombie'
    #
    #   class Puppy extends Model
    #     @entity 'puppy'
    #     @map 'zombies'
    #
    #   p = Puppy.build {zombies: [{foo: 'bar'}]}
    #
    #   p.get('zombies')        # Direct access: [{foo: 'bar'}]
    #   p.zombies               # Wrapped Collection of Zombie instances
    #   p.zombies[0].get('foo') # bar
    #
    # @param [String] name    Pluralized name of property to define
    # @param [Class] klass    Resource class to instantiate
    #
    map: (name, klass=false) ->
      unless klass
        klass = window[inflection.camelize inflection.singularize(name)]

      if !klass
        throw new Error "#{Joosy.Module.__className @}> class can not be detected for '#{name}' mapping"

      unless @__mappedAttributes?
        @__mappedAttributes = {}

      @__mappedAttributes[name] = klass

      @beforeLoad (data) ->
        klass = klass() unless klass.build?

        if data[name] instanceof Array
          entries = data[name]
          data[name] = new klass::__collection klass
          data[name].load entries
        else if data[name]
          data[name] = klass.build data[name]
        data

    #
    # Creates new instance of Resource using values from form
    #
    # @param [DOMElement] form      Form to grab
    #
    grab: (form) ->
      @build({}).grab form

    #
    # Registers dynamic accessors for given fields
    #
    # @example
    #   class Test extends Joosy.Resources.Hash
    #     @concern Joosy.Modules.Resources.Model
    #
    #     @attrAccessor 'field1', 'field2', 'nested': ['n1', 'n2']
    #
    #   test = Test.build(field1: 'test', nested: {n1: 'test', n2: 'test'})
    #
    #   test.field1                      # 'test'
    #   test.field2 = 'new value'        # triggers 'changed'
    #   test.nested.n1                   # 'test'
    #   test.nested = {n1: '', n2: ''}   # triggers 'changed'
    #
    attrAccessor: (attributes...) ->
      @__buildAccessors @::, '', attributes

    #
    # Internal recursive accessors builders
    #
    # @private
    #
    # @param [Object] receiver      Current nesting instance (starting with model itself)
    # @param [String] prefix        The prefix to current attributes nesting (ending with .)
    # @param [Array]  attributes    The array of attributes to define
    #
    __buildAccessors: (receiver, prefix, attributes) ->
      proxyClass = Joosy.Modules.Resources.Model.AttrAccessorProxy

      for attribute in attributes
        if typeof attribute == 'string'
          attributeName = prefix + attribute

          do (attributeName) =>
            Object.defineProperty receiver, attribute,
              enumerable: true
              get: ->
                proxyClass.parentFor(@).get attributeName
              set: (value) ->
                proxyClass.parentFor(@).set attributeName, value

        else if attribute instanceof Array
          @__buildAccessors receiver, prefix, attribute
        else
          for key, nestedAttribute of attribute
            nestedReceiver = new proxyClass

            do (nestedReceiver) =>
              Object.defineProperty receiver, key,
                enumerable: true
                get: ->
                  nestedReceiver.parent = @
                  nestedReceiver
                set: (value) ->
                  proxyClass.parentFor(@).set prefix+key, value

            @__buildAccessors nestedReceiver, "#{prefix}#{key}.", [ nestedAttribute ]

  InstanceMethods:
    #
    # Default primary key field 'id'
    #
    __primaryKey: 'id'

    #
    # Default collection: Joosy.Resources.Array
    #
    __collection: Joosy.Resources.Collection

    #
    # Getter for the primary key field
    #
    # @see Joosy.Modules.Resources.Model.primaryKey
    #
    id: ->
      @data?[@__primaryKey]

    #
    # Returns the list of known fields for the resource
    #
    # @return [Array<String>]
    #
    # @example
    #   class Test extends Joosy.Resources.Hash
    #     @concern Joosy.Modules.Resources.Model
    #
    #   test = Test.build field1: 'test', field2: 'test'
    #
    #   test.knownAttributes() # ['field1', 'field2']
    #
    knownAttributes: ->
      Object.keys @data

    #
    # Set the resource data manually.
    #
    # Unlike the basic implementation of load, this one
    # merges newer and older fieldsets that allows you to
    # receive different parts of model data from different endpoints.
    #
    # @param [Object] data      Data to store
    # @param [Boolean] clear    Whether previous data should be overwriten (not merged)
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
    # @private
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
    # @example
    #   class Test extends Joosy.Resources.Hash
    #     @concern Joosy.Modules.Resources.Model
    #
    #   test = Test.build().grab($ 'form')
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

    # @nodoc
    toString: ->
      "<Resource #{@__entityName}> #{JSON.stringify(@data)}"