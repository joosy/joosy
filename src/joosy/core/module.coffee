#
# Base Joosy class extending Coffee class with module-like injections
#   and other tiny stuff.
#
class Joosy.Module
  #
  # Sets the default namespace for all Joosy descendants.
  # This is used in {Joosy.namespace} magic.
  #
  @__namespace__: []

  #
  # Gets Object/Class class name.
  #
  # @note Never use this to make some magical auto-suggestions!!!
  #   Remember: minifcation will rename your classes. Therefore it
  #   is only intended for development debugging purposes.
  #
  # @note Go @jashkenas Go! Give us https://github.com/jashkenas/coffee-script/issues/2052.
  #   Please go vote for this feature if you are reading this. It will
  #   give us ability to eleminate a lot of boilerplate for you.
  #
  # @return [String]
  #
  @__className: (klass) ->
    unless Object.isFunction(klass)
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

    [what, klass] = [what.prototype, klass.prototype]

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

    action = @::[action] unless Object.isFunction(action)

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
    chained = "#{method}Without#{camelized}"

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
  #
  # @return [Object]                  The new and mighty destination Object
  #
  @merge: (destination, source, unsafe=true) ->
    for key, value of source
      if source.hasOwnProperty(key)
        if unsafe || !destination.hasOwnProperty(key)
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
        this::[key] = value

    object.included?.apply this
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

    object.extended?.apply this
    null
