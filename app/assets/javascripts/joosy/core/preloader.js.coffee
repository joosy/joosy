# Preloader stub
@Preloader =
  load: (libraries, options) ->
    @[key] = val for key, val of options
    @complete?.call window
