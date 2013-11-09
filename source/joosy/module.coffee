#
# Base Joosy class extending Coffee class with module-like injections
#   and other tiny stuff.
#
class Joosy.Module
  #
  # Sets the default namespace for all Joosy descendants.
  # This is used in {Joosy.namespace} magic.
  #
  # @nodoc
  #
  @__namespace__: []

  #
  # Gets Object/Class class name.
  #
  # @note Never use this to make some magical auto-suggestions!!!
  #   Remember: minification will rename your classes. Therefore it
  #   is only intended for development debugging purposes.
  #
  # @return [String]
  #
  @__className: (klass) ->
    unless typeof(klass) == 'function'
      klass = klass.constructor

    if klass.name?
      klass.name
    else
      klass.toString().replace /^function ([a-zA-Z]+)\([\s\S]+/, '$1'

  #
  # Determines if class A has class B in its ancestors.
  #
  # @param [Class] what       Class to check againt
  # @param [Class] klass      Possible ancestor to search for
  #
  # @return [Boolean]
  #
  @hasAncestor: (what, klass) ->
    unless what? && klass?
      return false

    what  = what.prototype
    klass = klass.prototype

    while what
      if what == klass
        return true
      what = what.constructor?.__super__

    false

  #
  # Allows to override method keeping the previous implementation accessible
  #
  # @param [String] method        Name of the method to override
  # @param [String] feature       Shortcut to use as previous implementation suffix
  # @param [String] action        Name of new method to use
  # @param [Function] action      New implementation
  #
  @aliasMethodChain: (method, feature, action) ->
    camelized = feature.charAt(0).toUpperCase() + feature.slice(1)
    chained = "#{method}Without#{camelized}"

    action = @::[action] unless typeof(action) == 'function'

    @::[chained] = @::[method]
    @::[method] = action

  #
  # Allows to override class-level method keeping the previous implementation accessible
  #
  # @param [String] method        Name of the method to override
  # @param [String] feature       Shortcut to use as previous implementation suffix
  # @param [String] action        Name of new method to use
  # @param [Function] action      New implementation
  #
  @aliasStaticMethodChain: (method, feature, action) ->
    camelized = feature.charAt(0).toUpperCase() + feature.slice(1)
    chained   = "#{method}Without#{camelized}"
    action  ||= @["#{method}With#{camelized}"]

    @[chained] = @[method]
    @[method] = action

  #
  # Simple and fast shallow merge implementation.
  #
  # This is here due to: https://github.com/andrewplummer/Sugar/issues/100.
  # This bug was closed and we got some performance but this implementation is
  # still like 10x fater for basic tasks.
  #
  # @param [Object] destination       Object to extend
  # @param [Object] source            Source of new properties
  # @param [Boolean] unsafe           Determines if we should rewrite destination properties
  # @param [Boolean] deep             Whether merge should go down recursively into nested objects
  #
  # @return [Object]                  The new and mighty destination Object
  #
  @merge: (destination, source, unsafe=true, deep=false) ->
    for key, value of source
      if source.hasOwnProperty(key)
        if unsafe || !destination.hasOwnProperty(key)
          if deep && value.constructor == Object
            destination[key] = {} unless destination[key]?.constructor == Object
            Joosy.Module.merge destination[key], value
          else
            destination[key] = value
    destination

  #
  # Mixes given object as dynamic methods
  #
  # @param [Object] object          Module object
  #
  @include: (object) ->
    unless object
      throw new Error 'include(object) requires obj'

    for key, value of object
      if key != 'included' && key != 'extended'
        @::[key] = value

    object.included?.apply @
    null

  #
  # Mixes given object as static methods
  #
  # @param [Object] object          Module object
  #
  @extend: (object) ->
    unless object
      throw new Error 'extend(object) requires object'

    @merge this, object

    object.extended?.apply @
    null

  #
  # Mixes given object as a concern
  #
  # Concern is a Module containing two submodules named ClassMethods and InstanceMethods
  # that should be correspondingly extended and included
  #
  @concern: (object) ->
    @extend object.ClassMethods if object.ClassMethods?
    @include object.InstanceMethods if object.InstanceMethods?

    object.extended?.apply @
    object.included?.apply @

# AMD wrapper
if define?.amd?
  define 'joosy/module', -> Joosy.Module