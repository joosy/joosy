Joosy.namespace 'Welcome', ->

  class @IndexPage extends ApplicationPage
    @layout ApplicationLayout
    @view   'index'

    @afterLoad ->
      @startHeartbeat()
      @$content().css
        'padding-top': "#{$(window).height() / 2 - 80}px"

    @mapElements
      content: '#content'
      joosy:   '.joosy'

    @mapEvents
      'mouseover $joosy': -> clearInterval @heartbeat
      'mouseout $joosy': 'startHeartbeat'

    startHeartbeat: ->
      @heartbeat = @setInterval 1500, =>
        @$joosy().animate({opacity: 0.8}, 300).animate({opacity: 1}, 300)
