describe "Joosy.Modules.Log", ->

  beforeEach ->
    class @TestLog extends Joosy.Module
      @include Joosy.Modules.Log
    @box = new @TestLog()

  it "should log into console", ->
    @box.log 'message', 'appendix'

  it "should log debug messages into console", ->
    Joosy.Application.debug = true
    @box.debug 'debug message'
    Joosy.Application.debug = false
    @box.debug 'unseen debug message'
