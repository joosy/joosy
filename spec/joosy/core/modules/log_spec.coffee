describe "Joosy.Modules.Log", ->

  beforeEach ->
    class @Logger extends Joosy.Module
      @include Joosy.Modules.Log

    @logger = new @Logger
    @stub   = sinon.stub console, 'log'

  afterEach ->
    console.log.restore()

  it "should log into console", ->
    @logger.log 'message', 'appendix'
    expect(@stub.callCount).toEqual 1

  it "should log debug messages into console", ->
    Joosy.debug(true)
    @logger.debug 'debug message'
    Joosy.debug(false)
    @logger.debug 'unseen debug message'

    expect(@stub.callCount).toEqual 1