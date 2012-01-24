describe "Joosy.Page", ->

  beforeEach ->
    window.JST = 'app/templates/layouts/default': (->)
    class window.ApplicationLayout extends Joosy.Layout
    class @TestPage extends Joosy.Page


  describe "Not rendered page", ->

    beforeEach ->
      sinon.stub @TestPage.prototype, '__render'
      sinon.stub @TestPage.prototype, '__renderLayout'
      @box = new @TestPage()


    it "should have appropriate accessors", ->
      callback_names = ['fetch', 'beforePageRender', 'afterPageRender',
        'onPageRender', 'beforeLayoutRender', 'afterLayoutRender',
        'onLayoutRender']
      callback_names.each (func) =>
        @TestPage[func] 'callback'
        expect(@TestPage::['__' + func]).toEqual 'callback'

      @TestPage.scroll '#here'
      expect(@TestPage::__scrollElement).toEqual '#here'
      expect(@TestPage::__scrollSpeed).toEqual 500
      expect(@TestPage::__scrollMargin).toEqual 0

      @TestPage.scroll '#there', speed: 1000, margin: -5
      expect(@TestPage::__scrollElement).toEqual '#there'
      expect(@TestPage::__scrollSpeed).toEqual 1000
      expect(@TestPage::__scrollMargin).toEqual -5



