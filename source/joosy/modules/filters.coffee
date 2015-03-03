#= require joosy/joosy

#
# Filters registration routines
#
# @mixin
# @private
#
Joosy.Modules.Filters =

  #
  # Internal helper registering filters accessors
  #
  __registerFilterCollector: (filter) ->
    camelized = filter.charAt(0).toUpperCase() + filter.slice(1)

    @[filter] = (callback) ->
      unless @::hasOwnProperty "__#{filter}s"
        @::["__#{filter}s"] = [].concat @.__super__["__#{filter}s"] || []
      @::["__#{filter}s"].push callback

    @["prepend#{camelized}"] = (callback) ->
      unless @::hasOwnProperty "__#{filter}s"
        @::["__#{filter}s"] = [].concat @.__super__["__#{filter}s"] || []
      @::["__#{filter}s"].unshift callback

    camelized

  #
  # Registers a set of plain (synchronous) filters
  #
  # @example
  #   class Test
  #     @extend Joosy.Modules.Filters
  #     @registerPlainFilters 'beforeLoad', 'afterLoad'
  #
  registerPlainFilters: (filters...) ->
    for filter in filters
      do (filter) =>
        camelized = @__registerFilterCollector filter

        @::["__run#{camelized}s"] = (params...) ->
          return unless @["__#{filter}s"]

          for callback in @["__#{filter}s"]
            callback = @[callback] unless typeof(callback) == 'function'
            callback.apply(@, params)

        @::["__confirm#{camelized}s"] = (params...) ->
          return true unless @["__#{filter}s"]

          @["__#{filter}s"].every (callback) =>
            callback = @[callback] unless typeof(callback) == 'function'
            callback.apply(@, params) != false

        @::["__apply#{camelized}s"] = (data, params...) ->
          return data unless @["__#{filter}s"]

          for callback in @["__#{filter}s"]
            callback = @[callback] unless typeof(callback) == 'function'
            data = callback.apply(@, [data].concat params)

          data

  #
  # Registers a set of sequenced (asynchronous) filters
  #
  # @example
  #   class Test
  #     @extend Joosy.Modules.Filters
  #     @registerSequencedFilters 'fetch', 'paint'
  #
  registerSequencedFilters: (filters...) ->
    for filter in filters
      do (filter) =>
        camelized = @__registerFilterCollector filter

        @::["__run#{camelized}s"] = (params, callback) ->
          return callback() unless @["__#{filter}s"]

          runners  = @["__#{filter}s"]
          filterer = @

          if runners.length == 1
            return runners[0].apply @, params.concat(callback)

          Joosy.synchronize (context) ->
            for runner in runners
              do (runner) ->
                context.do (done) ->
                  runner.apply filterer, params.concat(done)
            context.after callback

# AMD wrapper
if define?.amd?
  define 'joosy/modules/filters', -> Joosy.Modules.Filters
