describe "Joosy.Layout", ->

  beforeEach ->
    class @TestLayout extends Joosy.Layout
    @box = new @TestLayout()

  it "should have appropriate accessors", ->
    callback_names = ['beforePaint', 'paint', 'erase']
    callback_names.each (func) =>
      @TestLayout[func] 'callback'
      expect(@TestLayout::['__' + func]).toEqual 'callback'

  it "should have default view", ->
    @box = new @TestLayout()
    expect(@box.__renderer instanceof Function).toBeTruthy()

  it "should use Router", ->
    target = sinon.stub Joosy.Router, 'navigate'
    @box.navigate 'there'
    expect(target.callCount).toEqual 1
    expect(target.alwaysCalledWithExactly 'there').toBeTruthy()
    Joosy.Router.navigate.restore()

  it "should load itself", ->
    spies = []
    spies.push sinon.spy(@box, '__assignElements')
    spies.push sinon.spy(@box, '__delegateEvents')
    spies.push sinon.spy(@box, '__setupWidgets')
    spies.push sinon.spy(@box, '__runAfterLoads')
    @box.__load(@ground)
    expect(spies).toBeSequenced()

  it "should unload itself", ->
    spies = []
    spies.push sinon.spy(@box, '__clearTime')
    spies.push sinon.spy(@box, '__unloadWidgets')
    spies.push sinon.spy(@box, '__runAfterUnloads')
    @box.__unload()
    expect(spies).toBeSequenced()

  it "should generate uid", ->
    sinon.spy Joosy, 'uid'
    @box.page()
    expect(Joosy.uid.callCount).toEqual 1
    expect(@box.uid).toBeDefined()
    Joosy.uid.restore()

  it "should use uid as selector", ->
    @box.page()
    expect(@box.content().selector).toEqual '#' + @box.uid
