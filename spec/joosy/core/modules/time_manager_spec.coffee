describe "Joosy.Modules.TimeManager", ->

  beforeEach ->
    class @Manager extends Joosy.Module
      @include Joosy.Modules.TimeManager

    @manager = new @Manager

  it "stops intervals and timeouts", ->
    callback = sinon.spy()

    runs ->
      @manager.setTimeout 1, callback
      @manager.setInterval 1, callback
      @manager.__clearTime()

    waits 2

    runs ->
      expect(callback.callCount).toEqual 0
