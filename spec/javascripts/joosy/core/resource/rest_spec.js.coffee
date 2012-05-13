describe "Joosy.Resource.REST", ->

  class FluffyInline extends Joosy.Resource.REST
    @entity 'fluffy_inline'

  class FluffyParent extends Joosy.Resource.REST
    @entity 'fluffy_parent'

  class Fluffy extends Joosy.Resource.REST
    @entity 'fluffy'
    @map 'fluffy_inlines', FluffyInline

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

    expect(Fluffy.memberPath 1).toEqual '/fluffies/1'
    expect(Fluffy.memberPath 1, parent: parent).toEqual '/fluffy_parents/1/fluffies/1'
    expect(Fluffy.memberPath 1, parent: parent, from: 'test').toEqual '/fluffy_parents/1/fluffies/1/test'
    expect(Fluffy.memberPath 1, parent: parent, from: 'test', params: {foo: 'bar'}).toEqual '/fluffy_parents/1/fluffies/1/test'

  it "builds collection path", ->
    parent = FluffyParent.build 1

    expect(Fluffy.collectionPath()).toEqual '/fluffies'
    expect(Fluffy.collectionPath parent: parent).toEqual '/fluffy_parents/1/fluffies'
    expect(Fluffy.collectionPath parent: parent, from: 'test').toEqual '/fluffy_parents/1/fluffies/test'
    expect(Fluffy.collectionPath parent: parent, from: 'test', params: {foo: 'bar'}).toEqual '/fluffy_parents/1/fluffies/test'


  describe "finds resource", ->
    rawData = '{"fluffy": {"id": 1, "name": "test1"}}'

    callback = sinon.spy (target) ->
      expect(target instanceof Fluffy).toEqual true
      expect(target.id()).toEqual 1
      expect(target 'name').toEqual 'test1'

    it "without params", ->
      resource = Fluffy.find 1, callback
      checkAndRespond @server.requests[0], 'GET', /^\/fluffies\/1\?_=\d+/, rawData
      expect(callback.callCount).toEqual 1

    it "with from", ->
      resource = Fluffy.find 1, {from: 'action'}, callback
      checkAndRespond @server.requests[0], 'GET', /^\/fluffies\/1\/action\?_=\d+/, rawData
      expect(callback.callCount).toEqual 2

    it "with from and parent", ->
      resource = Fluffy.find 1, {parent: FluffyParent.build(1), from: 'action'}, callback
      checkAndRespond @server.requests[0], 'GET', /^\/fluffy_parents\/1\/fluffies\/1\/action\?_=\d+/, rawData
      expect(callback.callCount).toEqual 3

    it "with params", ->
      resource = Fluffy.find 1, params: {foo: 'bar'}, callback
      checkAndRespond @server.requests[0], 'GET', /^\/fluffies\/1\?foo=bar&_=\d+/, rawData
      expect(callback.callCount).toEqual 4

    it "with direct assignation", ->
      resource = Fluffy.find 1, ->
        expect(resource instanceof Fluffy).toEqual true
        expect(resource.id()).toEqual 1
        expect(resource 'name').toEqual 'test1'

      checkAndRespond @server.requests[0], 'GET', /^\/fluffies\/1\?_=\d+/, rawData

  describe "finds collection", ->
    rawData = '{"fluffies": [{"id": 1, "name": "test1"}, {"id": 2, "name": "test2"}]}'

    callback = sinon.spy (target) ->
      expect(target instanceof Joosy.Resource.RESTCollection).toEqual true
      expect(target.size()).toEqual 2
      expect(target.at(0) instanceof Fluffy).toEqual true

    it "without params", ->
      resource = Fluffy.find 'all', callback
      checkAndRespond @server.requests[0], 'GET', /^\/fluffies\?_=\d+/, rawData
      expect(callback.callCount).toEqual 1

    it "with from", ->
      resource = Fluffy.find 'all', {from: 'action'}, callback
      checkAndRespond @server.requests[0], 'GET', /^\/fluffies\/action\?_=\d+/, rawData
      expect(callback.callCount).toEqual 2

    it "with from and parent", ->
      resource = Fluffy.find 'all', {parent: FluffyParent.build(1), from: 'action'}, callback
      checkAndRespond @server.requests[0], 'GET', /^\/fluffy_parents\/1\/fluffies\/action\?_=\d+/, rawData
      expect(callback.callCount).toEqual 3

    it "with params", ->
      resource = Fluffy.find 'all', params: {foo: 'bar'}, callback
      checkAndRespond @server.requests[0], 'GET', /^\/fluffies\?foo=bar&_=\d+/, rawData
      expect(callback.callCount).toEqual 4

  it "reloads resource", ->
    rawData  = '{"fluffy": {"id": 1, "name": "test1"}}'
    resource = Fluffy.find 1
    callback = sinon.spy()

    checkAndRespond @server.requests[0], 'GET', /^\/fluffies\/1\?_=\d+/, rawData
    resource.bind 'changed', callback = sinon.spy()
    resource.reload()
    checkAndRespond @server.requests[1], 'GET', /^\/fluffies\/1\?_=\d+/, rawData
    expect(callback.callCount).toEqual 1

  describe "requests", ->
    rawData  = '{"foo": "bar"}'
    callback = sinon.spy (data) ->
      expect(data).toEqual {foo: 'bar'}

    describe "member", ->
      resource = Fluffy.build 1

      it "with get", ->
        resource.get {from: 'foo', params: {foo: 'bar'}}, callback
        checkAndRespond @server.requests[0], 'GET', /^\/fluffies\/1\/foo\?foo=bar&_=\d+/, rawData

      it "with post", ->
        resource.post callback
        checkAndRespond @server.requests[0], 'POST', /^\/fluffies\/1/, rawData

      it "with put", ->
        resource.put callback
        checkAndRespond @server.requests[0], 'PUT', /^\/fluffies\/1/, rawData

      it "with delete", ->
        resource.delete callback
        checkAndRespond @server.requests[0], 'DELETE', /^\/fluffies\/1/, rawData

    describe "collection", ->
      resource = Fluffy

      it "with get", ->
        resource.get {from: 'foo', params: {foo: 'bar'}}, callback
        checkAndRespond @server.requests[0], 'GET', /^\/fluffies\/foo\?foo=bar&_=\d+/, rawData

      it "with post", ->
        resource.post callback
        checkAndRespond @server.requests[0], 'POST', /^\/fluffies/, rawData

      it "with put", ->
        resource.put callback
        checkAndRespond @server.requests[0], 'PUT', /^\/fluffies/, rawData

      it "with delete", ->
        resource.delete callback
        checkAndRespond @server.requests[0], 'DELETE', /^\/fluffies/, rawData

  describe "identity map", ->

    it "handles finds", ->
      inline = FluffyInline.build(1)
      root   = Fluffy.find 1

      inline.bind 'changed', callback = sinon.spy()

      checkAndRespond @server.requests[0], 'GET', /^\/fluffies\/1\?_=\d+/,
        '{"id": 1, "fluffy_inlines": [{"id": 1, "name": 1}, {"id": 2, "name": 2}]}'

      expect(inline 'name').toEqual 1
      expect(callback.callCount).toEqual 1
