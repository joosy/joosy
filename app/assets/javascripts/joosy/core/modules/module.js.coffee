moduleKeywords = ['included', 'extended']

class Joosy.Module
  @__namespace__: []

  @__className__ = (klass) ->
    unless Object.isFunction(klass)
      klass = klass.constructor

    if klass.name?
      klass.name
    else
      klass.toString().replace /^function ([a-zA-Z]+)\([\s\S]+/, '$1'

  @hasAncestor = (what, klass) ->
    unless what? && klass?
      return false

    [what, klass] = [what.prototype, klass.prototype]

    while what
      if what == klass
        return true
      what = what.constructor?.__super__

    false

  @include: (obj) ->
    unless obj
      throw new Error 'include(obj) requires obj'

    Object.each obj, (key, value) =>
      if key not in moduleKeywords
        this::[key] = value

    obj.included?.apply this

    this

  @extend: (obj) ->
    unless obj
      throw new Error 'extend(obj) requires obj'

    Object.each obj, (key, value) =>
      if key not in moduleKeywords
        this[key] = value

    obj.extended?.apply this

    this
