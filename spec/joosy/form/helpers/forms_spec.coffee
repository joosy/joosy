describe "Joosy.Helpers.Form", ->
  class Test extends Joosy.Resources.REST
    @entity 'test'

  h = Joosy.Helpers.Application
  resource = Test.build id: 1

  describe "simple", ->
    for type in ['text', 'file', 'hidden', 'password']
      it "renders #{type}Field", ->
        expect(h["#{type}Field"] 'a', 'b', {a: 'b'}).toBeTag 'input', '', id: 'a_b', name: 'a[b]', a: 'b', type: type

    it "renders nested methods", ->
      expect(h.textField 'a', '[b]', {a: 'b'}).toBeTag 'input', '', id: 'a_b', name: 'a[b]', a: 'b', type: 'text'
      expect(h.textField 'a', '[b][c]', {a: 'b'}).toBeTag 'input', '', id: 'a_b_c', name: 'a[b][c]', a: 'b', type: 'text'

    it "renders label", ->
      expect(h.label 'a', 'b', 'test').toBeTag 'label', 'test', for: 'a_b'
      expect(h.label 'a', 'b', {a: 'b'}, 'test').toBeTag 'label', 'test', for: 'a_b', a: 'b'

    it "renders checkBox", ->
      tags = h.checkBox('a', 'b', {a: 'b'}).match(/<[^>]+>/g)

      expect(tags[0]).toBeTag 'input', '', value: '0', name: 'a[b]', type: 'hidden'
      expect(tags[1]).toBeTag 'input', '', value: '1', id: 'a_b', name: 'a[b]', type: 'checkbox', a: 'b'

    it "renders radioButton", ->
      expect(h.radioButton 'a', 'b', 'test', {a: 'b'}).toBeTag 'input', '', value: 'test', id: 'a_b_test', name: 'a[b]', type: 'radio', a: 'b'

    it "renders textArea", ->
      expect(h.textArea 'a', 'b', {a: 'b', value: 'foo'}).toBeTag 'textarea', 'foo', id: 'a_b', name: 'a[b]', a: 'b'

    it "renders select with options object", ->
      expect(tag = h.select 'a', 'b', {a: 'b', c: 'd'}, {a: 'b', value: 'c', includeBlank: true}).toBeTag 'select', false, id: 'a_b', name: 'a[b]', a: 'b'
      opts = $ $(tag).html()
      expect(opts.length).toEqual 3
      expect(opts[0]).toBeTag 'option', '', value: ''
      expect(opts[1]).toBeTag 'option', 'b', value: 'a'
      expect(opts[2]).toBeTag 'option', 'd', value: 'c', selected: 'selected'

    it "renders select with options array", ->
      expect(tag = h.select 'a', 'b', [['b', 'a'], ['d', 'c']], {a: 'b'}).toBeTag 'select', false, id: 'a_b', name: 'a[b]', a: 'b'
      opts = $ $(tag).html()
      expect(opts.length).toEqual 2
      expect(opts[0]).toBeTag 'option', 'b', value: 'a'
      expect(opts[1]).toBeTag 'option', 'd', value: 'c'

    it "renders formFor", ->
      callback = sinon.spy()
      expect(h.formFor resource, callback).toBeTag 'form', '', id: /.*/
      expect(callback.callCount).toEqual 1
      expect(callback.args[0][0].label?).toBeTruthy()

  describe "resource", ->
    callback = sinon.spy()
    h.formFor(resource, callback)
    form = callback.args[0][0]

    for type in ['text', 'file', 'hidden', 'password']
      it "renders #{type}Field", ->
        expect(form["#{type}Field"] 'b', {a: 'b'}).toBeTag 'input', '', id: 'test_b', name: 'test[b]', a: 'b', type: type

    it "renders label", ->
      expect(form.label 'b', 'test').toBeTag 'label', 'test', for: 'test_b'
      expect(form.label 'b', {a: 'b'}, 'test').toBeTag 'label', 'test', for: 'test_b', a: 'b'

    it "renders checkBox", ->
      tags = form.checkBox('b', {a: 'b'}).match(/<[^>]+>/g)

      expect(tags[0]).toBeTag 'input', '', value: '0', name: 'test[b]', type: 'hidden'
      expect(tags[1]).toBeTag 'input', '', value: '1', id: 'test_b', name: 'test[b]', type: 'checkbox', a: 'b'

    it "renders radioButton", ->
      expect(form.radioButton 'b', 'test', {a: 'b'}).toBeTag 'input', '', value: 'test', id: 'test_b_test', name: 'test[b]', type: 'radio', a: 'b'

    it "renders textArea", ->
      expect(form.textArea 'b', {a: 'b', value: 'foo'}).toBeTag 'textarea', 'foo', id: 'test_b', name: 'test[b]', a: 'b'

    it "renders select", ->
      expect(form.select 'b', {a: 'b', c: 'd'}, {a: 'b'}).toBeTag 'select', false, id: 'test_b', name: 'test[b]', a: 'b'

  describe "resource with extendIds", ->
    callback = sinon.spy()
    h.formFor(resource, extendIds: true, callback)
    form = callback.args[0][0]

    for type in ['text', 'file', 'hidden', 'password']
      it "renders #{type}Field", ->
        expect(form["#{type}Field"] 'b', {a: 'b'}).toBeTag 'input', '', id: 'test_1_b', name: 'test[b]', a: 'b', type: type

    it "renders label", ->
      expect(form.label 'b', 'test').toBeTag 'label', 'test', for: 'test_1_b'
      expect(form.label 'b', {a: 'b'}, 'test').toBeTag 'label', 'test', for: 'test_1_b', a: 'b'

    it "renders checkBox", ->
      tags = form.checkBox('b', {a: 'b'}).match(/<[^>]+>/g)

      expect(tags[0]).toBeTag 'input', '', value: '0', name: 'test[b]', type: 'hidden'
      expect(tags[1]).toBeTag 'input', '', value: '1', id: 'test_1_b', name: 'test[b]', type: 'checkbox', a: 'b'

    it "renders radioButton", ->
      expect(form.radioButton 'b', 'test', {a: 'b'}).toBeTag 'input', '', value: 'test', id: 'test_1_b_test', name: 'test[b]', type: 'radio', a: 'b'

    it "renders textArea", ->
      expect(form.textArea 'b', {a: 'b', value: 'foo'}).toBeTag 'textarea', 'foo', id: 'test_1_b', name: 'test[b]', a: 'b'

    it "renders select", ->
      expect(form.select 'b', {a: 'b', c: 'd'}, {a: 'b'}).toBeTag 'select', false, id: 'test_1_b', name: 'test[b]', a: 'b'
