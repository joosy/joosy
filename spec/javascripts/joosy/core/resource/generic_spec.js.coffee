describe "Joosy.Resource.Generic", ->

  class TestInline extends Joosy.Resource.Generic
    @entity 'test_inline'

  class Test extends Joosy.Resource.REST
    @entity 'test'
    @map 'test_inlines', TestInline

  beforeEach ->
    @resource = Joosy.Resource.Generic.build @data =
      foo: 'bar'
      bar: 'baz'
      very:
        deep:
          value: 'boo!'

  it "has primary key", ->
    expect(Test::__primaryKey).toEqual 'id'

  it "remembers where it belongs", ->
    resource = new Joosy.Resource.Generic foo: 'bar'
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
    
  it "handles @at", ->
    class Fluffy extends Joosy.Resource.Generic

    clone = Fluffy.at('rumbas!')
    
    expect(clone.__source).toEqual 'rumbas!'
    expect(Joosy.Module.hasAncestor clone, Fluffy).toBeTruthy()
    # clone won't be instanceof Fluffy in IE
    #expect(clone.build({}) instanceof Fluffy).toBeTruthy()
    
  it "triggers 'changed' right", ->
    callback = sinon.spy()
    @resource.bind 'changed', callback
    @resource 'foo', 'baz'
    @resource 'foo', 'baz2'
    
    expect(callback.callCount).toEqual(2)
    
  it "handles the before filter", ->
    class R extends Joosy.Resource.Generic
      @beforeLoad (data) ->
        data ||= {}
        data.tested = true
        data
        
      resource = R.build()
      
      expect(resource 'tested').toBeTruthy()
      
  it "should map inlines", ->
    class RumbaMumba extends Joosy.Resource.Generic   
      @entity 'rumba_mumba'
 
    class R extends Joosy.Resource.Generic
      @map 'rumbaMumbas', RumbaMumba

    class S extends Joosy.Resource.Generic
      @map 'rumbaMumba', RumbaMumba

    resource = R.build
      rumbaMumbas: [
        {foo: 'bar'},
        {bar: 'baz'}
      ]
    expect(resource('rumbaMumbas') instanceof Joosy.Resource.Collection).toBeTruthy()
    expect(resource('rumbaMumbas').at(0)('foo')).toEqual 'bar'

    resource = S.build
      rumbaMumba: {foo: 'bar'}
    expect(resource('rumbaMumba') instanceof Joosy.Resource.Generic).toBeTruthy()
    expect(resource('rumbaMumba.foo')).toEqual 'bar'

  it "should use magic collections", ->
    class window.RumbaMumbasCollection extends Joosy.Resource.Collection
      
    class RumbaMumba extends Joosy.Resource.Generic
      @entity 'rumba_mumba'
    class R extends Joosy.Resource.Generic
      @map 'rumbaMumbas', RumbaMumba

    resource = R.build
      rumbaMumbas: [
        {foo: 'bar'},
        {bar: 'baz'}
      ]
    expect(resource('rumbaMumbas') instanceof RumbaMumbasCollection).toBeTruthy()
    expect(resource('rumbaMumbas').at(0)('foo')).toEqual 'bar'
    
    window.RumbaMumbasCollection = undefined
    
  it "should use manually set collections", ->
    class OloCollection extends Joosy.Resource.Collection

    class RumbaMumba extends Joosy.Resource.Generic
      @entity 'rumba_mumba'
      @collection OloCollection
    class R extends Joosy.Resource.Generic
      @map 'rumbaMumbas', RumbaMumba

    resource = R.build
      rumbaMumbas: [
        {foo: 'bar'},
        {bar: 'baz'}
      ]
    expect(resource('rumbaMumbas') instanceof OloCollection).toBeTruthy()
    expect(resource('rumbaMumbas').at(0)('foo')).toEqual 'bar'

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