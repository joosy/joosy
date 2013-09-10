beforeEach ->
  @addMatchers

    #
    # Checks whether listed array of callbacks was
    # called in exact order one by one
    #
    # @example
    #   [ (->), (->), (->) ].toBesequenced()
    #
    toBeSequenced: ->
      # Are we working with array?
      if !Array.isArray(@actual) || @actual.length == 0
        @message = -> 'Not array or empty array given'
        return false

      # Was every spy called just once?
      for spy, i in @actual
        unless spy.callCount == 1
          @message = -> "Spy ##{i} was called #{spy.callCount} times instead of just one"
          return false

      # Were they called in a proper order?
      if @actual.length > 1
        for spy, i in @actual.slice(1)
          unless spy.calledAfter @actual[i]
            @message = -> "Spy ##{i+1} wasn't called after spy ##{i}"
            return false

      return true

    toEqualHTML: (string) ->
      html     = @actual.replace(/>\s+</g, '><').toLowerCase().replace(/\"/g, '')
      string   = string.toLowerCase().replace(/\"/g, '')
      @message = -> "Expected '#{html}' to equal '#{string}'"

      html == string

    #
    # Checks the exact equality of tag including attributes and content
    # with the posibility to check attributes values by regexp
    #
    # @example
    #   tag = "<div class='foo' id='bar'>foo</div>"
    #   tag.toBeTag 'div', 'foo', class: 'foo', id: /\S+/
    #
    toBeTag: (tagName, content, attrs) ->
      reason = ''
      @message = =>
        actual = $('<div>').append(@actual).html()
        "Expected '#{actual}' to be a tag #{tagName} with attributes #{JSON.stringify attrs} and content '#{content}': #{reason}"

      tag = $ @actual

      # Is it alone?
      flag = tag.length == 1
      if !flag
        reason = 'not alone'
        return false

      # Tag name matches?
      flag &&= tag[0].nodeName == tagName.toUpperCase()
      if !flag
        reason = 'tag name mismatch'
        return false

      # Content matches?
      flag &&= tag.html() == content if content != false
      if !flag
        reason = 'content mismatch'
        return false

      # Same number of attributes?
      flag &&= tag[0].attributes.length == Object.keys(attrs).length
      if !flag
        reason = 'attributes count mismatch'
        return false

      # Attributes match?
      for name, val of attrs
        if val.constructor == RegExp
          flag &&= tag.attr(name).match(val)
        else
          flag &&= tag.attr(name) == val

      flag
