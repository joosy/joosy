describe "InlinePreloader", ->

  it "should load JS", ->
    expect(window.variable_assigned_on_load).toBeUndefined()
    callback = sinon.spy()
    
    runs ->
      InlinePreloader.load [['/spec/javascripts/support/assets/test.js']], 
        complete: callback
    
    waits 100
    
    runs ->
      expect(callback.callCount).toEqual 1
      expect(window.variable_assigned_on_load).toEqual 'yapyap'
      delete window.variable_assigned_on_load