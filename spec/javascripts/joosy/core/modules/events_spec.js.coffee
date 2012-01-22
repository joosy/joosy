describe "Joosy.Modules.Events", ->

  beforeEach ->
    class @TestEvents extends Joosy.Module
      @include Joosy.Modules.Events
    @box = new @TestEvents()


  it "should create the events waiters list", ->
    expect(@box.__eventWaiters).toBeUndefined()
    callback = sinon.spy()
    @box.wait('events  list', callback)
    expect(@box.__eventWaiters).toEqual([[['events', '', 'list'], callback]])
    expect(callback.callCount).toEqual(0)

  it "should run callback once when the all listed events have occurred", ->
    callback = sinon.spy()
    @box.wait('events   list', callback)
    @box.trigger('events')
    expect(callback.callCount).toEqual(0)
    @box.trigger('list')
    expect(callback.callCount).toEqual(0)
    @box.trigger('')
    expect(callback.callCount).toEqual(0)
    @box.trigger('')
    expect(callback.callCount).toEqual(1)
    expect(@box.__eventWaiters).toEqual([])
    @box.trigger('events')
    expect(callback.callCount).toEqual(1)
