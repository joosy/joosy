describe "Joosy.Modules.Resources.Model", ->

  class Model extends Joosy.Resources.Hash
    @include Joosy.Modules.Resources.Model

  beforeEach ->
    @resource = Model.build @data =
      foo: 'bar'
      bar: 'baz'
      very:
        deep:
          value: 'boo!'

  it "has primary key", ->
    expect(Model::__primaryKey).toEqual 'id'

  it "remembers where it belongs", ->
    resource = Model.build foo: 'bar'
    expect(resource.data).toEqual foo: 'bar'

  it "produces magic function", ->
    expect(typeof(@resource) == 'function').toBeTruthy()
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
    class R extends Model
      @beforeLoad (data) ->
        data ||= {}
        data.tested = true
        data

      resource = R.build()

      expect(resource 'tested').toBeTruthy()

  it "should map inlines", ->
    class RumbaMumba extends Model
      @entity 'rumba_mumba'

    class R extends Model
      @map 'rumbaMumbas', RumbaMumba

    class S extends Model
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
    expect(resource('rumbaMumba') instanceof Model).toBeTruthy()
    expect(resource('rumbaMumba.foo')).toEqual 'bar'

  it "allows to override a collection", ->
    class Array extends Joosy.Resources.Array

    class RumbaMumba extends Model
      @entity 'rumba_mumba'
      @collection Array

    class R extends Model
      @map 'rumbaMumbas', RumbaMumba

    resource = R.build
      rumbaMumbas: [
        {foo: 'bar'},
        {bar: 'baz'}
      ]
    expect(resource('rumbaMumbas') instanceof Array).toBeTruthy()