describe "Joosy.Resource.RESTCollection", ->

  class Test extends Joosy.Resource.REST

  data = '[{"id": 1, "name": "test1"}, {"id": 2, "name": "test2"}]'

  checkData = (collection) ->
    expect(collection.data.length).toEqual 2
    expect(collection.pages[1]).toEqual collection.data
    expect(collection.data[0] instanceof Test).toBeTruthy()
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

  it "should initialize", ->
    expect(@collection.model).toEqual Test
    expect(@collection.params).toEqual Object.extended()
    expect(@collection.data).toEqual []
    expect(@collection.pages).toEqual Object.extended()

  it "should modelize", ->
    result = @collection.modelize $.parseJSON(data)
    expect(result[0] instanceof Test).toBeTruthy()
    expect(result[0].e.name).toEqual 'test1'

  it "should reset", ->
    @collection.reset $.parseJSON(data)
    checkData @collection

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
    expect(@collection.data.length).toEqual 4
    expect(@collection.data[2] instanceof Test).toBeTruthy()
    expect(@collection.data[2].e.name).toEqual 'test1'

    # Again from cache
    @collection.page 2, callback=sinon.spy()
    spoofData @server
    expect(callback.callCount).toEqual 1
    expect(@collection.data.length).toEqual 4
    expect(@collection.data[2] instanceof Test).toBeTruthy()
    expect(@collection.data[2].e.name).toEqual 'test1'