describe "Joosy.Resources.Hash", ->

  describe 'in general', ->
    beforeEach ->
      @hash = Joosy.Resources.Hash.build({foo: 'bar', bar: {baz: 'yummy!'}})

    it 'wraps', ->
      expect(typeof(@hash)).toEqual 'function'
      expect(@hash 'foo').toEqual 'bar'
      expect(@hash 'bar').toEqual {baz: 'yummy!'}
      expect(@hash 'bar.baz').toEqual 'yummy!'

    it 'sets', ->
      @hash('bar.baz', 'the ignition')
      expect(@hash.data.bar.baz).toEqual 'the ignition'
      expect(@hash 'bar.baz').toEqual 'the ignition'

    it 'gets', ->
      expect(@hash 'foo.bar.baz').toBeUndefined()
      expect(@hash.data.foo.bar).toBeUndefined()

    it 'triggers', ->
      spy = sinon.spy()
      @hash.bind 'changed', spy

      @hash 'bar.baz', 'rocking'
      expect(spy.callCount)

  describe 'nested hash', ->
    beforeEach ->
      @nested = Joosy.Resources.Hash.build(trolo: 'lo')
      @hash   = Joosy.Resources.Hash.build({foo: 'bar', bar: @nested})

    it 'gets', ->
      expect(@hash 'bar.trolo').toEqual 'lo'

    it 'sets', ->
      @hash 'bar.trolo', 'lolo'
      expect(@nested.data.trolo).toEqual 'lolo'

  describe 'filters', ->
    it 'runs beforeFilter', ->
      class Hash extends Joosy.Resources.Hash
        @beforeLoad (data) ->
          data.test = true
          data

      hash = Hash.build(foo: 'bar')
      expect(hash.data.test).toBeTruthy()
      expect(hash 'test').toBeTruthy()
