describe "Joosy.Helpers.Form", ->

  class Test extends Joosy.Resource.Generic
    @entity 'test'

  h = Joosy.Helpers.Application
  resource = Test.build 1

  describe "simple", ->

    it "renders label", ->
      expect(h.label 'a', 'b', {a: 'b'}, 'test').toEqual '<label a="b" for="a_b">test</label>'

    it "renders textField", ->
      expect(h.textField 'a', 'b', {a: 'b'}).toEqual '<input a="b" type="text" name="a[b]" id="a_b">'

    it "renders fileField", ->
      expect(h.fileField 'a', 'b', {a: 'b'}).toEqual '<input a="b" type="file" name="a[b]" id="a_b">'

    it "renders hiddenField", ->
      expect(h.hiddenField 'a', 'b', {a: 'b'}).toEqual '<input a="b" type="hidden" name="a[b]" id="a_b">'

    it "renders passwordField", ->
      expect(h.passwordField 'a', 'b', {a: 'b'}).toEqual '<input a="b" type="password" name="a[b]" id="a_b">'

    it "renders checkBox", ->
      expect(h.checkBox 'a', 'b', {a: 'b'}).toEqual '<input type="hidden" name="a[b]" id="a_b" value="0"><input a="b" type="checkbox" name="a[b]" id="a_b" value="1">'

    it "renders radioButton", ->
      expect(h.radioButton 'a', 'b', 'test', {a: 'b'}).toEqual '<input a="b" type="radio" value="test" name="a[b]" id="a_b">'

    it "renders textArea", ->
      expect(h.textArea 'a', 'b', {a: 'b', value: 'foo'}).toEqual '<textarea a="b" name="a[b]" id="a_b">foo</textarea>'

    it "renders formFor", -> 
      callback = sinon.spy()
      expect(h.formFor resource, callback).toMatch /<form id=".*"><\/form>/
      expect(callback.callCount).toEqual 1
      expect(callback.args[0][0].label?).toBeTruthy()

  describe "resource", ->
    callback = sinon.spy()
    h.formFor(resource, callback)
    form = callback.args[0][0]

    it "renders label", ->
      expect(form.label 'b', {a: 'b'}, 'test').toEqual '<label a="b" for="test_1_b">test</label>'

    it "renders textField", ->
      expect(form.textField 'b', {a: 'b'}).toEqual '<input a="b" type="text" name="test_1[b]" id="test_1_b">'

    it "renders fileField", ->
      expect(form.fileField 'b', {a: 'b'}).toEqual '<input a="b" type="file" name="test_1[b]" id="test_1_b">'

    it "renders hiddenField", ->
      expect(form.hiddenField 'b', {a: 'b'}).toEqual '<input a="b" type="hidden" name="test_1[b]" id="test_1_b">'

    it "renders passwordField", ->
      expect(form.passwordField 'b', {a: 'b'}).toEqual '<input a="b" type="password" name="test_1[b]" id="test_1_b">'

    it "renders checkBox", ->
      expect(form.checkBox 'b', {a: 'b'}).toEqual '<input type="hidden" name="test_1[b]" id="test_1_b" value="0"><input a="b" type="checkbox" name="test_1[b]" id="test_1_b" value="1">'

    it "renders radioButton", ->
      expect(form.radioButton 'b', 'test', {a: 'b'}).toEqual '<input a="b" type="radio" value="test" name="test_1[b]" id="test_1_b">'

    it "renders textArea", ->
      expect(form.textArea 'b', {a: 'b', value: 'foo'}).toEqual '<textarea a="b" name="test_1[b]" id="test_1_b">foo</textarea>'
