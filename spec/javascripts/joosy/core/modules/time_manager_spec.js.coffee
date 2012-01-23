describe "Joosy.Modules.TimeManager", ->

  beforeEach ->
    class @TestTimeManager extends Joosy.Module
      @include Joosy.Modules.TimeManager
    @box = new @TestTimeManager()


  it "should keep timeouts list", ->
    timer = @box.setTimeout 10000, ->
    expect(@box.__timeouts).toEqual [timer]
    window.clearTimeout timer

  it "should keep intervals list", ->
    timer = @box.setInterval 10000, ->
    expect(@box.__intervals).toEqual [timer]
    window.clearInterval timer

  it "should stop intervals and timeouts", ->
    callback = sinon.spy()
    runs -> 
      @box.setTimeout 10, callback
      @box.clearTime()
    waits(10)
    runs -> expect(callback.callCount).toEqual(0)
