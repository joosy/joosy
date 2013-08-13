describe "Joosy.Form", ->

  beforeEach ->
    Joosy.Resources.Base?.resetIdentity()

    @server = sinon.fakeServer.create()
    @seedGround()
    @nudeForm = "<form id='nude'><input name='test[foo]'/><input name='test[bar]'/><input name='test[bool]' type='checkbox' value='1'/><input name='test[set]' type='radio' value='qwe' /><input name='test[set]' type='radio' value='zxc' /></form>"
    @putForm  = "<form id='put' method='put'><input name='test[camel_baz]'/></form>"
    @moreForm = "<form id='more' method='put'><input name='test[ololo]'/></form>"
    @nestedForm = "<form id='nested'><input name='test[zee][capped][test]'/><input name='test[items_attributes][0][attr]'/><input name='test[items_attributes][1][attr]'/><input name='test[single_attributes][0][attr]'/></form>"
    @exactForm = "<form id='exact'><input name='test[EXact][MATCH]'/></form>"
    @arrayForm = "<form id='array'><input name='test[arr][1][0][1]'/></form>"

    @$ground.find('#sidebar').after(@nudeForm).after(@putForm).after(@moreForm).after(@nestedForm).after(@exactForm).after(@arrayForm)

    @nudeForm = $('#nude')
    @putForm  = $('#put')
    @moreForm = $('#more')
    @nestedForm = $('#nested')
    @exactForm = $('#exact')
    @arrayForm = $('#array')

    class Test extends Joosy.Resources.REST
      @entity 'test'
    @Test = Test

    @resource = Test.build
      arr: [null, [[null, 'here']]]
      id: 1,
      foo: 'foo',
      bar: 'bar'
      camelBaz: 'baz'
      bool: true
      set: 'zxc'
      zee:
        capped:
          test: 'test'
      EXact:
        MATCH: 'works'
      items: (new Joosy.Resources.RESTCollection(Test)).load([{attr: 'one'}, {attr: 'two'}])
      single: Test.build(attr: 'sin')

  afterEach ->
    @server.restore()

  describe "Initialization", ->

    beforeEach ->
      @spy = sinon.spy $.fn, 'ajaxForm'

    afterEach ->
      @spy.restore()

    it "should properly act with options", ->
      formWithProperties = new Joosy.Form @nudeForm, invalidationClass: 'fluffy'
      expect(formWithProperties.$container).toEqual @nudeForm
      expect(formWithProperties.invalidationClass).toEqual 'fluffy'
      expect(formWithProperties.$fields().length).toEqual 5

      expect(@spy.callCount).toEqual 1

    it "should properly act with callback", ->
      formWithCallback = new Joosy.Form @putForm, callback=sinon.spy()
      expect(formWithCallback.$container).toEqual @putForm
      expect(formWithCallback.invalidationClass).toEqual 'field_with_errors'
      expect(formWithCallback.success).toBe callback
      expect(formWithCallback.$fields().length).toEqual 2

      expect(@spy.callCount).toEqual 1

    it "should hijack form method if it differs from POST/GET", ->
      form   = new Joosy.Form @putForm, callback=sinon.spy()
      marker = @putForm.find "input[name=_method]"
      expect(@putForm.attr('method')?.toLowerCase()).toEqual 'post'
      expect(marker.attr 'type').toEqual 'hidden'
      expect(marker.attr 'value').toEqual 'put'

    it "should not stack _method inputs", ->
      form   = new Joosy.Form @putForm
      3.times =>
        form.fill @resource
      marker = @putForm.find "input[name=_method]"
      expect(marker.length).toEqual 1
      expect(marker.attr 'value').toEqual 'PUT'
      form.fill @Test
      marker = @putForm.find "input[name=_method]"
      expect(marker.length).toEqual 0

  describe "Filling", ->

    beforeEach ->
      @nudeForm   = new Joosy.Form @nudeForm
      @putForm    = new Joosy.Form @putForm
      @moreForm   = new Joosy.Form @moreForm
      @nestedForm = new Joosy.Form @nestedForm
      @exactForm  = new Joosy.Form @exactForm
      @arrayForm  = new Joosy.Form @arrayForm

    it "should fill form, set proper action and method and store resource", ->
      @nudeForm.fill @resource
      expect(@nudeForm.$fields()[0].value).toEqual 'foo'
      expect(@nudeForm.$fields()[1].value).toEqual 'bar'
      expect(@nudeForm.$fields()[2].checked).toEqual true
      expect(@nudeForm.$fields()[2].value).toEqual '1'
      expect(@nudeForm.$fields()[3].value).toEqual 'qwe'
      expect(@nudeForm.$fields()[3].checked).toEqual false
      expect(@nudeForm.$fields()[4].value).toEqual 'zxc'
      expect(@nudeForm.$fields()[4].checked).toEqual true
      expect(@nudeForm.$container.attr('method').toLowerCase()).toEqual 'post'
      expect(@nudeForm.$container.attr 'action').toEqual '/tests/1'
      expect(@nudeForm.__resource).toEqual @resource

    it "should fill form with camelized properties", ->
      @putForm.fill @resource
      expect(@putForm.$fields()[0].value).toEqual 'baz'
      expect(@putForm.$container.attr('method').toLowerCase()).toEqual 'post'
      expect(@putForm.$container.attr 'action').toEqual '/tests/1'

    it "should fill form with any properties", ->
      @exactForm.fill @resource
      expect(@exactForm.$fields()[0].value).toEqual 'works'

    it "should fill form with decorator", ->
      @moreForm.fill @resource,
        decorator: (e) ->
          e.ololo = e.camelBaz
          e
      expect(@moreForm.$fields()[0].value).toEqual 'baz'

    it "should fill form with extended action", ->
      @nudeForm.fill @resource,
        action: @resource.memberPath(from: 'calculate')
      expect(@nudeForm.$fields()[0].value).toEqual 'foo'
      expect(@nudeForm.$fields()[1].value).toEqual 'bar'
      expect(@nudeForm.$container.attr 'action').toEqual '/tests/1/calculate'

      resource = @Test.build 'someId'

      @nudeForm.fill resource,
        action: resource.memberPath(from: 'calculate')
      expect(@nudeForm.$container.attr 'action').toEqual '/tests/someId/calculate'

    it "should handle field name properly", ->
      expect(@nudeForm.concatFieldName 'resource', 'key').toEqual 'resource[key]'
      expect(@nudeForm.concatFieldName 'resource', 'key[key1]').toEqual 'resource[key][key1]'
      expect(@nudeForm.concatFieldName 'resource[key]', 'key1').toEqual 'resource[key][key1]'
      expect(@nudeForm.concatFieldName 'resource[key]', 'key1[key2]').toEqual 'resource[key][key1][key2]'
      expect(@nudeForm.concatFieldName 'resource[key]', '[key1][key2]').toEqual 'resource[key][key1][key2]'
      expect(@nudeForm.concatFieldName 'resource', 'key[]').toEqual 'resource[key][]'
      expect(@nudeForm.concatFieldName 'resource[]', 'key1').toEqual 'resource[][key1]'
      expect(@nudeForm.concatFieldName 'resource[]', 'key1[]').toEqual 'resource[][key1][]'
      expect(@nudeForm.concatFieldName 'resource[]', '[][]').toEqual 'resource[][][]'
      expect(@nudeForm.concatFieldName '[resource]', '[]').toEqual 'resource[]'
      expect(@nudeForm.concatFieldName '[resource]', '[key]').toEqual 'resource[key]'
      expect(@nudeForm.concatFieldName '[resource][key]', '[key1][key2]').toEqual 'resource[key][key1][key2]'
      expect(@nudeForm.concatFieldName '[][]', '[][]').toEqual '[][][]' # oops

    it "should fill nested attributes and resources", ->
      @nestedForm.fill @resource
      expect(@nestedForm.$fields()[0].value).toEqual 'test'
      expect(@nestedForm.$fields()[1].value).toEqual 'one'
      expect(@nestedForm.$fields()[2].value).toEqual 'two'
      expect(@nestedForm.$fields()[3].value).toEqual 'sin'

    it 'should fill array-like attributes', ->
      @arrayForm.fill @resource
      expect(@arrayForm.$fields()[0].value).toEqual 'here'

    it "should break cross-references", ->
      @resource('single')('trololo', @resource)
      @nestedForm.fill @resource
      # expect(you).toBeAlive(), lol

  describe 'Submit', ->

    beforeEach ->
      @xhr = sinon.useFakeXMLHttpRequest()
      @requests = []
      @xhr.onCreate = (xhr) =>
        @requests.push xhr

    afterEach ->
      @xhr.restore()
      delete @requests

    describe 'Global debouncing disabled', ->

      it 'should allow multiple submit', ->
        @nudeForm = new Joosy.Form @nudeForm
        3.times =>
          @nudeForm.$container.submit()
        expect(@requests.length).toEqual 3

      it 'should optionally prevent multiple submit', ->
        @nudeForm = new Joosy.Form @nudeForm, debounce: true
        [200, 404, 500].each (code) =>
          3.times =>
            @nudeForm.$container.submit()
          expect(@requests.length).toEqual 1
          @requests[0].respond(code, {}, '{}')
          expect(@requests.length).toEqual 1
          @requests = []

    describe 'Global debouncing enabled', ->

      beforeEach ->
        Joosy.Form.debounceForms = true

      afterEach ->
        Joosy.Form.debounceForms = false

      it 'should optionally allow multiple submit', ->
        @nudeForm = new Joosy.Form @nudeForm, debounce: false
        3.times =>
          @nudeForm.$container.submit()
        expect(@requests.length).toEqual 3

      it 'should prevent multiple submit', ->
        @nudeForm = new Joosy.Form @nudeForm
        3.times =>
          @nudeForm.$container.submit()
        expect(@requests.length).toEqual 1

  describe "Callbacks", ->

    beforeEach ->
      @nudeForm = new Joosy.Form @nudeForm, @spy=sinon.spy()
      @nudeForm.fill @resource
      @nudeForm.$container.submit()
      @target = @server.requests.last()

    it "should trigger 'success'", ->
      expect(@target.method).toEqual 'POST'
      expect(@target.url.endsWith '/tests/1').toEqual true
      @target.respond 200, 'Content-Type': 'application/json', '{"form": "works"}'
      expect(@spy.callCount).toEqual 1
      expect(@spy.args[0][0]).toEqual {form: 'works'}

    it "should fill class for invalidated fields by default", ->
      @target.respond 422, 'Content-Type': 'application/json', '{"foo": "error!"}'
      expect($(@nudeForm.$fields()[0]).attr 'class').toEqual 'field_with_errors'

    it "should fill class for invalidated fields by default", ->
      @target.respond 422, 'Content-Type': 'application/json', '{"errors":{"foo": "error!"}}'
      expect($(@nudeForm.$fields()[0]).attr 'class').toEqual 'field_with_errors'

    it "should trigger 'error' and complete default action if it returned true", ->
      @nudeForm.error = sinon.spy ->
        true
      @target.respond 422, 'Content-Type': 'application/json', '{"foo": "error!"}'
      expect($(@nudeForm.$fields()[0]).attr 'class').toEqual 'field_with_errors'
      expect(@nudeForm.error.callCount).toEqual 1
      expect(@nudeForm.error.args[0][0]).toEqual
        "foo": "error!"

    it "should trigger 'error' and skip default action if it returned false", ->
      @nudeForm.error = sinon.spy ->
        false
      @target.respond 422, 'Content-Type': 'application/json', '{"foo": "error!"}'
      expect($(@nudeForm.$fields()[0]).attr 'class').toNotEqual 'field_with_errors'
      expect(@nudeForm.error.callCount).toEqual 1

    it "should clear fields before another submit", ->
      @target.respond 422, 'Content-Type': 'application/json', '{"foo": "error!"}'
      expect($(@nudeForm.$fields()[0]).attr 'class').toEqual 'field_with_errors'
      @nudeForm.$container.submit()
      expect($(@nudeForm.$fields()[0]).attr 'class').toNotEqual 'field_with_errors'

    it "should trigger 'before' and do default action if it returns true", ->
      @target.respond 422, 'Content-Type': 'application/json', '{"foo": "error!"}'
      expect($(@nudeForm.$fields()[0]).attr 'class').toEqual 'field_with_errors'
      @nudeForm.before = sinon.spy ->
        true
      @nudeForm.$container.submit()
      expect($(@nudeForm.$fields()[0]).attr 'class').toNotEqual 'field_with_errors'
      expect(@nudeForm.before.callCount).toEqual 1

    it "should trigger 'before' and skip default action if it returns false", ->
      @target.respond 422, 'Content-Type': 'application/json', '{"foo": "error!"}'
      expect($(@nudeForm.$fields()[0]).attr 'class').toEqual 'field_with_errors'
      @nudeForm.before = sinon.spy ->
        false
      @nudeForm.$container.submit()
      expect($(@nudeForm.$fields()[0]).attr 'class').toEqual 'field_with_errors'
      expect(@nudeForm.before.callCount).toEqual 1

  describe "Error response handling", ->

    beforeEach ->
      @nudeForm = new Joosy.Form @nudeForm, @spy=sinon.spy()

    it "should prepare simple response", ->
      errors = {zombie: ['suck'], puppies: ['rock']}
      result = @nudeForm.__stringifyErrors(errors)

      expect(result).toEqual zombie: ['suck'], puppies: ['rock']

    it "should prepare inline response", ->
      errors = {"zombie.in1.subin1": ['suck'], "zombie.in2": ['rock']}
      result = @nudeForm.__stringifyErrors(errors)

      expect(result).toEqual {"zombie[in1][subin1]": ['suck'], "zombie[in2]": ['rock']}

    it "should prepare inline response with resource attached", ->
      @nudeForm.fill @resource
      errors = {"zombie.in1.subin1": ['suck'], "zombie.in2": ['rock']}
      result = @nudeForm.__stringifyErrors(errors)

      expect(result).toEqual {"test[zombie][in1][subin1]": ['suck'], "test[zombie][in2]": ['rock']}

    it "should prepare simple response with resource attached", ->
      @nudeForm.fill @resource
      errors = {zombie: ['suck'], puppies: ['rock']}
      result = @nudeForm.__stringifyErrors(errors)

      expect(result).toEqual { "test[zombie]": ['suck'], "test[puppies]": ['rock'] }

    it "should prepare complex response", ->
      @nudeForm.fill @resource
      errors = {fluffies: {zombie: {mumbas: ['ololo']}}}
      result = @nudeForm.__stringifyErrors(errors)

      expect(result).toEqual { "fluffies[zombie][mumbas]": ['ololo'] }

    it "should prepare nested response", ->
      @nestedForm = new Joosy.Form @nestedForm
      @nestedForm.fill @resource
      errors = {test: {items_attributes: [{attr: ['first']}, {attr: ['second']}]}}
      result = @nestedForm.__stringifyErrors(errors)
      expect(result).toEqual { "test[items_attributes][0][attr]": ['first'], "test[items_attributes][1][attr]": ['second'] }
