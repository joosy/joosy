describe "Joosy.Application", ->

  beforeEach ->
    sinon.stub Joosy.Router.prototype, "setup"
    @$ground.seed()

  afterEach ->
    Joosy.Router::setup.restore()

  it "initializes", ->
    Joosy.Application.initialize 'app', '#application', foo: {bar: 'baz'}
    expect(Joosy.Application.page).toBeUndefined()
    expect(Joosy.Application.selector).toEqual '#application'
    expect(Joosy.Router::setup.callCount).toEqual 1
    expect(Joosy.Application.name).toEqual 'app'
    expect(Joosy.Application.config.foo.bar).toEqual 'baz'
    expect(Joosy.Application.content()).toEqual $('#application')

  it "merges config", ->
    Joosy.Application.initialize 'app', '#application', router: {html5: true}
    expect(Joosy.Application.config.router.html5).toEqual true
    expect(Joosy.Application.config.router.base).toEqual ''

  it "manages pages", ->
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