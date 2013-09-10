#
# Module allowing to emulate Fn-based instances in JS
#
# @mixin
#
# @example
#   class Foo extends Joosy.Module
#
#     @extend Joosy.Module.Function
#
#     constructor: (value)
#       @value = value
#
#   __call: -> @value
#
#   foo = Foo.build 'test'
#   typeof(foo)             # 'function'
#   foo()                   # 'test'
#
Joosy.Modules.Function =

  build: ->
    shim  = -> shim.__call.apply shim, arguments

    if shim.__proto__
      shim.__proto__ = @::
    else
      for key, value of @::
        shim[key] = value

    shim.constructor = @

    @apply shim, arguments

    shim