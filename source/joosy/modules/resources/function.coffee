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
Joosy.Modules.Resources.Function =

  extended: ->
    if @build
      @aliasStaticMethodChain 'build', 'function'
    else
      @build = @buildWithFunction
      @buildWithoutFunction = ->
        new @ arguments...

  buildWithFunction: ->
    shim  = -> shim.__call.apply shim, arguments
    proto = @buildWithoutFunction arguments...

    if shim.__proto__
      shim.__proto__ = proto
    else
      for key, value of proto
        shim[key] = value

    shim.constructor = proto.constructor
    shim