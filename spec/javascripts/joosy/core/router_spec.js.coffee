describe "Joosy.Router", ->

  spies = 
    root: sinon.spy()
    page: sinon.spy()
    section: sinon.spy()
    wildcard: sinon.spy()
  
  map = 
    '/': spies.root
    '/page': spies.page
    '/section':
      '/page': spies.section
    404: spies.wildcard

  it "should map", ->
    Joosy.Router.map map
    expect(Joosy.Router.rawRoutes).toEqual map
    
  it "should initialize on setup", ->
    sinon.stub Joosy.Router, 'prepareRoutes'
    sinon.stub Joosy.Router, 'respondRoute'

    Joosy.Router.setupRoutes()
    expect(Joosy.Router.prepareRoutes.callCount).toEqual 1
    expect(Joosy.Router.prepareRoutes.args[0][0]).toEqual map
    expect(Joosy.Router.respondRoute.callCount).toEqual 1
    expect(Joosy.Router.respondRoute.args[0][0]).toEqual location.hash