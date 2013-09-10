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

  it "gets values", ->
    expect(@resource.get 'foo').toEqual 'bar'
    expect(@resource.get 'very.deep').toEqual value: 'boo!'
    expect(@resource.get 'very.deep.value').toEqual 'boo!'

  it "sets values", ->
    expect(@resource.get 'foo').toEqual 'bar'
    @resource.set 'foo', 'baz'
    expect(@resource.get 'foo').toEqual 'baz'

    expect(@resource.get 'very.deep').toEqual value: 'boo!'
    @resource.set 'very.deep', 'banana!'
    expect(@resource.get 'very.deep').toEqual 'banana!'

    @resource.set 'another.deep.value', 'banana strikes back'
    expect(@resource.get 'another.deep').toEqual value: 'banana strikes back'

  it "triggers 'changed' right", ->
    callback = sinon.spy()
    @resource.bind 'changed', callback
    @resource.set 'foo', 'baz'
    @resource.set 'foo', 'baz2'

    expect(callback.callCount).toEqual(2)

  it "handles the before filter", ->
    class R extends Model
      @beforeLoad (data) ->
        data ||= {}
        data.tested = true
        data

      resource = R.build()

      expect(resource.get 'tested').toBeTruthy()

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
    expect(resource.get('rumbaMumbas') instanceof Joosy.Resources.Array).toBeTruthy()
    expect(resource.get('rumbaMumbas')[0].get('foo')).toEqual 'bar'

    resource = S.build
      rumbaMumba: {foo: 'bar'}
    expect(resource.get('rumbaMumba') instanceof Model).toBeTruthy()
    expect(resource.get('rumbaMumba.foo')).toEqual 'bar'

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
    expect(resource.get('rumbaMumbas') instanceof Array).toBeTruthy()

  it "sets attributes", ->
    class Fluffy extends Model
      @attrAccessor 'foo', 'bar'

    fluffy = Fluffy.build foo: 'bar', bar: 'foo'

    expect(fluffy.foo()).toEqual 'bar'
    expect(fluffy.bar()).toEqual 'foo'

    fluffy.foo 'bar1'
    fluffy.bar 'foo1'

    expect(fluffy.foo()).toEqual 'bar1'
    expect(fluffy.bar()).toEqual 'foo1'