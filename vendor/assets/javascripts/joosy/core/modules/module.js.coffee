moduleKeywords = ['included', 'extended']

class Joosy.Module
  @has_ancestor = (what, klass) ->
    [ what, klass ] = [ what.prototype, klass.prototype ]
    while what
      return true if what == klass
      what = what.constructor?.__super__
    false

  @include: (obj) ->
    throw('include(obj) requires obj') unless obj
    _(obj).each (value, key) =>
      if key not in moduleKeywords
        @::[key] = value
    obj.included?.apply(@)
    @

  @extend: (obj) ->
    throw('extend(obj) requires obj') unless obj
    _(obj).each (value, key) =>
      if key not in moduleKeywords
        @[key] = value
    obj.extended?.apply(@)
    @

  @proxy: (func) ->
    => func.apply(@, arguments)

  proxy: (func) ->
    => func.apply(@, arguments)

  constructor: ->
    @init?(arguments...)