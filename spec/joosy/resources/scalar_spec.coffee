describe "Joosy.Resources.Scalar", ->

  describe 'in general', ->
    beforeEach ->
      @scalar = Joosy.Resources.Scalar.build(5)

    it 'wraps', ->
      expect(@scalar+1).toEqual(6)
      expect("#{@scalar}").toEqual('5')

    it 'triggers', ->
      spy = sinon.spy()
      @scalar.bind 'changed', spy

      @scalar.set(7)
      expect(@scalar.get()).toEqual 7

      @scalar.load(8)
      expect(@scalar.get()).toEqual 8

      expect(spy.callCount).toEqual 2

  describe 'filters', ->
    it 'runs beforeFilter', ->
      class Scalar extends Joosy.Resources.Scalar
        @beforeLoad (data) ->
          data + 1

      scalar = Scalar.build(5)
      expect(scalar.get()).toEqual 6

      scalar.set(5)
      expect(scalar.get()).toEqual 5

      scalar.load(7)
      expect(scalar.get()).toEqual 8