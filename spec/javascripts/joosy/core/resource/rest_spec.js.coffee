describe "Joosy.Resource.REST", ->

  beforeEach ->
    @server = sinon.fakeServer.create()
    class @Test extends Joosy.Resource.REST

  afterEach ->
    @server.restore()


  it "should have default primary key", ->
    expect(@Test::__primaryKey).toEqual 'id'

  it "should have appropriate accessors", ->
    @Test.entity 'tada'
    expect(@Test.__entityName).toEqual 'tada'
    expect(@Test.entityName()).toEqual 'tada'
    @Test.source 'uri'
    expect(@Test.__source).toEqual 'uri'
    expect(@Test.__buildSource()).toEqual 'uri/'
    @Test.primary 'uid'
    expect(@Test::__primaryKey).toEqual 'uid'
    @Test.beforeLoad 'function'
    expect(@Test::__beforeLoad).toEqual 'function'

  it "should extact entity name from class name", ->
    class SubTest extends @Test
    expect(@Test.entityName()).toEqual 'test'
    expect(SubTest.entityName()).toEqual 'sub_test'

  it "should build source url based on entity name", ->
    options =
      extension: 'id'
      params:
        test: 1
    expect(@Test.__buildSource(options)).toEqual '/tests/id?test=1'

  it "should have overloaded constructor", ->
    resource = new Joosy.Resource.REST 'someId'
    expect(resource.id).toEqual 'someId'

    resource = new Joosy.Resource.REST
      rest:  # should match entityName
        id: 'someId'
        field: 'value'
    expect(resource.id).toEqual 'someId'
    expect(resource.e.id).toEqual 'someId'
    expect(resource.e.field).toEqual 'value'

  it 'should find single object', ->
    @Test.beforeLoad beforeLoadCallback = sinon.spy (data) ->
      expect(data.id).toEqual 1
      expect(data.name).toEqual 'test1'
    @Test.find 1, callback = sinon.spy (target) ->
      expect(target.id).toEqual 1
      expect(target.e.name).toEqual 'test1'
    target = @server.requests[0]
    expect(target.method).toEqual 'GET'
    expect(target.url).toMatch /^\/tests\/1\?_=\d+/
    target.respond 200, 'Content-Type': 'application/json',
      '{"id": 1, "name": "test1"}'
    expect(callback.callCount).toEqual 1
    expect(beforeLoadCallback.callCount).toEqual 1

  it 'should find objects collection', ->
    callback = sinon.spy (collection) ->
      i = 1
      collection.data.each (target) ->
        expect(target.id).toEqual i
        expect(target.e.name).toEqual 'test' + i
        i += 1
    @Test.find null, callback
    target = @server.requests[0]
    expect(target.method).toEqual 'GET'
    expect(target.url).toMatch /^\/tests\/\?_=\d+/
    target.respond 200, 'Content-Type': 'application/json',
      '[{"id": 1, "name": "test1"}, {"id": 2, "name": "test2"}]'
    expect(callback.callCount).toEqual 1

  it 'should destroy single object', ->
    obj = new @Test 1
    callback = sinon.spy (target) ->
      expect(target).toBe obj
    obj.destroy callback
    target = @server.requests[0]
    expect(target.method).toEqual 'DELETE'
    expect(target.url).toEqual '/tests/1'
    target.respond 200
    expect(callback.callCount).toEqual 1

  it "should identify identifiers", ->
    [0, 123, -5, '123abd', 'whatever'].each (variant) =>
      expect(@Test.__isId variant).toBeTruthy()
    [(->) , [], {}, null, undefined, true, false].each (variant) =>
      expect(@Test.__isId variant).toBeFalsy()
