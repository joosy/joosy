describe "Joosy.Resource.Generic", ->

  beforeEach ->
    @resource = Joosy.Resource.Generic.create @data =
      foo: 'bar'
      bar: 'baz'
      very:
        deep:
          value: 'boo!'


  it "should remember where it belongs", ->
    resource = new Joosy.Resource.Generic foo: 'bar'
    expect(resource.e).toEqual foo: 'bar'
    
  it "should produce magic function", ->
    expect(Object.isFunction @resource).toBeTruthy()
    expect(@resource.e).toEqual @data
    
  it "should get values", ->
    expect(@resource 'foo').toEqual 'bar'
    expect(@resource 'very.deep').toEqual value: 'boo!'
    expect(@resource 'very.deep.value').toEqual 'boo!'
    
  it "should set values", ->
    expect(@resource 'foo').toEqual 'bar'
    @resource 'foo', 'baz'
    expect(@resource 'foo').toEqual 'baz'

    expect(@resource 'very.deep').toEqual value: 'boo!'
    @resource 'very.deep', 'banana!'
    expect(@resource 'very.deep').toEqual 'banana!'
    
    @resource 'another.deep.value', 'banana strikes back'
    expect(@resource 'another.deep').toEqual value: 'banana strikes back'
    
  it "should handle lambdas in @source properly", ->
    class Fluffy extends Joosy.Resource.Generic
      @source (rumbas) -> "#{rumbas}!"

    expect(-> Fluffy.create {}).toThrow(new Error 'Fluffy> should be created through Fluffy.at()')

    clone = Fluffy.at('rumbas')    
    
    expect(-> clone.at 'kutuzka').toThrow(new Error 'clone> should be created directly (without `at\')')
    expect(clone.__source).toEqual 'rumbas!'
    
    expect(Joosy.Module.hasAncestor clone, Fluffy).toBeTruthy()
    # clone won't be instanceof Fluffy in IE
    #expect(clone.create({}) instanceof Fluffy).toBeTruthy()
    
  it "should trigger 'changed' right", ->
    callback = sinon.spy()
    @resource.bind 'changed', callback
    @resource 'foo', 'baz'
    @resource 'foo', 'baz2'
    
    expect(callback.callCount).toEqual(2)
    
  it "should properly handle the before filter", ->
    class R extends Joosy.Resource.Generic
      @beforeLoad (data) ->
        data ||= {}
        data.tested = true
        data
        
      resource = R.create()
      
      expect(resource 'tested').toBeTruthy()