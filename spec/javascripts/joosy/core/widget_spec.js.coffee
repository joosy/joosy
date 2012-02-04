describe "Joosy.Widget", ->

  beforeEach ->
    class @TestWidget extends Joosy.Widget
    @box = new @TestWidget()

  it "should have appropriate accessors", ->
    test = ->
    @TestWidget.view test
    expect(@TestWidget::__renderer).toEqual test
    @TestWidget.view 'test'
    expect(@TestWidget::__renderer instanceof Function).toBeTruthy()

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
    target = sinon.stub Joosy.Router, 'navigate'
    @box.navigate 'there'
    expect(target.callCount).toEqual 1
    expect(target.alwaysCalledWithExactly 'there').toBeTruthy()
    Joosy.Router.navigate.restore()

  it "should load itself", ->
    @box.data = {tested: true}
    spies = [sinon.spy()]
    @TestWidget.view spies[0]
    @parent = new Joosy.Layout()
    spies.push sinon.spy(@box, 'refreshElements')
    spies.push sinon.spy(@box, '__delegateEvents')
    spies.push sinon.spy(@box, '__runAfterLoads')
    target = @box.__load @parent, @ground
    expect(target).toBe @box
    expect(@box.__renderer.getCall(0).calledOn()).toBeFalsy()
    expect(@box.__renderer.getCall(0).args[0]).toEqual {tested: true}
    expect(spies).toBeSequenced()

  it "should unload itself", ->
    sinon.spy @box, '__runAfterUnloads'
    @box.__unload()
    target = @box.__runAfterUnloads
    expect(target.callCount).toEqual 1
    expect(target.getCall(0).calledOn()).toBeFalsy()