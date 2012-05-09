describe "Joosy.Resource.RESTCollection", ->

  class Test extends Joosy.Resource.REST
    @entity 'test'

  data = '[{"id": 1, "name": "test1"}, {"id": 2, "name": "test2"}]'

  checkData = (collection) ->
    expect(collection.data.length).toEqual 2
    expect(collection.data[0].constructor == Test).toBeTruthy()
    expect(collection.data[0].data.name).toEqual 'test1'

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