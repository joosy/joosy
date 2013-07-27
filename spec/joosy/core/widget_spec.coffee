describe "Joosy.Widget", ->

  beforeEach ->
    class @Widget extends Joosy.Widget
    @widget = new @Widget

  it "integrates with Router", ->
    target = sinon.stub Joosy.Router.prototype, 'navigate'
    @widget.navigate 'there'
    expect(target.callCount).toEqual 1
    expect(target.alwaysCalledWithExactly 'there').toBeTruthy()
    Joosy.Router::navigate.restore()

  it "loads", ->
    spies = []
    spies.push sinon.spy()
    spies.push sinon.spy(@widget, '__assignElements')
    spies.push sinon.spy(@widget, '__delegateEvents')
    spies.push sinon.spy(@widget, '__runAfterLoads')

    @widget.data = tested: true
    @Widget.view spies[0]
    @parent = new Joosy.Layout

    target = @widget.__load @parent, @$ground

    expect(target).toBe @widget
    expect(spies[0].getCall(0).calledOn()).toBeFalsy()
    expect(spies[0].getCall(0).args[0].tested).toBe true
    expect(spies).toBeSequenced()

  it "unloads", ->
    sinon.spy @widget, '__runAfterUnloads'
    @widget.__unload()
    expect(@widget.__runAfterUnloads.callCount).toEqual 1
    expect(@widget.__runAfterUnloads.getCall(0).calledOn()).toBeFalsy()