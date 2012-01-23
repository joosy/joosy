describe "Joosy", ->

  it "should properly initialize", ->
    expect(Joosy.debug).toBeFalsy()
    expect(Joosy.Modules).toBeDefined()
    expect(Joosy.Resource).toBeDefined()
    
  it "should declare namespaces", ->
    Joosy.namespace 'Namespaces.Test1'
    Joosy.namespace 'Namespaces.Test2', ->
      @bingo = 'bongo'
    expect(window.Namespaces.Test1).toBeDefined()
    expect(window.Namespaces.Test2.bingo).toEqual('bongo')
    
  it "should generate proper UUIDs", ->
    uuids = []
    2.times -> 
      uuids.push Joosy.uuid()
    expect(uuids.unique().length).toEqual(2)
    
  it "should build proper URLs", ->
    expect(Joosy.buildUrl 'http://www.org').toEqual('http://www.org')
    expect(Joosy.buildUrl 'http://www.org#hash').toEqual('http://www.org#hash')
    expect(Joosy.buildUrl 'http://www.org', {foo: 'bar'}).toEqual('http://www.org?foo=bar')
    expect(Joosy.buildUrl 'http://www.org?bar=baz', {foo: 'bar'}).toEqual('http://www.org?bar=baz&foo=bar')
    
  it "should preload images", ->
    path   = "/spec/javascripts/support/images/"
    images = [path+"okay.jpg", path+"coolface.jpg"]
    
    callback = sinon.spy()
    
    runs -> Joosy.preloadImages images[0], callback
    waits(50)
    runs -> expect(callback.callCount).toEqual(1)
    
    # Callback should happen on cached images too
    runs -> Joosy.preloadImages images[0], callback
    waits(50)
    runs -> expect(callback.callCount).toEqual(2)
    
    # One callback per set
    runs -> Joosy.preloadImages images, callback
    waits(50)
    runs -> expect(callback.callCount).toEqual(3)