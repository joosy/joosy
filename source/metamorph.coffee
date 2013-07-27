# ==========================================================================
# Project:   metamorph
# Copyright: ©2013 Tilde, Inc. All rights reserved.
# ==========================================================================
((window) ->
  K = ->

  guid = 0
  document = window.document
  
  # Feature-detect the W3C range API, the extended check is for IE9 which only partially supports ranges
  supportsRange = document and ("createRange" of document) and (typeof Range isnt "undefined") and Range::createContextualFragment
  
  # Internet Explorer prior to 9 does not allow setting innerHTML if the first element
  # is a "zero-scope" element. This problem can be worked around by making
  # the first node an invisible text node. We, like Modernizr, use &shy;
  needsShy = document and (->
    testEl = document.createElement("div")
    testEl.innerHTML = "<div></div>"
    testEl.firstChild.innerHTML = "<script></script>"
    testEl.firstChild.innerHTML is ""
  )()
  
  # IE 8 (and likely earlier) likes to move whitespace preceeding
  # a script tag to appear after it. This means that we can
  # accidentally remove whitespace when updating a morph.
  movesWhitespace = document and (->
    testEl = document.createElement("div")
    testEl.innerHTML = "Test: <script type='text/x-placeholder'></script>Value"
    testEl.childNodes[0].nodeValue is "Test:" and testEl.childNodes[2].nodeValue is " Value"
  )()
  
  # Constructor that supports either Metamorph('foo') or new
  # Metamorph('foo');
  # 
  # Takes a string of HTML as the argument.
  Metamorph = (html) ->
    self = undefined
    if this instanceof Metamorph
      self = this
    else
      self = new K()
    self.innerHTML = html
    myGuid = "metamorph-" + (guid++)
    self.start = myGuid + "-start"
    self.end = myGuid + "-end"
    self

  K:: = Metamorph::
  rangeFor = undefined
  htmlFunc = undefined
  removeFunc = undefined
  outerHTMLFunc = undefined
  appendToFunc = undefined
  afterFunc = undefined
  prependFunc = undefined
  startTagFunc = undefined
  endTagFunc = undefined
  outerHTMLFunc = ->
    @startTag() + @innerHTML + @endTag()

  startTagFunc = ->
    
    #
    #     * We replace chevron by its hex code in order to prevent escaping problems.
    #     * Check this thread for more explaination:
    #     * http://stackoverflow.com/questions/8231048/why-use-x3c-instead-of-when-generating-html-from-javascript
    #     
    "<script id='" + @start + "' type='text/x-placeholder'></script>"

  endTagFunc = ->
    
    #
    #     * We replace chevron by its hex code in order to prevent escaping problems.
    #     * Check this thread for more explaination:
    #     * http://stackoverflow.com/questions/8231048/why-use-x3c-instead-of-when-generating-html-from-javascript
    #     
    "<script id='" + @end + "' type='text/x-placeholder'></script>"

  
  # If we have the W3C range API, this process is relatively straight forward.
  if supportsRange
    
    # Get a range for the current morph. Optionally include the starting and
    # ending placeholders.
    rangeFor = (morph, outerToo) ->
      range = document.createRange()
      before = document.getElementById(morph.start)
      after = document.getElementById(morph.end)
      if outerToo
        range.setStartBefore before
        range.setEndAfter after
      else
        range.setStartAfter before
        range.setEndBefore after
      range

    htmlFunc = (html, outerToo) ->
      
      # get a range for the current metamorph object
      range = rangeFor(this, outerToo)
      
      # delete the contents of the range, which will be the
      # nodes between the starting and ending placeholder.
      range.deleteContents()
      
      # create a new document fragment for the HTML
      fragment = range.createContextualFragment(html)
      
      # insert the fragment into the range
      range.insertNode fragment

    removeFunc = ->
      
      # get a range for the current metamorph object including
      # the starting and ending placeholders.
      range = rangeFor(this, true)
      
      # delete the entire range.
      range.deleteContents()

    appendToFunc = (node) ->
      range = document.createRange()
      range.setStart node
      range.collapse false
      frag = range.createContextualFragment(@outerHTML())
      node.appendChild frag

    afterFunc = (html) ->
      range = document.createRange()
      after = document.getElementById(@end)
      range.setStartAfter after
      range.setEndAfter after
      fragment = range.createContextualFragment(html)
      range.insertNode fragment

    prependFunc = (html) ->
      range = document.createRange()
      start = document.getElementById(@start)
      range.setStartAfter start
      range.setEndAfter start
      fragment = range.createContextualFragment(html)
      range.insertNode fragment
  else
    
    ###
    This code is mostly taken from jQuery, with one exception. In jQuery's case, we
    have some HTML and we need to figure out how to convert it into some nodes.
    
    In this case, jQuery needs to scan the HTML looking for an opening tag and use
    that as the key for the wrap map. In our case, we know the parent node, and
    can use its type as the key for the wrap map.
    ###
    wrapMap =
      select: [1, "<select multiple='multiple'>", "</select>"]
      fieldset: [1, "<fieldset>", "</fieldset>"]
      table: [1, "<table>", "</table>"]
      tbody: [2, "<table><tbody>", "</tbody></table>"]
      tr: [3, "<table><tbody><tr>", "</tr></tbody></table>"]
      colgroup: [2, "<table><tbody></tbody><colgroup>", "</colgroup></table>"]
      map: [1, "<map>", "</map>"]
      _default: [0, "", ""]

    findChildById = (element, id) ->
      return element  if element.getAttribute("id") is id
      len = element.childNodes.length
      idx = undefined
      node = undefined
      found = undefined
      idx = 0
      while idx < len
        node = element.childNodes[idx]
        found = node.nodeType is 1 and findChildById(node, id)
        return found  if found
        idx++

    setInnerHTML = (element, html) ->
      matches = []
      if movesWhitespace
        
        # Right now we only check for script tags with ids with the
        # goal of targeting morphs.
        html = html.replace(/(\s+)(<script id='([^']+)')/g, (match, spaces, tag, id) ->
          matches.push [id, spaces]
          tag
        )
      element.innerHTML = html
      
      # If we have to do any whitespace adjustments do them now
      if matches.length > 0
        len = matches.length
        idx = undefined
        idx = 0
        while idx < len
          script = findChildById(element, matches[idx][0])
          node = document.createTextNode(matches[idx][1])
          script.parentNode.insertBefore node, script
          idx++

    
    ###
    Given a parent node and some HTML, generate a set of nodes. Return the first
    node, which will allow us to traverse the rest using nextSibling.
    
    We need to do this because innerHTML in IE does not really parse the nodes.
    ###
    firstNodeFor = (parentNode, html) ->
      arr = wrapMap[parentNode.tagName.toLowerCase()] or wrapMap._default
      depth = arr[0]
      start = arr[1]
      end = arr[2]
      html = "&shy;" + html  if needsShy
      element = document.createElement("div")
      setInnerHTML element, start + html + end
      i = 0

      while i <= depth
        element = element.firstChild
        i++
      
      # Look for &shy; to remove it.
      if needsShy
        shyElement = element
        
        # Sometimes we get nameless elements with the shy inside
        shyElement = shyElement.firstChild  while shyElement.nodeType is 1 and not shyElement.nodeName
        
        # At this point it's the actual unicode character.
        shyElement.nodeValue = shyElement.nodeValue.slice(1)  if shyElement.nodeType is 3 and shyElement.nodeValue.charAt(0) is "­"
      element

    
    ###
    In some cases, Internet Explorer can create an anonymous node in
    the hierarchy with no tagName. You can create this scenario via:
    
    div = document.createElement("div");
    div.innerHTML = "<table>&shy<script></script><tr><td>hi</td></tr></table>";
    div.firstChild.firstChild.tagName //=> ""
    
    If our script markers are inside such a node, we need to find that
    node and use *it* as the marker.
    ###
    realNode = (start) ->
      start = start.parentNode  while start.parentNode.tagName is ""
      start

    
    ###
    When automatically adding a tbody, Internet Explorer inserts the
    tbody immediately before the first <tr>. Other browsers create it
    before the first node, no matter what.
    
    This means the the following code:
    
    div = document.createElement("div");
    div.innerHTML = "<table><script id='first'></script><tr><td>hi</td></tr><script id='last'></script></table>
    
    Generates the following DOM in IE:
    
    + div
    + table
    - script id='first'
    + tbody
    + tr
    + td
    - "hi"
    - script id='last'
    
    Which means that the two script tags, even though they were
    inserted at the same point in the hierarchy in the original
    HTML, now have different parents.
    
    This code reparents the first script tag by making it the tbody's
    first child.
    ###
    fixParentage = (start, end) ->
      end.parentNode.insertBefore start, end.parentNode.firstChild  if start.parentNode isnt end.parentNode

    htmlFunc = (html, outerToo) ->
      
      # get the real starting node. see realNode for details.
      start = realNode(document.getElementById(@start))
      end = document.getElementById(@end)
      parentNode = end.parentNode
      node = undefined
      nextSibling = undefined
      last = undefined
      
      # make sure that the start and end nodes share the same
      # parent. If not, fix it.
      fixParentage start, end
      
      # remove all of the nodes after the starting placeholder and
      # before the ending placeholder.
      node = start.nextSibling
      while node
        nextSibling = node.nextSibling
        last = node is end
        
        # if this is the last node, and we want to remove it as well,
        # set the `end` node to the next sibling. This is because
        # for the rest of the function, we insert the new nodes
        # before the end (note that insertBefore(node, null) is
        # the same as appendChild(node)).
        #
        # if we do not want to remove it, just break.
        if last
          if outerToo
            end = node.nextSibling
          else
            break
        node.parentNode.removeChild node
        
        # if this is the last node and we didn't break before
        # (because we wanted to remove the outer nodes), break
        # now.
        break  if last
        node = nextSibling
      
      # get the first node for the HTML string, even in cases like
      # tables and lists where a simple innerHTML on a div would
      # swallow some of the content.
      node = firstNodeFor(start.parentNode, html)
      
      # copy the nodes for the HTML between the starting and ending
      # placeholder.
      while node
        nextSibling = node.nextSibling
        parentNode.insertBefore node, end
        node = nextSibling

    
    # remove the nodes in the DOM representing this metamorph.
    #
    # this includes the starting and ending placeholders.
    removeFunc = ->
      start = realNode(document.getElementById(@start))
      end = document.getElementById(@end)
      @html ""
      start.parentNode.removeChild start
      end.parentNode.removeChild end

    appendToFunc = (parentNode) ->
      node = firstNodeFor(parentNode, @outerHTML())
      nextSibling = undefined
      while node
        nextSibling = node.nextSibling
        parentNode.appendChild node
        node = nextSibling

    afterFunc = (html) ->
      
      # get the real starting node. see realNode for details.
      end = document.getElementById(@end)
      insertBefore = end.nextSibling
      parentNode = end.parentNode
      nextSibling = undefined
      node = undefined
      
      # get the first node for the HTML string, even in cases like
      # tables and lists where a simple innerHTML on a div would
      # swallow some of the content.
      node = firstNodeFor(parentNode, html)
      
      # copy the nodes for the HTML between the starting and ending
      # placeholder.
      while node
        nextSibling = node.nextSibling
        parentNode.insertBefore node, insertBefore
        node = nextSibling

    prependFunc = (html) ->
      start = document.getElementById(@start)
      parentNode = start.parentNode
      nextSibling = undefined
      node = undefined
      node = firstNodeFor(parentNode, html)
      insertBefore = start.nextSibling
      while node
        nextSibling = node.nextSibling
        parentNode.insertBefore node, insertBefore
        node = nextSibling
  Metamorph::html = (html) ->
    @checkRemoved()
    return @innerHTML  if html is `undefined`
    htmlFunc.call this, html
    @innerHTML = html

  Metamorph::replaceWith = (html) ->
    @checkRemoved()
    htmlFunc.call this, html, true

  Metamorph::remove = removeFunc
  Metamorph::outerHTML = outerHTMLFunc
  Metamorph::appendTo = appendToFunc
  Metamorph::after = afterFunc
  Metamorph::prepend = prependFunc
  Metamorph::startTag = startTagFunc
  Metamorph::endTag = endTagFunc
  Metamorph::isRemoved = ->
    before = document.getElementById(@start)
    after = document.getElementById(@end)
    not before or not after

  Metamorph::checkRemoved = ->
    throw new Error("Cannot perform operations on a Metamorph that is not in the DOM.")  if @isRemoved()

  window.Metamorph = Metamorph
) this