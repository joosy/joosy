describe 'Joosy.Resources.Array', ->

  describe 'in general', ->
    beforeEach ->
      @array = new Joosy.Resources.Array([1, 2, 3])

    it 'wraps', ->
      expect(@array instanceof Array).toBeTruthy()
      expect(@array.length).toEqual 3
      expect(@array[0]).toEqual 1
      expect(@array[1]).toEqual 2
      expect(@array[2]).toEqual 3

    it 'modifies', ->
      @array.push 4
      @array.push 5
      expect(@array.length).toEqual 5

    it 'triggers', ->
      spy = sinon.spy()
      @array.bind 'changed', spy

      @array.set(0, 0)
      expect(@array[0]).toEqual 0

      @array.unshift(9)
      expect(@array[0]).toEqual 9
      expect(@array.length).toEqual 4

      expect(@array.shift()).toEqual 9
      expect(@array.length).toEqual 3

      expect(@array.push(9)).toEqual 4
      expect(@array.length).toEqual 4
      expect(@array[3]).toEqual 9

      expect(@array.pop()).toEqual 9
      expect(@array.length).toEqual 3

      expect(spy.callCount).toEqual 5

  describe 'filters', ->
    it 'runs beforeFilter', ->
      class RealArray extends Joosy.Resources.Array
        @beforeLoad (data) ->
          data.push 2
          data

      array = new RealArray([1])
      expect(array[0]).toEqual 1
      expect(array[1]).toEqual 2

      array.load([5,6])
      expect(array[0]).toEqual 5
      expect(array[1]).toEqual 6
      expect(array[2]).toEqual 2
