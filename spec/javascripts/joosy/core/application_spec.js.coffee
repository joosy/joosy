describe "Joosy.Application", ->
  
  beforeEach ->
    sinon.stub(Joosy.Router, "setupRoutes")
    @seedGround()
    
  afterEach ->
    Joosy.Router.setupRoutes.restore()
  
  it "should initialize", ->
    Joosy.Application.initialize '#application'
    expect(Joosy.Application.page).toBeUndefined()
    expect(Joosy.Application.selector).toEqual '#application'
    expect(Joosy.Application.sandboxSelector).toMatch /#[0-9A-F]{8}-[0-9A-F]{4}-4[0-9A-F]{3}-[0-9A-F]{4}-[0-9A-F]{12}/
    expect($(Joosy.Application.sandboxSelector).length).toEqual 1
    expect(Joosy.Router.setupRoutes.callCount).toEqual 1
    
  it "should set container", ->
    expect(Joosy.Application.content()).toEqual $('#application')
  
  it "should properly initialize and save pages", ->
    spy = sinon.spy()
    class Page1
      constructor: spy
    class Page2
      constructor: spy
    
    Joosy.Application.setCurrentPage(Page1, {foo: 'bar'})

    expect(Joosy.Application.page instanceof Page1).toBeTruthy()
    expect(spy.callCount).toEqual 1
    expect(spy.args[0]).toEqual [{foo: 'bar'}, undefined]
    
    Joosy.Application.setCurrentPage(Page2, {bar: 'baz'})

    expect(Joosy.Application.page instanceof Page2).toBeTruthy()
    expect(spy.callCount).toEqual 2
    expect(spy.args[1][0]).toEqual {bar: 'baz'}
    expect(spy.args[1][1] instanceof Page1).toBeTruthy()