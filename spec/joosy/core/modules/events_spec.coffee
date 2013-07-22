describe "Joosy.Modules.Events", ->

  beforeEach ->
    class @Eventer extends Joosy.Module
      @include Joosy.Modules.Events

  describe "base", ->

    beforeEach ->
      @callback = sinon.spy()
      @eventer  = new @Eventer

    describe "waiter", ->

      it "fires", ->
        @eventer.wait 'events list', @callback

        @eventer.trigger 'events'
        expect(@callback.callCount).toEqual 0

        @eventer.trigger 'list'
        expect(@callback.callCount).toEqual 1

      it "fires just once", ->
        @eventer.wait 'events list', @callback

        @eventer.trigger 'events'
        @eventer.trigger 'list'
        @eventer.trigger 'events'
        @eventer.trigger 'list'

        expect(@callback.callCount).toEqual 1

      it "unbinds", ->
        binding = @eventer.wait 'events list', @callback
        @eventer.unwait binding

        @eventer.trigger 'events'
        @eventer.trigger 'list'

        expect(@callback.callCount).toEqual 0

      it "recognizes invalid arguments", ->
        expect(=> @eventer.wait '', @callback).toThrow()
        expect(=> @eventer.wait '    ', @callback).toThrow()
        expect(=> @eventer.wait [], @callback).toThrow()

    describe "binder", ->

      it "fires", ->
        @eventer.bind 'events list', @callback

        @eventer.trigger 'events'
        expect(@callback.callCount).toEqual 1

        @eventer.trigger 'list'
        expect(@callback.callCount).toEqual 2

      it "fires multiple times", ->
        @eventer.bind 'events list', @callback

        @eventer.trigger 'events'
        @eventer.trigger 'list'
        @eventer.trigger 'events'
        @eventer.trigger 'list'

        expect(@callback.callCount).toEqual 4

      it "unbinds", ->
        binding = @eventer.bind 'events list', @callback
        @eventer.unbind binding

        @eventer.trigger 'events'
        @eventer.trigger 'list'

        expect(@callback.callCount).toEqual 0

      it "recognizes invalid arguments", ->
        expect(=> @eventer.bind '', @callback).toThrow()
        expect(=> @eventer.bind '    ', @callback).toThrow()
        expect(=> @eventer.bind [], @callback).toThrow()

    it "allows simultaneous usage", ->
      3.times (i) => @eventer.bind "event#{i}", @callback
      3.times (i) => @eventer.wait "event#{i}", @callback

      @eventer.trigger 'event2'

      expect(@callback.callCount).toEqual 2

    it "handles inheritance well", ->
      class A extends @Eventer
      a = new A

      a.wait 'event', @callback

      expect(a.__oneShotEvents).toEqual 0: [['event'], @callback]
      expect(@eventer.__oneShotEvents).toBeUndefined()

  describe "synchronizer", ->

    it "finalizes", ->
      callback = sinon.spy()

      Joosy.Modules.Events.synchronize (context) ->
        context.do (done) ->
          callback()
          done()
        context.after ->
          expect(callback.callCount).toEqual 1
          callback()

      waits 1
      expect(callback.callCount).toEqual 2

    it "finalizes with no dependencies defined", ->
      callback = sinon.spy()

      Joosy.Modules.Events.synchronize (context) ->
        context.after ->
          expect(callback.callCount).toEqual 0
          callback()

      waits 1
      expect(callback.callCount).toEqual 1

    it "gets called in proper context", ->
      eventer = new @Eventer

      eventer.synchronize (context) ->
        context.do (done) ->
          expect(@).toEqual eventer
        context.after ->

    it "is safe for concurrent usage", ->
      test = (method) ->
        expect(-> method()).not.toThrow()

      Joosy.Modules.Events.synchronize (context) ->
        context.do (done)  ->
          window.setTimeout (-> test done), 1

      Joosy.Modules.Events.synchronize (context) ->
        context.do (done)  ->
          window.setTimeout (-> test done), 2

      waits 3

  describe "namespece", ->

    beforeEach ->
      @callback = sinon.spy()

    it "proxies events", ->
      eventer   = new @Eventer
      namespace = new Joosy.Events.Namespace(eventer)

      namespace.bind 'event1', @callback
      namespace.bind 'event2', @callback

      eventer.trigger 'event1'
      eventer.trigger 'event2'

      expect(@callback.callCount).toEqual 2

    it "unbinds events", ->
      eventer   = new @Eventer
      namespace = new Joosy.Events.Namespace(eventer)

      namespace.bind 'event1', @callback
      namespace.bind 'event2', @callback

      namespace.unbind()

      eventer.trigger 'event1'
      eventer.trigger 'event2'

      expect(@callback.callCount).toEqual 0