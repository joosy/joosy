describe "Joosy.Resources.RESTCollection", ->

  class Test extends Joosy.Resources.REST
    @entity 'test'

  beforeEach ->
    @server = sinon.fakeServer.create()
    @collection = new Joosy.Resources.RESTCollection(Test)

  afterEach ->
    @server.restore()

  it "loads", ->
    @collection.load [{"id": 1, "name": "test1"}, {"id": 2, "name": "test2"}]
    expect(@collection.data.length).toEqual 2
    expect(@collection.data[0] instanceof Test).toBeTruthy()
    expect(@collection.data[0].data.name).toEqual 'test1'

  it "reloads", ->
    @collection.load [{"id": 1, "name": "test1"}, {"id": 2, "name": "test2"}]
    @collection.reload from: 'test'

    target = @server.requests.last()
    expect(target.method).toEqual 'GET'
    expect(target.url).toMatch /^\/tests\/test\?_=\d+/
    target.respond 200, 'Content-Type': 'application/json', '[{"id": 3, "name": "test3"}, {"id": 4, "name": "test4"}, {"id": 5, "name": "test5"}]'

    expect(@collection.data.length).toEqual 3
    expect(@collection.data[0].constructor == Test).toBeTruthy()
    expect(@collection.data[0].data.name).toEqual 'test3'

  it "should use own storage", ->
    class TestsCollection extends Joosy.Resources.RESTCollection
      @model Test
    collection = new TestsCollection()
    collection.add 'test'
    expect(collection.data).toEqual ['test']
    expect(collection.hasOwnProperty 'data').toBeTruthy()
