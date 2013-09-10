describe 'Joosy.Modules.Function', ->

  it 'works', ->
    class Generic extends Joosy.Module
      @extend Joosy.Modules.Function

      constructor: (@bar) ->
        @foo = 'bar'

      __call: -> '123'

    generic = Generic.build 'foo'

    expect(typeof generic).toEqual 'function'
    expect(generic.foo).toEqual 'bar'
    expect(generic.bar).toEqual 'foo'
    expect(generic()).toEqual '123'

  describe 'Hash', ->
    it 'works', ->
      class Hash extends Joosy.Resources.Hash
        @extend Joosy.Modules.Function

        constructor: (data) ->
          data.bar = 'foo'
          super data

      hash = Hash.build {foo: 'bar'}

      expect(typeof hash).toEqual 'function'
      expect(hash 'foo').toEqual 'bar'
      expect(hash 'bar').toEqual 'foo'