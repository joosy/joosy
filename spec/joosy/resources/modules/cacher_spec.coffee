describe 'Joosy.Modules.Resources.Cacher', ->

  beforeEach ->
    @spy = sinon.spy()

  afterEach ->
    localStorage.clear()

  describe 'Scalar', ->

    beforeEach ->
      spy = @spy

      class @Cacher extends Joosy.Resources.Scalar
        @concern Joosy.Modules.Resources.Cacher

        @cache 'scalar'
        @fetcher (callback) ->
          spy(); callback 1

    it 'caches', ->
      @Cacher.cached (instance) =>
        expect(instance.get()).toEqual 1

        expect(localStorage['scalar']).toEqual "{\"v\":#{@Cacher.VERSION},\"d\":[1]}"
        expect(@spy.callCount).toEqual 1

        instance.refresh (instance) =>
          expect(instance.get()).toEqual 1
          expect(@spy.callCount).toEqual 2

    it 'rejects non-versioned data', ->
      @Cacher.cached (instance) =>
        localStorage['scalar'] = '[1]'
        expect(instance.get()).toEqual 1
        expect(@spy.callCount).toEqual 1

    it 'rejects data with different version', ->
      @Cacher.cached (instance) =>
        localStorage['scalar'] = "{\"v\":#{@Cacher.VERSION - 1},\"d\":[1]}"
        expect(instance.get()).toEqual 1
        expect(@spy.callCount).toEqual 1

  describe 'Array', ->

    beforeEach ->
      spy = @spy

      class @Cacher extends Joosy.Resources.Array
        @concern Joosy.Modules.Resources.Cacher

        @cache 'array'
        @fetcher (callback) ->
          spy(); callback [1, 2]

    it 'caches', ->
      @Cacher.cached (instance) =>
        expect(instance[0]).toEqual 1
        expect(instance[1]).toEqual 2
        expect(instance.length).toEqual 2

        expect(localStorage['array']).toEqual "{\"v\":#{@Cacher.VERSION},\"d\":[[1,2]]}"
        expect(@spy.callCount).toEqual 1

        instance.refresh (instance) =>
          expect(instance[0]).toEqual 1
          expect(instance[1]).toEqual 2
          expect(instance.length).toEqual 2

          expect(@spy.callCount).toEqual 2

    it 'rejects non-versioned data', ->
      @Cacher.cached (instance) =>
        localStorage['array'] = '[[1,2]]'
        expect(instance[0]).toEqual 1
        expect(instance[1]).toEqual 2
        expect(instance.length).toEqual 2
        expect(@spy.callCount).toEqual 1

    it 'rejects data with different version', ->
      @Cacher.cached (instance) =>
        localStorage['array'] = "{\"v\":#{@Cacher.VERSION - 1},\"d\":[[1,2]]}"
        expect(instance[0]).toEqual 1
        expect(instance[1]).toEqual 2
        expect(instance.length).toEqual 2
        expect(@spy.callCount).toEqual 1

  describe 'Hash', ->

    beforeEach ->
      spy = @spy

      class @Cacher extends Joosy.Resources.Hash
        @concern Joosy.Modules.Resources.Cacher

        @cache 'hash'
        @fetcher (callback) ->
          spy(); callback {foo: 'bar'}

    it 'caches', ->
      @Cacher.cached (instance) =>
        expect(instance.data).toEqual {foo: 'bar'}

        expect(localStorage['hash']).toEqual "{\"v\":#{@Cacher.VERSION},\"d\":[{\"foo\":\"bar\"}]}"
        expect(@spy.callCount).toEqual 1

        instance.refresh (instance) =>
          expect(instance.data).toEqual {foo: 'bar'}
          expect(@spy.callCount).toEqual 2

    it 'rejects non-versioned data', ->
      @Cacher.cached (instance) =>
        localStorage['hash'] = '[{"foo":"bar"}]'
        expect(instance.data).toEqual {foo: 'bar'}
        expect(@spy.callCount).toEqual 1

    it 'rejects data with different version', ->
      @Cacher.cached (instance) =>
        localStorage['hash'] = '[{"foo":"bar"}]'
        expect(instance.data).toEqual {foo: 'bar'}
        expect(@spy.callCount).toEqual 1
