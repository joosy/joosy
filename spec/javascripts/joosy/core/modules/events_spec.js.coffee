describe "Joosy.Modules.Events", ->

  beforeEach ->
    class @TestEvents extends Joosy.Module
      @include Joosy.Modules.Events
    @box = new @TestEvents()

  it "should run callback once when the all listed events have occurred", ->
    callback = sinon.spy()

    @box.wait 'events   list', callback

    @box.trigger 'events'
    expect(callback.callCount).toEqual 0
    @box.trigger 'list'
    expect(callback.callCount).toEqual 1

    @box.trigger 'events'
    expect(callback.callCount).toEqual 1
    @box.trigger 'list'
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