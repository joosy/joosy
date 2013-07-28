describe "Joosy.Layout", ->

  beforeEach ->
    class @Layout extends Joosy.Layout
    @layout = new @Layout $('#application')

  it "has appropriate accessors", ->
    callbackNames = ['beforePaint', 'paint', 'erase']
    callbackNames.each (callbackName) =>
      @Layout[callbackName] 'callback'
      expect(@Layout::['__' + callbackName]).toEqual 'callback'

  it "generates uid", ->
    @layout.page()
    expect(@layout.uid).toBeDefined()

  it "uses uid as selector", ->
    @layout.page()
    expect(@layout.content().selector).toEqual '#' + @layout.uid

  it "has default view", ->
    expect(@layout.__renderDefault instanceof Function).toBeTruthy()

  it "integrates with Router", ->
    target = sinon.stub Joosy.Router, 'navigate'
    @layout.navigate 'there'
    expect(target.callCount).toEqual 1
    expect(target.alwaysCalledWithExactly 'there').toBeTruthy()
    Joosy.Router.navigate.restore()

  it "loads", ->
    spies = []
    spies.push sinon.spy(@layout, '__assignElements')
    spies.push sinon.spy(@layout, '__delegateEvents')
    spies.push sinon.spy(@layout, '__setupWidgets')
    spies.push sinon.spy(@layout, '__runAfterLoads')
    @layout.__load(@$ground)
    expect(spies).toBeSequenced()

  it "unloads", ->
    spies = []
    spies.push sinon.spy(@layout, '__clearTime')
    spies.push sinon.spy(@layout, '__unloadWidgets')
    spies.push sinon.spy(@layout, '__runAfterUnloads')
    @layout.__unload()
    expect(spies).toBeSequenced()
