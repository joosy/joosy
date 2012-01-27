moduleKeywords = ['included', 'extended']

class Joosy.Module
  @__namespace__: []
  
  @cname = (klass) ->
    klass = klass.constructor unless Object.isFunction(klass)
    
    if klass.name?
      klass.name
    else
      klass.toString().replace(/function ([a-zA-Z]+)\(.*/, '$1')
  
  @hasAncestor = (what, klass) ->
    [ what, klass ] = [ what.prototype, klass.prototype ]

    while what
      return true if what == klass
      what = what.constructor?.__super__

    false

  @include: (obj) ->
    throw 'include(obj) requires obj' unless obj

    Object.extended(obj).each (key, value) =>
      if key not in moduleKeywords
        this::[key] = value

    obj.included?.apply(this)
    this

  @extend: (obj) ->
    throw 'extend(obj) requires obj' unless obj

    Object.extended(obj).each (key, value) =>
      if key not in moduleKeywords
        this[key] = value

    obj.extended?.apply(this)
    this

  constructor: ->
    @init?(arguments...)