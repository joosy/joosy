describe "Joosy.Resources.REST", ->

  beforeEach ->
    Joosy.Resources.Base?.resetIdentity()

  class FluffyInline extends Joosy.Resources.REST
    @entity 'fluffy_inline'

  class FluffyParent extends Joosy.Resources.REST
    @entity 'fluffy_parent'

  class Fluffy extends Joosy.Resources.REST
    @entity 'fluffy'
    @map 'fluffy_inlines', FluffyInline

  Joosy.namespace 'Animal', ->
    class @Cat extends Joosy.Resources.REST
      @entity 'cat'

  beforeEach ->
    @server = sinon.fakeServer.create()

  afterEach ->
    @server.restore()

  checkAndRespond = (target, method, url, data) ->
    expect(target.method).toEqual method
    expect(target.url).toMatch url
    target.respond 200, 'Content-Type': 'application/json', data

  describe '@at', ->
    # clone won't be instanceof Fluffy in IE
    #expect(clone.build({}) instanceof Fluffy).toBeTruthy()

    beforeEach ->
      class @Test extends Joosy.Resources.REST
        @entity 'test'

    it 'returns base class child', ->
      clone = @Test.at 'rumbas'
      expect(Joosy.Module.hasAncestor(clone, @Test)).toBeTruthy()

    it 'accepts string', ->
      clone = @Test.at 'rumbas'
      expect(clone.collectionPath()).toEqual '/rumbas/tests'

    it 'accepts another resource instance', ->
      clone = @Test.at Fluffy.build(1)
      expect(clone.collectionPath()).toEqual '/fluffies/1/tests'

    it 'accepts array', ->
      clone = @Test.at ['rumbas', Fluffy.build(1), 'salsas']
      expect(clone.collectionPath()).toEqual '/rumbas/fluffies/1/salsas/tests'

    it 'accepts sequential attributes', ->
      clone = @Test.at 'rumbas', 'salsas', Fluffy.build(1)
      expect(clone.collectionPath()).toEqual '/rumbas/salsas/fluffies/1/tests'

  describe '::at', ->
    beforeEach ->
      class @Test extends Joosy.Resources.REST
        @entity 'test'

    it 'returns base class instance', ->
      original = @Test.build id: 1, name: 'foobar'
      clone    = original.at 'rumbas'
      expect(clone instanceof @Test).toBeTruthy()
      expect(clone.data).toEqual original.data

    it 'accepts string', ->
      clone = @Test.build(1).at('rumbas')
      expect(clone.memberPath()).toEqual '/rumbas/tests/1'

    it 'accepts another resource instance', ->
      clone = @Test.build(1).at(Fluffy.build(1))
      expect(clone.memberPath()).toEqual '/fluffies/1/tests/1'

    it 'accepts array', ->
      clone = @Test.build(1).at ['rumbas', Fluffy.build(1), 'salsas']
      expect(clone.memberPath()).toEqual '/rumbas/fluffies/1/salsas/tests/1'

    it 'accepts sequential attributes', ->
      clone = @Test.build(1).at 'rumbas', 'salsas', Fluffy.build(1)
      expect(clone.memberPath()).toEqual '/rumbas/salsas/fluffies/1/tests/1'

  describe '@memberPath', ->
    it 'builds member path', ->
      expect(Fluffy.memberPath 1).toEqual '/fluffies/1'

    it 'builds member path with from', ->
      expect(Fluffy.memberPath 1, from: 'test').toEqual '/fluffies/1/test'


  describe '@collectionPath', ->
    it 'builds collection path', ->
      expect(Fluffy.collectionPath()).toEqual '/fluffies'

    it 'builds collection path with from', ->
      expect(Fluffy.collectionPath from: 'test').toEqual '/fluffies/test'

  describe '@find(:id)', ->
    rawData = '{"fluffy": {"id": 1, "name": "test1"}}'

    beforeEach ->
      @callback = sinon.spy (target, data) ->
        expect(target instanceof Fluffy).toEqual true
        expect(target.id()).toEqual 1
        expect(target 'name').toEqual 'test1'
        expect(data).toEqual $.parseJSON(rawData)

    it "gets item without params", ->
      resource = Fluffy.find 1, @callback
      checkAndRespond @server.requests[0], 'GET', /^\/fluffies\/1\?_=\d+/, rawData
      expect(@callback.callCount).toEqual 1

    it "gets item with from", ->
      resource = Fluffy.find 1, {from: 'action'}, @callback
      checkAndRespond @server.requests[0], 'GET', /^\/fluffies\/1\/action\?_=\d+/, rawData
      expect(@callback.callCount).toEqual 1

    it "gets item with params", ->
      resource = Fluffy.find 1, params: {foo: 'bar'}, @callback
      checkAndRespond @server.requests[0], 'GET', /^\/fluffies\/1\?foo=bar&_=\d+/, rawData
      expect(@callback.callCount).toEqual 1

    it "gets item with url", ->
      resource = Fluffy.find 1, url: '/some/custom/url', @callback
      checkAndRespond @server.requests[0], 'GET', /^\/some\/custom\/url\?_=\d+/, rawData
      expect(@callback.callCount).toEqual 1

    it "gets item with direct assignation", ->
      resource = Fluffy.find 1, (cbResource) ->
        expect(resource).toBe cbResource
      checkAndRespond @server.requests[0], 'GET', /^\/fluffies\/1\?_=\d+/, rawData

  describe "@find('all')", ->
    rawData = '{"page": 42, "fluffies": [{"id": 1, "name": "test1"}, {"id": 2, "name": "test2"}]}'

    beforeEach ->
      @callback = sinon.spy (target, data) ->
        expect(target instanceof Joosy.Resources.RESTCollection).toEqual true
        expect(target.size()).toEqual 2
        expect(target.at(0) instanceof Fluffy).toEqual true
        expect(data).toEqual $.parseJSON(rawData)

    it "gets collection without params", ->
      resource = Fluffy.find 'all', @callback
      checkAndRespond @server.requests[0], 'GET', /^\/fluffies\?_=\d+/, rawData
      expect(@callback.callCount).toEqual 1

    it "gets collection with from", ->
      resource = Fluffy.find 'all', {from: 'action'}, @callback
      checkAndRespond @server.requests[0], 'GET', /^\/fluffies\/action\?_=\d+/, rawData
      expect(@callback.callCount).toEqual 1

    it "gets collection with params", ->
      resource = Fluffy.find 'all', params: {foo: 'bar'}, @callback
      checkAndRespond @server.requests[0], 'GET', /^\/fluffies\?foo=bar&_=\d+/, rawData
      expect(@callback.callCount).toEqual 1

    it 'gets collection with url', ->
      resource = Fluffy.find 'all', url: '/some/custom/url', @callback
      checkAndRespond @server.requests[0], 'GET', /^\/some\/custom\/url\?_=\d+/, rawData
      expect(@callback.callCount).toEqual 1


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
