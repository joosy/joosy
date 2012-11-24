describe "CachingPreloader", ->

  it "should load JS", ->
    window.variable_assigned_on_load = undefined
    localStorage.clear()

    callback = sinon.spy()
    server   = sinon.fakeServer.create()

    load = ->
      CachingPreloader.load [['/spec/javascripts/support/assets/test.js']],
        complete: callback

    load()

    expect(server.requests.length).toEqual 1
    target = server.requests[0]
    expect(target.method).toEqual 'GET'
    expect(target.url).toMatch /^\/spec\/javascripts\/support\/assets\/test.js$/
    target.respond 200, 'Content-Type': 'application/javascript',
      "window.variable_assigned_on_load = 'yapyap';"

    expect(callback.callCount).toEqual 1
    expect(window.variable_assigned_on_load).toEqual 'yapyap'
    window.variable_assigned_on_load = undefined

    load()

    expect(server.requests.length).toEqual 1
    expect(callback.callCount).toEqual 2
    expect(window.variable_assigned_on_load).toEqual 'yapyap'

    server.restore()

    window.variable_assigned_on_load = undefined
    localStorage.clear()
