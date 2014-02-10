describe "Joosy.Resources.REST", ->

  class FluffyInline extends Joosy.Resources.REST
    @entity 'fluffy_inline'

  class FluffyParent extends Joosy.Resources.REST
    @entity 'fluffy_parent'

  class Fluffy extends Joosy.Resources.REST
    @entity 'fluffy'
    @map 'fluffy_inlines', FluffyInline

  class Interpolated extends Joosy.Resources.REST
    @entity 'test'
    @source '/grand_parents/:grand_parent_id/parents/:parent_id/tests'

  Joosy.namespace 'Deeply.Nested', ->
    class @Entity extends Joosy.Resources.REST
      @entity 'entity'

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

    it 'makes a class whose instances get new source too', ->
      clone = @Test.at 'rumbas'
      expect(clone.build(id: 1).memberPath()).toEqual '/rumbas/tests/1'

    it 'accepts another resource instance', ->
      clone = @Test.at Fluffy.build(id: 1)
      expect(clone.collectionPath()).toEqual '/fluffies/1/tests'

    it 'accepts array', ->
      clone = @Test.at ['rumbas', Fluffy.build(id: 1), 'salsas']
      expect(clone.collectionPath()).toEqual '/rumbas/fluffies/1/salsas/tests'

    it 'accepts sequential attributes', ->
      clone = @Test.at 'rumbas', 'salsas', Fluffy.build(id: 1)
      expect(clone.collectionPath()).toEqual '/rumbas/salsas/fluffies/1/tests'

  describe '::at', ->
    beforeEach ->
      class @Test extends Joosy.Resources.REST
        @entity 'test'

    it 'returns base class instance', ->
      original = @Test.build id: 1, name: 'foobar', 'thing': 'baseclass'
      clone    = original.at 'rumbas'
      expect(clone instanceof @Test).toBeTruthy()
      expect(clone.data).toEqual original.data

    it 'accepts string', ->
      clone = @Test.build(id: 1).at('rumbas')
      expect(clone.memberPath()).toEqual '/rumbas/tests/1'

    it 'accepts another resource instance', ->
      clone = @Test.build(id: 1).at(Fluffy.build(id: 1))
      expect(clone.memberPath()).toEqual '/fluffies/1/tests/1'

    it 'accepts array', ->
      clone = @Test.build(id: 1).at ['rumbas', Fluffy.build(id: 1), 'salsas']
      expect(clone.memberPath()).toEqual '/rumbas/fluffies/1/salsas/tests/1'

    it 'accepts sequential attributes', ->
      clone = @Test.build(id: 1).at 'rumbas', 'salsas', Fluffy.build(id: 1)
      expect(clone.memberPath()).toEqual '/rumbas/salsas/fluffies/1/tests/1'

  describe '@memberPath', ->
    it 'builds member path', ->
      expect(Fluffy.memberPath 1).toEqual '/fluffies/1'

    it 'builds member path with action', ->
      expect(Fluffy.memberPath 1, action: 'test').toEqual '/fluffies/1/test'

    describe 'with interpolation', ->
      it 'builds member path', ->
        expect(Interpolated.memberPath([1,2,3])).toEqual '/grand_parents/1/parents/2/tests/3'

      it 'saves member path for single instance', ->
        item = Interpolated.find [1,2,3]
        checkAndRespond @server.requests[0], 'GET', /^\/grand_parents\/1\/parents\/2\/tests\/3\?_=\d+/, '{"test": {"id": 3}}'
        expect(item.memberPath()).toEqual '/grand_parents/1/parents/2/tests/3'

      it 'saves member path for instances collection', ->
        items = Interpolated.all [1,2]
        checkAndRespond @server.requests[0], 'GET', /^\/grand_parents\/1\/parents\/2\/tests\?_=\d+/, '{"tests": [{"test": {"id": 3}}]}'
        expect(items[0].memberPath()).toEqual '/grand_parents/1/parents/2/tests/3'

  describe '@collectionPath', ->
    it 'builds collection path', ->
      expect(Fluffy.collectionPath()).toEqual '/fluffies'

    it 'builds collection path with action', ->
      expect(Fluffy.collectionPath action: 'test').toEqual '/fluffies/test'

    describe 'with interpolation', ->
      it 'builds collection path', ->
        expect(Interpolated.collectionPath([1,2])).toEqual '/grand_parents/1/parents/2/tests'

    describe 'with namespace', ->
      it 'builds collection path', ->
        expect(Deeply.Nested.Entity.collectionPath([1,2])).toEqual '/deeply/nested/entities'

  describe '@find(:id)', ->
    rawData = '{"fluffy": {"id": 1, "name": "test1"}}'

    beforeEach ->
      @callback = sinon.spy (error, target, data) ->
        expect(target instanceof Fluffy).toEqual true
        expect(target.id()).toEqual 1
        expect(target.get 'name').toEqual 'test1'
        expect(data).toEqual $.parseJSON(rawData)

    it "gets item without params", ->
      resource = Fluffy.find 1, @callback
      checkAndRespond @server.requests[0], 'GET', /^\/fluffies\/1\?_=\d+/, rawData
      expect(@callback.callCount).toEqual 1

    it "gets item with action", ->
      resource = Fluffy.find 1, {action: 'action'}, @callback
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
      resource = Fluffy.find 1, (error, cbResource) ->
        expect(resource).toBe cbResource
      checkAndRespond @server.requests[0], 'GET', /^\/fluffies\/1\?_=\d+/, rawData

  describe '@all', ->
    rawData = '{"page": 42, "fluffies": [{"id": 1, "name": "test1"}, {"id": 2, "name": "test2"}]}'

    beforeEach ->
      @callback = sinon.spy (error, target, data) ->
        expect(target instanceof Joosy.Resources.RESTCollection).toEqual true
        expect(target.length).toEqual 2
        expect(target[0] instanceof Fluffy).toEqual true
        expect(data).toEqual $.parseJSON(rawData)

    it "gets collection without params", ->
      resource = Fluffy.all @callback
      checkAndRespond @server.requests[0], 'GET', /^\/fluffies\?_=\d+/, rawData
      expect(@callback.callCount).toEqual 1

    it "gets collection with action", ->
      resource = Fluffy.all {action: 'action'}, @callback
      checkAndRespond @server.requests[0], 'GET', /^\/fluffies\/action\?_=\d+/, rawData
      expect(@callback.callCount).toEqual 1

    it "gets collection with params", ->
      resource = Fluffy.all {params: {foo: 'bar'}}, @callback
      checkAndRespond @server.requests[0], 'GET', /^\/fluffies\?foo=bar&_=\d+/, rawData
      expect(@callback.callCount).toEqual 1

    it 'gets collection with url', ->
      resource = Fluffy.all url: '/some/custom/url', @callback
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

  it "reloads collection", ->
    rawData = '{"page": 42, "fluffies": [{"id": 1, "name": "test1"}, {"id": 2, "name": "test2"}]}'
    collection = undefined
    @callback = sinon.spy (error, target, data) ->
      expect(target instanceof Joosy.Resources.RESTCollection).toEqual true
      collection = target

    resource = Fluffy.all @callback
    checkAndRespond @server.requests[0], 'GET', /^\/fluffies\?_=\d+/, rawData
    expect(@callback.callCount).toEqual 1

    collection.reload(@callback)
    checkAndRespond @server.requests[0], 'GET', /^\/fluffies\?_=\d+/, rawData
    expect(@callback.callCount).toEqual 1

  describe "requests", ->
    rawData  = '{"foo": "bar"}'
    callback = sinon.spy (error, data) ->
      expect(data).toEqual {foo: 'bar'}

    describe "member", ->
      resource = Fluffy.build id: 1

      it "with get", ->
        resource.send 'get', {action: 'foo', params: {foo: 'bar'}}, callback
        checkAndRespond @server.requests[0], 'GET', /^\/fluffies\/1\/foo\?foo=bar&_=\d+/, rawData

      it "with post", ->
        resource.send 'post', callback
        checkAndRespond @server.requests[0], 'POST', /^\/fluffies\/1/, rawData

      it "with put", ->
        resource.send 'put', callback
        checkAndRespond @server.requests[0], 'PUT', /^\/fluffies\/1/, rawData

      it "with delete", ->
        resource.send 'delete', callback
        checkAndRespond @server.requests[0], 'DELETE', /^\/fluffies\/1/, rawData

    describe "collection", ->
      resource = Fluffy

      it "with get", ->
        resource.send 'get', {action: 'foo', params: {foo: 'bar'}}, callback
        checkAndRespond @server.requests[0], 'GET', /^\/fluffies\/foo\?foo=bar&_=\d+/, rawData

      it "with post", ->
        resource.send 'post', callback
        checkAndRespond @server.requests[0], 'POST', /^\/fluffies/, rawData

      it "with put", ->
        resource.send 'put', callback
        checkAndRespond @server.requests[0], 'PUT', /^\/fluffies/, rawData

      it "with delete", ->
        resource.send 'delete', callback
        checkAndRespond @server.requests[0], 'DELETE', /^\/fluffies/, rawData

    describe "save", ->
      beforeEach ->
        class @Resource extends Joosy.Resources.REST
          @entity 'resource'

          @beforeSave (data) ->
            data.tested = true
            data

      it "creates", ->
        resource = new @Resource(foo: 'bar')
        resource.save()

        checkAndRespond @server.requests[0], 'POST', /^\/resources/, rawData
        expect(@server.requests[0].requestBody).toEqual 'foo=bar&tested=true'

      it "updates", ->
        resource = new @Resource(id: 1, foo: 'bar')
        resource.save()

        checkAndRespond @server.requests[0], 'PUT', /^\/resources\/1/, rawData
        expect(@server.requests[0].requestBody).toEqual 'id=1&foo=bar&tested=true'