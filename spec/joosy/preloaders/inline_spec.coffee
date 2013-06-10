describe "InlinePreloader", ->

  it "should load JS", ->
    window.variable_assigned_on_load = undefined
    callback = sinon.spy()

    runs ->
      InlinePreloader.load [['/spec/support/test.js']],
        complete: callback

    waits 100

    runs ->
      expect(callback.callCount).toEqual 1
      expect(window.variable_assigned_on_load).toEqual 'yapyap'
      window.variable_assigned_on_load = undefined
