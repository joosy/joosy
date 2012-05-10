describe "Joosy.Resource.REST", ->

  class FluffyParent extends Joosy.Resource.REST
    @entity 'test_parent'

  class Fluffy extends Joosy.Resource.REST
    @entity 'test'

  beforeEach ->
    @server = sinon.fakeServer.create()

  afterEach ->
    @server.restore()

  checkAndRespond = (target, method, url, data) ->
    expect(target.method).toEqual method
    expect(target.url).toMatch url
    target.respond 200, 'Content-Type': 'application/json', data

  it "builds member path", ->
    parent = FluffyParent.build 1

    expect(Fluffy.memberPath 1).toEqual '/tests/1'
    expect(Fluffy.memberPath 1, parent: parent).toEqual '/test_parents/1/tests/1'
    expect(Fluffy.memberPath 1, parent: parent, from: 'test').toEqual '/test_parents/1/tests/1/test'
    expect(Fluffy.memberPath 1, parent: parent, from: 'test', params: {foo: 'bar'}).toEqual '/test_parents/1/tests/1/test'

  it "builds collection path", ->
    parent = FluffyParent.build 1

    expect(Fluffy.collectionPath()).toEqual '/tests'
    expect(Fluffy.collectionPath parent: parent).toEqual '/test_parents/1/tests'
    expect(Fluffy.collectionPath parent: parent, from: 'test').toEqual '/test_parents/1/tests/test'
    expect(Fluffy.collectionPath parent: parent, from: 'test', params: {foo: 'bar'}).toEqual '/test_parents/1/tests/test'


  describe "finds resource", ->
    rawData = '{"test": {"id": 1, "name": "test1"}}'

    callback = sinon.spy (target) ->
      expect(target instanceof Fluffy).toEqual true
      expect(target.id()).toEqual 1
      expect(target 'name').toEqual 'test1'

    it "without params", ->
      resource = Fluffy.find 1, callback
      checkAndRespond @server.requests[0], 'GET', /^\/tests\/1\?_=\d+/, rawData
      expect(callback.callCount).toEqual 1

    it "with from", ->
      resource = Fluffy.find 1, {from: 'action'}, callback
      checkAndRespond @server.requests[0], 'GET', /^\/tests\/1\/action\?_=\d+/, rawData
      expect(callback.callCount).toEqual 2

    it "with from and parent", ->
      resource = Fluffy.find 1, {parent: FluffyParent.build(1), from: 'action'}, callback
      checkAndRespond @server.requests[0], 'GET', /^\/test_parents\/1\/tests\/1\/action\?_=\d+/, rawData
      expect(callback.callCount).toEqual 3

    it "with params", ->
      resource = Fluffy.find 1, params: {foo: 'bar'}, callback
      checkAndRespond @server.requests[0], 'GET', /^\/tests\/1\?foo=bar&_=\d+/, rawData
      expect(callback.callCount).toEqual 4

    it "with direct assignation", ->
      resource = Fluffy.find 1, ->
        expect(resource instanceof Fluffy).toEqual true
        expect(resource.id()).toEqual 1
        expect(resource 'name').toEqual 'test1'

      checkAndRespond @server.requests[0], 'GET', /^\/tests\/1\?_=\d+/, rawData

  describe "finds collection", ->
    rawData = '{"tests": [{"id": 1, "name": "test1"}, {"id": 2, "name": "test2"}]}'

    callback = sinon.spy (target) ->
      expect(target instanceof Joosy.Resource.RESTCollection).toEqual true
      expect(target.size()).toEqual 2
      expect(target.at(0) instanceof Fluffy).toEqual true

    it "without params", ->
      resource = Fluffy.find 'all', callback
      checkAndRespond @server.requests[0], 'GET', /^\/tests\?_=\d+/, rawData
      expect(callback.callCount).toEqual 1

    it "with from", ->
      resource = Fluffy.find 'all', {from: 'action'}, callback
      checkAndRespond @server.requests[0], 'GET', /^\/tests\/action\?_=\d+/, rawData
      expect(callback.callCount).toEqual 2

    it "with from and parent", ->
      resource = Fluffy.find 'all', {parent: FluffyParent.build(1), from: 'action'}, callback
      checkAndRespond @server.requests[0], 'GET', /^\/test_parents\/1\/tests\/action\?_=\d+/, rawData
      expect(callback.callCount).toEqual 3

    it "with params", ->
      resource = Fluffy.find 'all', params: {foo: 'bar'}, callback
      checkAndRespond @server.requests[0], 'GET', /^\/tests\?foo=bar&_=\d+/, rawData
      expect(callback.callCount).toEqual 4

  it "reloads resource", ->
    rawData  = '{"test": {"id": 1, "name": "test1"}}'
    resource = Fluffy.find 1
    callback = sinon.spy()

    checkAndRespond @server.requests[0], 'GET', /^\/tests\/1\?_=\d+/, rawData
    resource.bind 'changed', callback = sinon.spy()
    resource.reload()
    checkAndRespond @server.requests[1], 'GET', /^\/tests\/1\?_=\d+/, rawData
    expect(callback.callCount).toEqual 1

  describe "requests", ->
    rawData  = '{"foo": "bar"}'
    callback = sinon.spy (data) ->
      expect(data).toEqual {foo: 'bar'}

    describe "member", ->
      resource = Fluffy.build 1

      it "with get", ->
        resource.get {from: 'foo', params: {foo: 'bar'}}, callback
        checkAndRespond @server.requests[0], 'GET', /^\/tests\/1\/foo\?foo=bar&_=\d+/, rawData

      it "with post", ->
        resource.post callback
        checkAndRespond @server.requests[0], 'POST', /^\/tests\/1/, rawData

      it "with put", ->
        resource.put callback
        checkAndRespond @server.requests[0], 'PUT', /^\/tests\/1/, rawData

      it "with delete", ->
        resource.delete callback
        checkAndRespond @server.requests[0], 'DELETE', /^\/tests\/1/, rawData

    describe "collection", ->
      resource = Fluffy

      it "with get", ->
        resource.get {from: 'foo', params: {foo: 'bar'}}, callback
        checkAndRespond @server.requests[0], 'GET', /^\/tests\/foo\?foo=bar&_=\d+/, rawData

      it "with post", ->
        resource.post callback
        checkAndRespond @server.requests[0], 'POST', /^\/tests/, rawData

      it "with put", ->
        resource.put callback
        checkAndRespond @server.requests[0], 'PUT', /^\/tests/, rawData

      it "with delete", ->
        resource.delete callback
        checkAndRespond @server.requests[0], 'DELETE', /^\/tests/, rawData

