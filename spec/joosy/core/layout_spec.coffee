describe "Joosy.Layout", ->

  beforeEach ->
    class @Layout extends Joosy.Layout
    @layout = new @Layout $('#application')

  it "generates uid", ->
    @layout.page()
    expect(@layout.uid).toBeDefined()

  it "uses uid as selector", ->
    @layout.page()
    expect(@layout.content().selector).toEqual '#' + @layout.uid

  it "integrates with Router", ->
    target = sinon.stub Joosy.Router, 'navigate'
    @layout.navigate 'there'
    expect(target.callCount).toEqual 1
    expect(target.alwaysCalledWithExactly 'there').toBeTruthy()
    Joosy.Router.navigate.restore()