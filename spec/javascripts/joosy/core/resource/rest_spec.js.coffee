describe "Joosy.Resource.REST", ->

  beforeEach ->
    @server = sinon.fakeServer.create()

    class @TestParent extends Joosy.Resource.REST
      @entity 'test_parent'

    class @Test extends Joosy.Resource.REST
      @entity 'test'

  afterEach ->
    @server.restore()

  it "builds member path", ->
    parent = @TestParent.build 1

    expect(@Test.memberPath 1).toEqual '/tests/1'
    expect(@Test.memberPath 1, parent: parent).toEqual '/test_parents/1/tests/1'
    expect(@Test.memberPath 1, parent: parent, from: 'test').toEqual '/test_parents/1/tests/1/test'
    expect(@Test.memberPath 1, parent: parent, from: 'test', params: {foo: 'bar'}).toEqual '/test_parents/1/tests/1/test'

  it "builds collection path", ->
    parent = @TestParent.build 1

    expect(@Test.collectionPath()).toEqual '/tests'
    expect(@Test.collectionPath parent: parent).toEqual '/test_parents/1/tests'
    expect(@Test.collectionPath parent: parent, from: 'test').toEqual '/test_parents/1/tests/test'
    expect(@Test.collectionPath parent: parent, from: 'test', params: {foo: 'bar'}).toEqual '/test_parents/1/tests/test'

  #it "should trigger 'changed' on fetch", ->
  #  resource = @Test.find 1, callback = sinon.spy (target) ->
  #    expect(target.id).toEqual 1
  #    expect(target.data?.name).toEqual 'test1'
  #  target = @server.requests[0]
  #  expect(target.method).toEqual 'GET'
  #  expect(target.url).toMatch /^\/tests\/1\?_=\d+/
  #  target.respond 200, 'Content-Type': 'application/json',
  #    '{"test": {"id": 1, "name": "test1"}}'
  #  expect(callback.callCount).toEqual 1
  #  
  #  resource.bind 'changed', callback = sinon.spy()
  #  resource.fetch()