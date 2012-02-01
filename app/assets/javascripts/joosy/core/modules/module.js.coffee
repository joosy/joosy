moduleKeywords = ['included', 'extended']

class Joosy.Module
  @__namespace__: []

  @__className__ = (klass) ->
    klass = klass.constructor unless Object.isFunction(klass)

    if klass.name?
      klass.name
    else
      klass.toString().replace(/^function ([a-zA-Z]+)\([\s\S]+/, '$1')

  @hasAncestor = (what, klass) ->
    return false unless what?

    [ what, klass ] = [ what.prototype, klass.prototype ]

    while what
      return true if what == klass
      what = what.constructor?.__super__

    false

  @include: (obj) ->
    throw new Error 'include(obj) requires obj' unless obj

    Object.each obj, (key, value) =>
      if key not in moduleKeywords
        this::[key] = value

    obj.included?.apply(this)
    this

  @extend: (obj) ->
    throw new Error 'extend(obj) requires obj' unless obj

    Object.each obj, (key, value) =>
      if key not in moduleKeywords
        this[key] = value

    obj.extended?.apply(this)
    this