describe "Joosy.Helpers.Form", ->
  beforeEach ->
    @addMatchers toBeTag: (tagName, content, attrs) ->
      @message = =>
        "Expected #{@actual} to be a tag #{tagName} with attributes #{JSON.stringify attrs} and content #{content}"

      tag = $ @actual
      flag = true

      flag = flag && tag.length == 1
      flag = flag && tag[0].nodeName == tagName.toUpperCase()
      flag = flag && tag.html() == content

      for name, val of attrs
        flag = flag && tag.attr(name) == val

      flag = flag && tag[0].attributes.length == Object.keys(attrs).length

      flag

  class Test extends Joosy.Resource.Generic
    @entity 'test'

  h = Joosy.Helpers.Application
  resource = Test.build 1

  describe "simple", ->
    ['text', 'file', 'hidden', 'password'].each (type) =>
      it "renders #{type}Field", ->
        expect(h["#{type}Field"] 'a', 'b', {a: 'b'}).toBeTag 'input', '', id: 'a_b', name: 'a[b]', a: 'b', type: type

    it "renders nested methods", ->
      expect(h.textField 'a', '[b]', {a: 'b'}).toBeTag 'input', '', id: 'a_b', name: 'a[b]', a: 'b', type: 'text'
      expect(h.textField 'a', '[b][c]', {a: 'b'}).toBeTag 'input', '', id: 'a_b_c', name: 'a[b][c]', a: 'b', type: 'text'

    it "renders label", ->
      expect(h.label 'a', 'b', {a: 'b'}, 'test').toBeTag 'label', 'test', for: 'a_b', a: 'b'

    it "renders checkBox", ->
      tags = h.checkBox('a', 'b', {a: 'b'}).match(/<[^>]+>/g)

      expect(tags[0]).toBeTag 'input', '', value: '0', id: 'a_b', name: 'a[b]', type: 'hidden'
      expect(tags[1]).toBeTag 'input', '', value: '1', id: 'a_b', name: 'a[b]', type: 'checkbox', a: 'b'

    it "renders radioButton", ->
      expect(h.radioButton 'a', 'b', 'test', {a: 'b'}).toBeTag 'input', '', value: 'test', id: 'a_b', name: 'a[b]', type: 'radio', a: 'b'

    it "renders textArea", ->
      expect(h.textArea 'a', 'b', {a: 'b', value: 'foo'}).toBeTag 'textarea', 'foo', id: 'a_b', name: 'a[b]', a: 'b'

    it "renders formFor", ->
      callback = sinon.spy()
      expect(h.formFor resource, callback).toMatch /<form id=".*"><\/form>/
      expect(callback.callCount).toEqual 1
      expect(callback.args[0][0].label?).toBeTruthy()

  describe "resource", ->
    callback = sinon.spy()
    h.formFor(resource, callback)
    form = callback.args[0][0]

    ['text', 'file', 'hidden', 'password'].each (type) =>
      it "renders #{type}Field", ->
        expect(form["#{type}Field"] 'b', {a: 'b'}).toBeTag 'input', '', id: 'test_b', name: 'test[b]', a: 'b', type: type

    it "renders label", ->
      expect(form.label 'b', {a: 'b'}, 'test').toBeTag 'label', 'test', for: 'test_b', a: 'b'

    it "renders checkBox", ->
      tags = form.checkBox('b', {a: 'b'}).match(/<[^>]+>/g)

      expect(tags[0]).toBeTag 'input', '', value: '0', id: 'test_b', name: 'test[b]', type: 'hidden'
      expect(tags[1]).toBeTag 'input', '', value: '1', id: 'test_b', name: 'test[b]', type: 'checkbox', a: 'b'

    it "renders radioButton", ->
      expect(form.radioButton 'b', 'test', {a: 'b'}).toBeTag 'input', '', value: 'test', id: 'test_b', name: 'test[b]', type: 'radio', a: 'b'

    it "renders textArea", ->
      expect(form.textArea 'b', {a: 'b', value: 'foo'}).toBeTag 'textarea', 'foo', id: 'test_b', name: 'test[b]', a: 'b'

  describe "resource with extendIds", ->
    callback = sinon.spy()
    h.formFor(resource, extendIds: true, callback)
    form = callback.args[0][0]

    ['text', 'file', 'hidden', 'password'].each (type) =>
      it "renders #{type}Field", ->
        expect(form["#{type}Field"] 'b', {a: 'b'}).toBeTag 'input', '', id: 'test_1_b', name: 'test[b]', a: 'b', type: type

    it "renders label", ->
      expect(form.label 'b', {a: 'b'}, 'test').toBeTag 'label', 'test', for: 'test_1_b', a: 'b'

    it "renders checkBox", ->
      tags = form.checkBox('b', {a: 'b'}).match(/<[^>]+>/g)

      expect(tags[0]).toBeTag 'input', '', value: '0', id: 'test_1_b', name: 'test[b]', type: 'hidden'
      expect(tags[1]).toBeTag 'input', '', value: '1', id: 'test_1_b', name: 'test[b]', type: 'checkbox', a: 'b'

    it "renders radioButton", ->
      expect(form.radioButton 'b', 'test', {a: 'b'}).toBeTag 'input', '', value: 'test', id: 'test_1_b', name: 'test[b]', type: 'radio', a: 'b'

    it "renders textArea", ->
      expect(form.textArea 'b', {a: 'b', value: 'foo'}).toBeTag 'textarea', 'foo', id: 'test_1_b', name: 'test[b]', a: 'b'