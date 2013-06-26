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
    Joosy.Router.prefix = '!'

  afterEach ->
    $(window).unbind 'hashchange'

  it "should map", ->
    Joosy.Router.map map
    expect(Joosy.Router.rawRoutes).toEqual map

  it "should initialize on setup", ->
    sinon.stub Joosy.Router, '__prepareRoutes'
    sinon.stub Joosy.Router, '__respondRoute'

    Joosy.Router.map map
    Joosy.Router.__setupRoutes()
    expect(Joosy.Router.__prepareRoutes.callCount).toEqual 1
    expect(Joosy.Router.__prepareRoutes.args[0][0]).toEqual map
    expect(Joosy.Router.__respondRoute.callCount).toEqual 1
    expect(Joosy.Router.__respondRoute.args[0][0]).toEqual location.hash
    Joosy.Router.__prepareRoutes.restore()
    Joosy.Router.__respondRoute.restore()

  it "should prepare route", ->
    route = Joosy.Router.__prepareRoute "/such/a/long/long/url/:with/:plenty/:of/:params", "123"

    expect(route).toEqual Object.extended
      '^/?such/a/long/long/url/([^/]+)/([^/]+)/([^/]+)/([^/]+)/?$':
        capture: ['with', 'plenty', 'of', 'params']
        action: "123"

  it "should cook routes", ->
    sinon.stub Joosy.Router, '__respondRoute'

    Joosy.Router.map map
    Joosy.Router.__setupRoutes()

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

    Joosy.Router.__respondRoute.restore()

  it "should get route params", ->
    route  = Joosy.Router.__prepareRoute "/such/a/long/long/url/:with/:plenty/:of/:params", "123"
    result = Joosy.Router.__paramsFromRouteMatch ['full regex match here', 1, 2, 3, 4], route.values().first()

    expect(result).toEqual Object.extended
      'with':   1
      'plenty': 2
      'of':     3
      'params': 4

  it "should build query params", ->
    result = Joosy.Router.__paramsFromQueryArray ["foo=bar", "bar=baz"]

    expect(result).toEqual Object.extended
      foo: 'bar'
      bar: 'baz'

  it "should respond routes", ->
    sinon.stub Joosy.Router, '__respondRoute'
    sinon.stub Joosy.Application, 'setCurrentPage'

    Joosy.Router.map map
    Joosy.Router.__setupRoutes()

    Joosy.Router.__respondRoute.restore()

    Joosy.Router.__respondRoute '/'
    expect(spies.root.callCount).toEqual 1

    Joosy.Router.__respondRoute '/page'
    expect(Joosy.Application.setCurrentPage.callCount).toEqual 1
    expect(Joosy.Application.setCurrentPage.args.last()).toEqual [TestPage, Object.extended()]

    Joosy.Router.__respondRoute '/section/page/1'
    expect(spies.section.callCount).toEqual 1
    expect(spies.section.args.last()).toEqual [Object.extended(id: '1')]

    Joosy.Router.__respondRoute '/section/page2/1&a=b'
    expect(Joosy.Application.setCurrentPage.callCount).toEqual 2
    expect(Joosy.Application.setCurrentPage.args.last()).toEqual [TestPage, Object.extended(more: '1', a: 'b')]

    Joosy.Router.__respondRoute '/thiswillneverbefound&a=b'
    expect(spies.wildcard.callCount).toEqual 1
    expect(spies.wildcard.args.last()).toEqual ['/thiswillneverbefound', Object.extended(a: 'b')]

    Joosy.Application.setCurrentPage.restore()

  it "should navigate", ->
    Joosy.Router.navigate 'test'
    expect(location.hash).toEqual "#!test"
    Joosy.Router.navigate ''
    expect(location.hash).toEqual '#!'
    location.hash = ''

  it "should restrict urls", ->
    sinon.stub Joosy.Router, '__respondRoute'
    sinon.stub Joosy.Application, 'setCurrentPage'

    Joosy.Router.map map
    Joosy.Router.__setupRoutes()

    Joosy.Router.__respondRoute.restore()

    Joosy.Router.restrict /^\/page$/

    Joosy.Router.__respondRoute '/page'
    Joosy.Router.__respondRoute '/section/page/1'

    expect(Joosy.Application.setCurrentPage.callCount).toEqual 1
    expect(Joosy.Application.setCurrentPage.args.last()).toEqual [TestPage, Object.extended()]

    Joosy.Application.setCurrentPage.restore()
    Joosy.Router.restrict false
    
  it "should DRAW simple routes, only using match and root", ->
    Joosy.Router.map
      '/': spies.root
      '/page': TestPage
      404: spies.wildcard
    raw_routes_for_map = Joosy.Router.rawRoutes

    Joosy.Router.reset()
    
    Joosy.Router.draw ->
      @root to: spies.root
      @match '/page', to: TestPage
      @notFound to: spies.wildcard
      
    expect(Joosy.Router.rawRoutes).toEqual(raw_routes_for_map)
    
  it "should DRAW namespaced routes", ->
    Joosy.Router.map
      '/': spies.root
      '/page': TestPage
      '/section':
        '/page/:id': spies.section
        '/page2/:more': TestPage
      404: spies.wildcard
    rawRoutesForMap = Joosy.Router.rawRoutes

    Joosy.Router.reset()
    
    Joosy.Router.draw ->
      @root to: spies.root
      @match '/page', to: TestPage
      @namespace '/section', ->
        @match '/page/:id', to: spies.section
        @match '/page2/:more', to: TestPage
      @notFound to: spies.wildcard
      
    expect(Joosy.Router.rawRoutes).toEqual(rawRoutesForMap)
    
  it "should DRAW simple route reverses, only using match and root", ->
    Joosy.Router.draw ->
      @root to: spies.root
      @match '/page', to: TestPage, as: "page"
      @match '/page/:id', to: TestPage, as: "pageFor"
      @notFound to: spies.wildcard
      
    validate = ->
      expect(@rootUrl).not.toEqual undefined
      expect(@rootPath).not.toEqual undefined
    
      expect(@rootPath()).toEqual "#!/"
      expect(@pagePath()).toEqual "#!/page"
      expect(@pageForPath(id: 3)).toEqual "#!/page/3"
    validate.call(Joosy.Helpers.Application)
    
  it "should DRAW more complex reverses using namespaces", ->
    Joosy.Router.draw ->
      @namespace '/projects', as: "projects", ->
        @match "/", to: TestPage, as: "index"
        @namespace "/:id", ->
          @match "/", to: TestPage, as: "show"
          @match "/edit", to: TestPage, as: "edit"
          @match "/delete", to: TestPage, as: "delete"
          
      @namespace '/tickets', ->
        @match "/", to: TestPage, as: "tasksIndex"
        
      @namespace '/activities', ->
        @root to: TestPage, as: "activities"

    validate = ->
      expect(@projectsIndexPath).not.toEqual undefined
      expect(@projectsIndexPath()).not.toEqual "#!/projects"
      expect(@projectsIndexPath()).toEqual "#!/projects/"
    
      expect(@projectsShowPath(id: 3)).toEqual "#!/projects/3/"
      expect(@projectsEditPath(id: 3)).toEqual "#!/projects/3/edit"
      expect(@projectsDeletePath(id: 3)).toEqual "#!/projects/3/delete"
    
      expect(@tasksIndexPath()).toEqual "#!/tickets/"
      expect(@activitiesPath()).toEqual "#!/activities/"
    validate.call(Joosy.Helpers.Application)
    
  it "should return reverse url with hostname and pathname", ->
    Joosy.Router.draw ->
      @match "/projects/", to: TestPage, as: "projectsIndex"
        
    validate = ->
      expect(@projectsIndexPath()).toEqual "#!/projects/"
      expect(@projectsIndexUrl()).toEqual "#{location.protocol}//#{location.host}#{location.pathname}#!/projects/"
    validate.call(Joosy.Helpers.Application)