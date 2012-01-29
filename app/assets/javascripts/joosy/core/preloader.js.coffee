# Preloader stub
@Preloader = Object.extended
  load: (libraries, options) ->
    @.merge options
    @complete?.call window