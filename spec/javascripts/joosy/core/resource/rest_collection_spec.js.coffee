describe "Joosy.Resource.RESTCollection", ->

  class Test extends Joosy.Resource.REST
    @entity 'test'

  data = '[{"id": 1, "name": "test1"}, {"id": 2, "name": "test2"}]'

  checkData = (collection) ->
    expect(collection.data.length).toEqual 2
    expect(collection.pages[1]).toEqual collection.data
    expect(collection.data[0].constructor == Test).toBeTruthy()
    expect(collection.data[0].e.name).toEqual 'test1'

  spoofData = (server) ->
    target = server.requests.last()
    expect(target.method).toEqual 'GET'
    expect(target.url).toMatch /^\/tests\/\?(page=\d+&)?_=\d+/
    target.respond 200, 'Content-Type': 'application/json', data

  beforeEach ->
    @server = sinon.fakeServer.create()
    @collection = new Joosy.Resource.RESTCollection(Test)

  afterEach ->
    @server.restore()

  it "should fetch", ->
    @collection.fetch()
    spoofData @server
    checkData @collection

  it "should paginate", ->
    @collection.fetch()
    spoofData @server
    checkData @collection

    @collection.page 2, callback=sinon.spy()
    spoofData @server
    expect(callback.callCount).toEqual 1
    expect(@collection.data.length).toEqual 2
    expect(@collection.data[0].constructor == Test).toBeTruthy()
    expect(@collection.data[0].e.name).toEqual 'test1'

    # Again from cache
    @collection.page 2, callback=sinon.spy()
    spoofData @server
    expect(callback.callCount).toEqual 1
    expect(@collection.data.length).toEqual 2
    expect(@collection.data[0].constructor == Test).toBeTruthy()
    expect(@collection.data[0].e.name).toEqual 'test1'
    
  it "should trigger changes", ->
    @collection.bind 'changed', callback = sinon.spy()
    @collection.fetch()
    spoofData @server
    expect(callback.callCount).toEqual 1
    @collection.page 2
    spoofData @server
    expect(callback.callCount).toEqual 2