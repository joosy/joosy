describe 'Joosy.Modules.Resources.Cacher', ->

  beforeEach ->
    @spy = sinon.spy()

  afterEach ->
    localStorage.clear()

  describe 'Scalar', ->

    beforeEach ->
      spy = @spy

      class @Cacher extends Joosy.Resources.Scalar
        @include Joosy.Modules.Resources.Cacher

        @cache 'scalar'
        @fetcher (callback) ->
          spy(); callback 1

    it 'caches', ->
      @Cacher.cached (instance) =>
        expect(instance()).toEqual 1

        expect(localStorage['scalar']).toEqual '[1]'
        expect(@spy.callCount).toEqual 1

        instance.refresh (instance) =>
          expect(instance()).toEqual 1
          expect(@spy.callCount).toEqual 2

  describe 'Array', ->

    beforeEach ->
      spy = @spy

      class @Cacher extends Joosy.Resources.Array
        @include Joosy.Modules.Resources.Cacher

        @cache 'array'
        @fetcher (callback) ->
          spy(); callback 1, 2

    it 'caches', ->
      @Cacher.cached (instance) =>
        expect(instance[0]).toEqual 1
        expect(instance[1]).toEqual 2
        expect(instance.length).toEqual 2

        expect(localStorage['array']).toEqual '[1,2]'
        expect(@spy.callCount).toEqual 1

        instance.refresh (instance) =>
          expect(instance[0]).toEqual 1
          expect(instance[1]).toEqual 2
          expect(instance.length).toEqual 2

          expect(@spy.callCount).toEqual 2

  describe 'Hash', ->

    beforeEach ->
      spy = @spy

      class @Cacher extends Joosy.Resources.Hash
        @include Joosy.Modules.Resources.Cacher

        @cache 'hash'
        @fetcher (callback) ->
          spy(); callback {foo: 'bar'}

    it 'caches', ->
      @Cacher.cached (instance) =>
        expect(instance.data).toEqual {foo: 'bar'}

        expect(localStorage['hash']).toEqual '[{"foo":"bar"}]'
        expect(@spy.callCount).toEqual 1

        instance.refresh (instance) =>
          expect(instance.data).toEqual {foo: 'bar'}
          expect(@spy.callCount).toEqual 2