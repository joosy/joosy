describe "Joosy.Modules.Events", ->

  beforeEach ->
    class @TestEvents extends Joosy.Module
      @include Joosy.Modules.Events
    class @SubTestEvents extends @TestEvents
      @include Joosy.Modules.Events
    @box = new @TestEvents()
    @sub = new @SubTestEvents()

  it "should run callback once when the all listed events have occurred", ->
    callback = sinon.spy()

    @box.wait '  events   list ', callback

    @box.trigger 'events'
    expect(callback.callCount).toEqual 0
    @box.trigger 'list'
    expect(callback.callCount).toEqual 1

    @box.trigger 'events'
    expect(callback.callCount).toEqual 1
    @box.trigger 'list'
    expect(callback.callCount).toEqual 1

    expect(=> @box.wait '', callback).toThrow()
    expect(callback.callCount).toEqual 1

    expect(=> @box.wait '    ', callback).toThrow()
    expect(callback.callCount).toEqual 1

    expect(=> @box.wait [], callback).toThrow()
    expect(callback.callCount).toEqual 1

  it "should allow for binding and unbinding to events", ->
    callback = sinon.spy()

    @box.bind 'event', callback

    @box.trigger 'other-event'
    expect(callback.callCount).toEqual 0
    @box.trigger 'event'
    expect(callback.callCount).toEqual 1
    @box.trigger 'event'
    expect(callback.callCount).toEqual 2

    @box.unbind 'other-event'

    @box.trigger 'event'
    expect(callback.callCount).toEqual 3

    @box.unbind callback

    @box.trigger 'event'
    expect(callback.callCount).toEqual 3

  it "should allow multiple binding", ->
    callback = ->

    3.times =>
      @box.bind 'event', callback
    expect(@box.__boundEvents).toEqual [[['event'], callback], [['event'], callback], [['event'], callback]]

    3.times =>
      @box.wait 'event', callback
    expect(@box.__oneShotEvents).toEqual [[['event'], callback], [['event'], callback], [['event'], callback]]

  it "should ignore multiple binding", ->
    callback = ->

    @box.bind 'event', callback
    3.times =>
      @box.bind 'event', callback, true
    expect(@box.__boundEvents).toEqual [[['event'], callback]]

    @box.wait 'event', callback
    3.times =>
      @box.wait 'event', callback, true
    expect(@box.__oneShotEvents).toEqual [[['event'], callback]]

  it "should handle inheritance well", ->
    callback = sinon.spy()
    @sub.wait 'foo', callback

    expect(@sub.__oneShotEvents).toEqual [[['foo'], callback]]
    expect(@box.__oneShotEvents).toBeUndefined()

  it "should be safe for concurrent usage", ->
    Joosy.synchronize (context) ->
      context.do (done)  ->
        window.setTimeout ->
          expect(-> done()).not.toThrow()
        , 1
    Joosy.synchronize (context) ->
      context.do (done)  ->
        window.setTimeout ->
          expect(-> done()).not.toThrow()
        , 2
    waits 3

  it "should call finalizer", ->
    callback = sinon.spy()

    Joosy.synchronize (context) ->
      context.do (done) ->
        callback()
        done()
      context.after ->
        expect(callback.callCount).toEqual 1
        callback()

    waits 1
    expect(callback.callCount).toEqual 2

  it "should call finalizer even if context.do hasn't been called", ->
    callback = sinon.spy()

    Joosy.synchronize (context) ->
      context.after ->
        expect(callback.callCount).toEqual 0
        callback()

    waits 1
    expect(callback.callCount).toEqual 1
