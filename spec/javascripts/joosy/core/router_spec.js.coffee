describe "Joosy.Router", ->

  class TestPage extends Joosy.Page

  spies =
    root: sinon.spy()
    section: sinon.spy()
    wildcard: sinon.spy()

  map = Object.extended
    '/': spies.root
    '/page': TestPage
    '/section':
      '/page/:id': spies.section
      '/page2/:more': TestPage
    404: spies.wildcard

  beforeEach ->
    Joosy.Router.reset()

  afterEach ->
    $(window).unbind 'hashchange'

  it "should map", ->
    Joosy.Router.map map
    expect(Joosy.Router.rawRoutes).toEqual map

  it "should initialize on setup", ->
    sinon.stub Joosy.Router, 'prepareRoutes'
    sinon.stub Joosy.Router, 'respondRoute'

    Joosy.Router.map map
    Joosy.Router.setupRoutes()
    expect(Joosy.Router.prepareRoutes.callCount).toEqual 1
    expect(Joosy.Router.prepareRoutes.args[0][0]).toEqual map
    expect(Joosy.Router.respondRoute.callCount).toEqual 1
    expect(Joosy.Router.respondRoute.args[0][0]).toEqual location.hash
    Joosy.Router.prepareRoutes.restore()
    Joosy.Router.respondRoute.restore()

  it "should prepare route", ->
    route = Joosy.Router.prepareRoute "/such/a/long/long/url/:with/:plenty/:of/:params", "123"

    expect(route).toEqual Object.extended
      '^/?such/a/long/long/url/([^/]+)/([^/]+)/([^/]+)/([^/]+)/?$':
        capture: ['with', 'plenty', 'of', 'params']
        action: "123"

  it "should cook routes", ->
    sinon.stub Joosy.Router, 'respondRoute'

    Joosy.Router.map map
    Joosy.Router.setupRoutes()

    expect(Joosy.Router.routes).toEqual Object.extended
      '^/?/?$':
        capture: []
        action: spies.root
      '^/?page/?$':
        capture: []
        action: TestPage
      '^/?section/page/([^/]+)/?$':
        capture: ['id']
        action: spies.section
      '^/?section/page2/([^/]+)/?$':
        capture: ['more']
        action: TestPage

    Joosy.Router.respondRoute.restore()

  it "should get route params", ->
    route  = Joosy.Router.prepareRoute "/such/a/long/long/url/:with/:plenty/:of/:params", "123"
    result = Joosy.Router.paramsFromRouteMatch ['full regex match here', 1,2,3,4], route.values().first()

    expect(result).toEqual Object.extended
      with: 1
      plenty: 2
      of: 3
      params: 4

  it "should build query params", ->
    result = Joosy.Router.paramsFromQueryArray ["foo=bar", "bar=baz"]

    expect(result).toEqual Object.extended
      foo: 'bar'
      bar: 'baz'

  it "should respond routes", ->
    sinon.stub Joosy.Router, 'respondRoute'
    sinon.stub Joosy.Application, 'setCurrentPage'

    Joosy.Router.map map
    Joosy.Router.setupRoutes()

    Joosy.Router.respondRoute.restore()

    Joosy.Router.respondRoute '/'
    expect(spies.root.callCount).toEqual 1

    Joosy.Router.respondRoute '/page'
    expect(Joosy.Application.setCurrentPage.callCount).toEqual 1
    expect(Joosy.Application.setCurrentPage.args.last()).toEqual [TestPage, Object.extended()]

    Joosy.Router.respondRoute '/section/page/1'
    expect(spies.section.callCount).toEqual 1
    expect(spies.section.args.last()).toEqual [Object.extended(id: '1')]

    Joosy.Router.respondRoute '/section/page2/1&a=b'
    expect(Joosy.Application.setCurrentPage.callCount).toEqual 2
    expect(Joosy.Application.setCurrentPage.args.last()).toEqual [TestPage, Object.extended(more: '1', a: 'b')]

    Joosy.Router.respondRoute '/thiswillneverbefound&a=b'
    expect(spies.wildcard.callCount).toEqual 1
    expect(spies.wildcard.args.last()).toEqual ['/thiswillneverbefound', Object.extended(a: 'b')]

    Joosy.Application.setCurrentPage.restore()

  it "should navigate", ->
    location.hash = ''
    expect(location.hash).toEqual ''
    Joosy.Router.navigate 'test'
    expect(location.hash).toEqual '#!test'
    Joosy.Router.navigate ''
    expect(location.hash).toEqual '#!'
    location.hash = ''