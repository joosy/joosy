#
# Module allowing to emulate Fn-based instances in JS
#
# @example
#   class Foo extends Joosy.Modules.Resources.Hash
#     @concern Joosy.Module.Function
#
#   foo = Foo.build foo: 'bar'
#   typeof(foo)                  # 'function'
#   foo('foo')                   # 'bar'
#
# @mixin
#
Joosy.Modules.Resources.Function =

  ClassMethods:
    # @nodoc
    extended: ->
      if @build
        @aliasStaticMethodChain 'build', 'function'
      else
        @build = @buildWithFunction
        @buildWithoutFunction = ->
          new @ arguments...

    # @nodoc
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