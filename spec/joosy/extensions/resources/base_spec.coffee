describe "Joosy.Resources.Base", ->

  beforeEach ->
    Joosy.Resources.Base?.resetIdentity()

  class TestInline extends Joosy.Resources.Base
    @entity 'test_inline'

  class Test extends Joosy.Resources.REST
    @entity 'test'
    @map 'test_inlines', TestInline

  class TestNode extends Joosy.Resources.Base
    @entity 'test_node'
    @map 'children', TestNode
    @map 'parent', TestNode

  beforeEach ->
    @resource = Joosy.Resources.Base.build @data =
      foo: 'bar'
      bar: 'baz'
      very:
        deep:
          value: 'boo!'

  it "has primary key", ->
    expect(Test::__primaryKey).toEqual 'id'

  it "remembers where it belongs", ->
    resource = new Joosy.Resources.Base foo: 'bar'
    expect(resource.data).toEqual foo: 'bar'

  it "produces magic function", ->
    expect(Object.isFunction @resource).toBeTruthy()
    expect(@resource.data).toEqual @data

  it "gets values", ->
    expect(@resource 'foo').toEqual 'bar'
    expect(@resource 'very.deep').toEqual value: 'boo!'
    expect(@resource 'very.deep.value').toEqual 'boo!'

  it "sets values", ->
    expect(@resource 'foo').toEqual 'bar'
    @resource 'foo', 'baz'
    expect(@resource 'foo').toEqual 'baz'

    expect(@resource 'very.deep').toEqual value: 'boo!'
    @resource 'very.deep', 'banana!'
    expect(@resource 'very.deep').toEqual 'banana!'

    @resource 'another.deep.value', 'banana strikes back'
    expect(@resource 'another.deep').toEqual value: 'banana strikes back'

  it "triggers 'changed' right", ->
    callback = sinon.spy()
    @resource.bind 'changed', callback
    @resource 'foo', 'baz'
    @resource 'foo', 'baz2'

    expect(callback.callCount).toEqual(2)

  it "handles the before filter", ->
    class R extends Joosy.Resources.Base
      @beforeLoad (data) ->
        data ||= {}
        data.tested = true
        data

      resource = R.build()

      expect(resource 'tested').toBeTruthy()

  it "should map inlines", ->
    class RumbaMumba extends Joosy.Resources.Base
      @entity 'rumba_mumba'

    class R extends Joosy.Resources.Base
      @map 'rumbaMumbas', RumbaMumba

    class S extends Joosy.Resources.Base
      @map 'rumbaMumba', RumbaMumba

    resource = R.build
      rumbaMumbas: [
        {foo: 'bar'},
        {bar: 'baz'}
      ]
    expect(resource('rumbaMumbas') instanceof Joosy.Resources.Array).toBeTruthy()
    expect(resource('rumbaMumbas')[0]('foo')).toEqual 'bar'

    resource = S.build
      rumbaMumba: {foo: 'bar'}
    expect(resource('rumbaMumba') instanceof Joosy.Resources.Base).toBeTruthy()
    expect(resource('rumbaMumba.foo')).toEqual 'bar'

  describe "identity map", ->
    it "handles builds", ->
      foo = Test.build 1
      bar = Test.build 1

      expect(foo).toEqual bar

    it "handles maps", ->
      inline = TestInline.build(1)
      root   = Test.build
        id: 1
        test_inlines: [{id: 1}, {id: 2}]

      inline('foo', 'bar')

      expect(root('test_inlines').at(0)('foo')).toEqual 'bar'

    it "handles nested bi-directional reference", ->
      biDirectionTestNode = TestNode.build
        id: 1
        yolo: true
        children: [{id: 2, parent: {id: 1, yolo: true}}]

      expect(biDirectionTestNode).toEqual(biDirectionTestNode('children').at(0)('parent'))
