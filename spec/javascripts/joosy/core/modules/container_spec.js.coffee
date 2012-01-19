describe 'Joosy.Modules.Container', ->

  class TestContainer extends Joosy.Module
    @include Joosy.Modules.Container

  beforeEach ->
    @container = new TestContainer()
    @ground.html('<div id="application" />')
    @container.container = $('#application', @ground)

  it 'should setup property per declared element', ->
    @container.container.html('<div id="test" />')
    @container.elements = {testElem: '#test'}
    @container.refreshElements()
    expect(@container.testElem.get(0))
      .toBe($('#test', @container.container).get(0))
