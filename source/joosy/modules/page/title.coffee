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
      titleStr = if Object.isFunction(title) then title.apply(@) else title
      titleStr = titleStr.join(separator) if Object.isArray(titleStr)
      @__previousTitle = document.title
      document.title = titleStr

    @afterUnload ->
      document.title = @__previousTitle