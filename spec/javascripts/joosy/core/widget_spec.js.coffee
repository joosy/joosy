describe "Joosy.Widget", ->

  beforeEach ->
    class @TestWidget extends Joosy.Widget
    @box = new @TestWidget()

  it "should have appropriate accessors", ->
    @TestWidget.render 'function'
    expect(@TestWidget::__render).toEqual 'function'

  it "should use parent's TimeManager", ->
    @box.parent =
      setInterval: sinon.spy()
      setTimeout: sinon.spy()
    @box.setInterval 1, 2, 3
    @box.setTimeout 1, 2, 3
    target = @box.parent.setInterval
    expect(target.callCount).toEqual 1
    expect(target.alwaysCalledWithExactly 1, 2, 3).toBeTruthy()
    target = @box.parent.setTimeout
    expect(target.callCount).toEqual 1
    expect(target.alwaysCalledWithExactly 1, 2, 3).toBeTruthy()

  it "should use Router", ->
    target = sinon.spy Joosy.Router, 'navigate'
    @box.navigate 'there'
    expect(target.callCount).toEqual 1
    expect(target.alwaysCalledWithExactly 'there').toBeTruthy()
    Joosy.Router.navigate.restore()

  it "should load itself", ->
    @TestWidget.render sinon.spy()
    @parent = new Joosy.Layout()
    sinon.spy @box, 'refreshElements'
    sinon.spy @box, '__delegateEvents'
    sinon.spy @box, '__runAfterLoads'
    target = @box.__load @parent, @ground
    expect(target).toBe @box

    target = @box.__render
    expect(target.callCount).toEqual 1
    expect(target.getCall(0).calledOn()).toBeFalsy()

    prev_target = target
    target = @box.refreshElements
    expect(target.callCount).toEqual 1
    expect(target.calledAfter prev_target).toBeTruthy()

    prev_target = target
    target = @box.__delegateEvents
    expect(target.callCount).toEqual 1
    expect(target.calledAfter prev_target).toBeTruthy()

    prev_target = target
    target = @box.__runAfterLoads
    expect(target.callCount).toEqual 1
    expect(target.calledAfter prev_target).toBeTruthy()

  it "should unload itself", ->
    sinon.spy @box, '__runAfterUnloads'
    @box.__unload()
    target = @box.__runAfterUnloads
    expect(target.callCount).toEqual 1
    expect(target.getCall(0).calledOn()).toBeFalsy()
