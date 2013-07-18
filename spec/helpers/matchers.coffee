beforeEach ->
  @addMatchers
    toBeSequenced: ->
      if !Object.isArray(@actual) || @actual.length == 0
        @message = -> 'toBeSequenced: not array or empty array given'
        return false
      i = 0
      for spy in @actual
        unless spy.callCount == 1
          @message = -> "toBeSequenced: spy ##{i} was called #{spy.callCount} times"
          return false
        i++
      if @actual.length > 1
        for spy in @actual.from(1)
          i = @actual.indexOf spy
          previous = @actual[i - 1]
          unless spy.calledAfter previous
            @message = -> "toBeSequenced: spy ##{i} wasn't called after spy ##{i - 1}"
            return false

      return true

    toBeTag: (tagName, content, attrs) ->
      @message = =>
        "Expected #{@actual} to be a tag #{tagName} with attributes #{JSON.stringify attrs} and content #{content}"

      tag = $ @actual
      flag = true

      flag = flag && tag.length == 1
      flag = flag && tag[0].nodeName == tagName.toUpperCase()
      if content != false
        flag = flag && tag.html() == content

      for name, val of attrs
        flag = flag && !!(if val.constructor == RegExp then tag.attr(name).match(val) else tag.attr(name) == val)

      flag = flag && tag[0].attributes.length == Object.keys(attrs).length

      flag