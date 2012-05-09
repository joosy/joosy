describe "Joosy.Resource.Collection", ->

  class Test extends Joosy.Resource.Generic
    @entity 'test'

  data = '[{"id": 1, "name": "test1"}, {"id": 2, "name": "test2"}]'

  checkData = (collection) ->
    expect(collection.data.length).toEqual 2
    expect(collection.data[0].constructor == Test).toBeTruthy()
    expect(collection.data[0].e.name).toEqual 'test1'

  beforeEach ->
    @collection = new Joosy.Resource.Collection(Test)

  it "should initialize", ->
    expect(@collection.model).toEqual Test
    expect(@collection.data).toEqual []

  it "should modelize", ->
    result = @collection.modelize $.parseJSON(data)
    expect(result[0].constructor == Test).toBeTruthy()
    expect(result[0].e.name).toEqual 'test1'

  it "should load", ->
    @collection.load $.parseJSON(data)
    checkData @collection
  
  it "should trigger changes", ->
    @collection.bind 'changed', callback = sinon.spy()
    @collection.load $.parseJSON(data)
    expect(callback.callCount).toEqual 1

  it "should not trigger changes", ->
    @collection.bind 'changed', callback = sinon.spy()
    @collection.load $.parseJSON(data), false
    expect(callback.callCount).toEqual 0

  it "should properly handle the before filter", ->
    class RC extends Joosy.Resource.Collection
      @beforeLoad (data) ->
        data.each (entry, i) ->
          data[i].tested = true
        data
      
    collection = new RC(Test)
    collection.load $.parseJSON(data)

    expect(collection.at(0)('tested')).toBeTruthy()

  it "should remove item from collection", ->
    @collection.load $.parseJSON(data)
    @collection.bind 'changed', callback = sinon.spy()
    @collection.remove @collection.data[1]
    expect(@collection.data.length).toEqual 1
    @collection.remove 0
    expect(@collection.data.length).toEqual 0
    expect(callback.callCount).toEqual 2

  it "should silently remove item from collection", ->
    @collection.load $.parseJSON(data)
    @collection.bind 'changed', callback = sinon.spy()
    @collection.remove @collection.data[1], false
    expect(@collection.data.length).toEqual 1
    @collection.remove 0, false
    expect(@collection.data.length).toEqual 0
    expect(callback.callCount).toEqual 0
    
  it "should add item from collection", ->
    @collection.load $.parseJSON(data)
    @collection.bind 'changed', callback = sinon.spy()
    @collection.add new Test {'rocking': 'mocking'}
    expect(@collection.data.length).toEqual 3
    expect(@collection.at(2).e).toEqual {'rocking': 'mocking'}
    @collection.add new Test({'rocking': 'mocking'}), 1
    expect(@collection.data.length).toEqual 4
    expect(@collection.at(1).e).toEqual {'rocking': 'mocking'}
    expect(@collection.at(3).e).toEqual {'rocking': 'mocking'}
    
  it "should find items by id", ->
    @collection.load $.parseJSON(data)
    
    expect(@collection.findById 1).toEqual @collection.data[0]
    expect(@collection.findById 2).toEqual @collection.data[1]