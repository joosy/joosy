#
# The hash structure with the support of dynamic rendering
#
# @include Joosy.Modules.Events
# @extend  Joosy.Modules.Filters
#
# @example
#   data = Joosy.Resources.Hash.build field1: 'test', field2: 'test'
#   data.get('field1')                              # 'test'
#   data.set('field2', 'test2')                     # triggers 'changed'
#

class Joosy.Resources.Hash extends Joosy.Module

  @include Joosy.Modules.Events
  @extend Joosy.Modules.Filters

  @registerPlainFilters 'beforeLoad'
  @registerPlainFilters 'beforeChange'

  #
  # Instantiates a new hash
  #
  @build: ->
    new @ arguments...

  #
  # Internal helper for {Joosy.Modules.Resources.Function}
  #
  __call: (path, value) ->
    if arguments.length > 1
      @set path, value
    else
      @get path

  #
  # Accepts hash of fields that have to be defined
  #
  constructor: (data={}) ->
    @__fillData data, false

  #
  # Replaces all the values with given
  #
  # @example
  #   data = Joosy.Resources.Hash.build foo: 'bar'
  #   data.load bar: 'baz'
  #   data                                          # { bar: 'baz' }
  #
  load: (data) ->
    @__fillData data
    @

  #
  # Gets value by field name.
  #
  # @param [String] path              The path to the field that should be resolved
  # @note Can resolve nested fields
  #
  # @example
  #    data.get('field')              # { subfield: 'value' }
  #    data.get('field.subfield')     # 'value'
  #
  get: (path) ->
    [instance, property] = @__callTarget path, true

    return undefined unless instance

    if instance.get
      instance.get(property)
    else
      instance[property]

  #
  # Sets value by field name.
  #
  # @param [String] path              The path to the field that should be resolved
  # @param [Mixed] value              The value to set
  # @param [Object] options
  #
  # @option options [Boolean] silent       Suppresses modification trigger
  #
  # @note Can resolve nested fields
  #
  # @example
  #    data.set('field', {subfield: 'value'})
  #    data.set('field.subfield', 'value2')
  #
  set: (path, value, options={}) ->
    [instance, property] = @__callTarget path

    if instance.set?
      instance.set(property, value, options)
    else
      instance[property] = value

    @trigger 'changed', @__applyBeforeChanges([path]) unless options.silent
    value

  #
  # Combines a new fieldset and the existing data.
  #
  # @param [Object] values            Hash of values to be set
  #
  merge: (values) ->
    Joosy.Module.merge @data, @__applyBeforeLoads(data)

    this

  #
  # Sets values of multiple fields, emitting event only once.
  #
  # @param [Object] values            Hash of values to be set
  # @param [Object] options
  #
  # @option options [Boolean] silent       Suppresses modification trigger
  #
  # @note Can resolve nested fields
  #
  # @example
  #    data.setFields('field': {subfield: 'value'})
  #    data.setFields('field.subfield': 'value2')
  #
  setFields: (values, options={}) ->
    updatedFields = []

    for path, value of values
      [instance, property] = @__callTarget path

      if instance.set?
        instance.set(property, value, options)
      else
        instance[property] = value

      updatedFields.push path

    @trigger 'changed', @__applyBeforeChanges(updatedFields) unless options.silent
    this

  #
  # Locates the actual instance of attribute path `foo.bar` from get/set
  #
  # @param [String] path    Path to the attribute (`foo.bar`)
  # @param [Boolean] safe   Indicates whether nested hashes should not be automatically created when they don't exist
  # @return [Array]         Instance of object containing last step of path and keyword for required field
  #
  __callTarget: (path, safe=false) ->
    if path.indexOf('.') != -1 && !@data[path]?
      path    = path.split '.'
      keyword = path.pop()
      target  = @data

      for part in path
        return false if safe && !target[part]?

        target[part] ?= {}

        target = if target.__get
          target.__get(part)
        else
          target[part]

      [target, keyword]
    else
      [@data, path]

  #
  # Defines how exactly prepared data should be saved
  #
  # @param [Object] data    Raw data to store
  #
  __fillData: (data, notify=true) ->
    @data = @__applyBeforeLoads data
    @trigger 'changed', @__applyBeforeChanges() if notify
    null

  #
  # @nodoc
  #
  toString: ->
    "Hash: #{JSON.stringify(@data)}"

# AMD wrapper
if define?.amd?
  define 'joosy/resources/hash', -> Joosy.Resources.Hash