describe "Joosy.Modules.Filters", ->

  beforeEach ->
    class @TestFilters extends Joosy.Module
      @include Joosy.Modules.Filters
    @box = new @TestFilters()


  it "should inherit filters by copying them", ->
    class SubFiltersA extends @TestFilters
      @beforeLoad 'filter1'
      @afterLoad 'filter2'
      @afterUnload 'filter3'
    class SubFiltersB extends SubFiltersA
      @beforeLoad 'filter4'
      @afterLoad 'filter5'
      @afterUnload 'filter6'
    target = new SubFiltersB()
    expect(target.__beforeLoads).toEqual ['filter1', 'filter4']
    expect(target.__afterLoads).toEqual ['filter2', 'filter5']
    expect(target.__afterUnloads).toEqual ['filter3', 'filter6']
    target = new SubFiltersA()
    expect(target.__beforeLoads).toEqual ['filter1']
    expect(target.__afterLoads).toEqual ['filter2']
    expect(target.__afterUnloads).toEqual ['filter3']
    target = new @TestFilters()
    expect(target.__beforeLoads).toBeUndefined()
    expect(target.__afterLoads).toBeUndefined()
    expect(target.__afterUnloads).toBeUndefined()

  it "should run callbacks", ->
    callback = 0.upto(2).map -> sinon.spy()
    @box.constructor.beforeLoad callback[0]
    @box.constructor.afterLoad callback[1]
    @box.constructor.afterUnload callback[2]
    @box.__runBeforeLoads 1, 2
    @box.__runAfterLoads 1, 2
    @box.__runAfterUnloads 1, 2
    for i in 0.upto(2)
      expect(callback[i].callCount).toEqual 1
      expect(callback[i].alwaysCalledWithExactly 1, 2).toBeTruthy()

  it "should chain beforeLoad filters", ->
    callback = 0.upto(2).map -> sinon.stub()
    callback[0].returns true
    callback[1].returns false
    @box.constructor.beforeLoad(callback[i]) for i in 0.upto 2
    expect(@box.__runBeforeLoads()).toBeFalsy()
    expect(callback[0].callCount).toEqual 1
    expect(callback[1].callCount).toEqual 1
    expect(callback[2].callCount).toEqual 0

  it "should chain beforeLoad filters", ->
    callback = 0.upto(1).map -> sinon.stub()
    callback[0].returns true
    callback[1].returns true
    @box.constructor.beforeLoad(callback[i]) for i in 0.upto(1)
    expect(@box.__runBeforeLoads()).toBeTruthy()
    expect(callback[0].callCount).toEqual 1
    expect(callback[1].callCount).toEqual 1

  it "should accept callback names", ->
    @box.constructor.beforeLoad 'callback0'
    @box.constructor.afterLoad 'callback1'
    @box.constructor.afterUnload 'callback2'
    for i in 0.upto(2)
      @box['callback' + i] = sinon.spy()
    @box.__runBeforeLoads()
    @box.__runAfterLoads()
    @box.__runAfterUnloads()
    for i in 0.upto(2)
      expect(@box['callback' + i].callCount).toEqual 1