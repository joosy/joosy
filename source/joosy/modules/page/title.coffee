#= require ../page

# @mixin
Joosy.Modules.Page.Title =

  #
  # Sets the page HTML title.
  #
  # @note Title will be reverted on unload.
  #
  # @param [String] title       Title to set.
  #
  title: (title, separator=' / ') ->
    @afterLoad ->
      title = title.apply(@) if typeof(title) == 'function'
      title = title.join(separator) if title instanceof Array
      @__previousTitle = document.title
      document.title = title

    @afterUnload ->
      document.title = @__previousTitle