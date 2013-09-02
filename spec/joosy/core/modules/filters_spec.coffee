describe "Joosy.Modules.Filters", ->

  describe 'plain', ->

    beforeEach ->
      class @Filters extends Joosy.Module
        @include Joosy.Modules.Filters
        @registerPlainFilters 'beforeLoad', 'afterLoad', 'afterUnload'

      @filters = new @Filters

    it "inherits filters by copying them", ->
      class A extends @Filters
        @beforeLoad 'filter1'
        @afterLoad 'filter2'
        @afterUnload 'filter3'

      class B extends A
        @beforeLoad 'filter4'
        @afterLoad 'filter5'
        @afterUnload 'filter6'

      target = new B
      expect(target.__beforeLoads).toEqual ['filter1', 'filter4']
      expect(target.__afterLoads).toEqual ['filter2', 'filter5']
      expect(target.__afterUnloads).toEqual ['filter3', 'filter6']

      target = new A
      expect(target.__beforeLoads).toEqual ['filter1']
      expect(target.__afterLoads).toEqual ['filter2']
      expect(target.__afterUnloads).toEqual ['filter3']

      target = new @Filters
      expect(target.__beforeLoads).toBeUndefined()
      expect(target.__afterLoads).toBeUndefined()
      expect(target.__afterUnloads).toBeUndefined()

    it "runs callbacks", ->
      callbacks = 0.upto(2).map -> sinon.spy()
      @Filters.beforeLoad callbacks[0]
      @Filters.afterLoad callbacks[1]
      @Filters.afterUnload callbacks[2]

      @filters.__confirmBeforeLoads 1, 2
      @filters.__runAfterLoads 1, 2
      @filters.__runAfterUnloads 1, 2

      for i in 0.upto(2)
        expect(callbacks[i].callCount).toEqual 1
        expect(callbacks[i].alwaysCalledWithExactly 1, 2).toBeTruthy()

    describe "chaining", ->

      it "evaluates", ->
        callbacks = 0.upto(1).map =>
          callback = sinon.stub()
          @Filters.beforeLoad callback
          callback

        callbacks[0].returns true
        callbacks[1].returns true

        expect(@filters.__confirmBeforeLoads()).toBeTruthy()

        expect(callbacks[0].callCount).toEqual 1
        expect(callbacks[1].callCount).toEqual 1

      it "breaks on false", ->
        callbacks = 0.upto(2).map =>
          callback = sinon.stub()
          @Filters.beforeLoad callback
          callback

        callbacks[0].returns true
        callbacks[1].returns false

        expect(@filters.__confirmBeforeLoads()).toBeFalsy()

        expect(callbacks[0].callCount).toEqual 1
        expect(callbacks[1].callCount).toEqual 1
        expect(callbacks[2].callCount).toEqual 0

    it "accepts method names as callbacks", ->
      @filters['callback' + i] = sinon.spy() for i in 0.upto(2)

      @Filters.beforeLoad  'callback0'
      @Filters.afterLoad   'callback1'
      @Filters.afterUnload 'callback2'
        
      @filters.__confirmBeforeLoads()
      @filters.__runAfterLoads()
      @filters.__runAfterUnloads()

      expect(@filters['callback' + i].callCount).toEqual 1 for i in 0.upto(2)

  describe 'sequenced', ->

    beforeEach ->
      class @Filters extends Joosy.Module
        @include Joosy.Modules.Filters
        @registerSequencedFilters 'beforeLoad', 'afterLoad', 'afterUnload'

      @filters = new @Filters

    it "inherits filters by copying them", ->
      class A extends @Filters
        @beforeLoad 'filter1'
        @afterLoad 'filter2'
        @afterUnload 'filter3'

      class B extends A
        @beforeLoad 'filter4'
        @afterLoad 'filter5'
        @afterUnload 'filter6'

      target = new B
      expect(target.__beforeLoads).toEqual ['filter1', 'filter4']
      expect(target.__afterLoads).toEqual ['filter2', 'filter5']
      expect(target.__afterUnloads).toEqual ['filter3', 'filter6']

      target = new A
      expect(target.__beforeLoads).toEqual ['filter1']
      expect(target.__afterLoads).toEqual ['filter2']
      expect(target.__afterUnloads).toEqual ['filter3']

      target = new @Filters
      expect(target.__beforeLoads).toBeUndefined()
      expect(target.__afterLoads).toBeUndefined()
      expect(target.__afterUnloads).toBeUndefined()

    it "runs with no callbacks", ->
      spy = sinon.spy()

      @filters.__runBeforeLoads [], =>
        @filters.__runAfterLoads ['test'], =>
          @filters.__runAfterUnloads ['test'], =>
            spy()

      expect(spy.callCount).toEqual 1

    it "runs single callbacks", ->
      spy = sinon.spy()
      context = @filters

      @Filters.beforeLoad (complete) ->
        expect(@).toEqual context
        spy(); complete()
      @Filters.afterLoad (argument, complete) ->
        expect(@).toEqual context
        spy(argument); complete()
      @Filters.afterUnload (argument1, argument2, complete) ->
        expect(@).toEqual context
        spy(argument1, argument2); complete()

      @filters.__runBeforeLoads [], =>
        expect(spy.callCount).toEqual 1

        @filters.__runAfterLoads ['test'], =>
          expect(spy.callCount).toEqual 2
          expect(spy.args[1][0]).toEqual 'test'

          @filters.__runAfterUnloads ['test', 'test2'], =>
            expect(spy.callCount).toEqual 3
            expect(spy.args[2][0]).toEqual 'test'
            expect(spy.args[2][1]).toEqual 'test2'

    it "runs multiple callbacks", ->
      spies = 0.upto(2).map -> sinon.spy()
      context = @filters

      @Filters.beforeLoad (argument, complete) ->
        expect(argument).toEqual 'test'
        expect(@).toEqual context
        spies[0]()
        complete()

      @Filters.beforeLoad (argument, complete) ->
        expect(argument).toEqual 'test'
        expect(@).toEqual context
        spies[1]()
        complete()

      @Filters.beforeLoad (argument, complete) ->
        expect(argument).toEqual 'test'
        expect(@).toEqual context
        spies[2]()
        complete()

      @filters.__runBeforeLoads ['test'], ->
        expect(spies).toBeSequenced()