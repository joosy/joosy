moduleKeywords = ['included', 'extended']

class Joosy.Module
  @__namespace__: []

  @__className = (klass) ->
    unless Object.isFunction(klass)
      klass = klass.constructor

    if klass.name?
      klass.name
    else
      klass.toString().replace /^function ([a-zA-Z]+)\([\s\S]+/, '$1'

  @hasAncestor: (what, klass) ->
    unless what? && klass?
      return false

    [what, klass] = [what.prototype, klass.prototype]

    while what
      if what == klass
        return true
      what = what.constructor?.__super__

    false
    
  @merge: (destination, source, safe=false) ->
    for key, value of source
      if source.hasOwnProperty(key)
        unless safe && destination.hasOwnProperty(key)
          destination[key] = value

  @include: (object) ->
    unless object
      throw new Error 'include(object) requires obj'

    Object.each object, (key, value) =>
      if key not in moduleKeywords
        this::[key] = value

    object.included?.apply this
    null

  @extend: (object) ->
    unless object
      throw new Error 'extend(object) requires object'

    @merge this, object

    object.extended?.apply this
    null
