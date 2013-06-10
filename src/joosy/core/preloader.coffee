#
# Preloader stub
#
# @mixin
#
@Preloader =

  #
  # Mocks loader to do nothing if Joosy is already here
  #
  load: (libraries, options) ->
    @[key] = val for key, val of options
    @complete?.call window
