(function() {
  this.Joosy = {
    Modules: {},
    Resources: {},
    Templaters: {},
    Helpers: {},
    Events: {},
    /* Global settings*/

    debug: function(value) {
      if (value != null) {
        return this.__debug = value;
      } else {
        return !!this.__debug;
      }
    },
    templater: function(value) {
      if (value != null) {
        return this.__templater = value;
      } else {
        if (!this.__templater) {
          throw new Error("No templater registered");
        }
        return this.__templater;
      }
    },
    /* Global helpers*/

    namespace: function(name, generator) {
      var key, klass, part, space, _i, _len, _results;
      if (generator == null) {
        generator = false;
      }
      name = name.split('.');
      space = window;
      for (_i = 0, _len = name.length; _i < _len; _i++) {
        part = name[_i];
        if (part.length > 0) {
          space = space[part] != null ? space[part] : space[part] = {};
        }
      }
      if (generator) {
        generator = generator.apply(space);
      }
      _results = [];
      for (key in space) {
        klass = space[key];
        if (space.hasOwnProperty(key) && Joosy.Module.hasAncestor(klass, Joosy.Module)) {
          _results.push(klass.__namespace__ = name);
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    },
    helpers: function(name, generator) {
      var _base;
      (_base = Joosy.Helpers)[name] || (_base[name] = {});
      return generator.apply(Joosy.Helpers[name]);
    },
    uid: function() {
      this.__uid || (this.__uid = 0);
      return "__joosy" + (this.__uid++);
    },
    uuid: function() {
      return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
        var r, v;
        r = Math.random() * 16 | 0;
        v = c === 'x' ? r : r & 3 | 8;
        return v.toString(16);
      }).toUpperCase();
    },
    /* Shortcuts*/

    synchronize: function() {
      var _ref;
      if (!Joosy.Modules.Events) {
        return console.error("Events module is required to use `Joosy.synchronize'!");
      } else {
        return (_ref = Joosy.Modules.Events).synchronize.apply(_ref, arguments);
      }
    },
    buildUrl: function(url, params) {
      var hash, paramsString;
      paramsString = [];
      Object.each(params, function(key, value) {
        return paramsString.push("" + key + "=" + value);
      });
      hash = url.match(/(\#.*)?$/)[0];
      url = url.replace(/\#.*$/, '');
      if (!paramsString.isEmpty() && !url.has(/\?/)) {
        url = url + "?";
      }
      paramsString = paramsString.join('&');
      if (!paramsString.isBlank() && url.last() !== '?') {
        paramsString = '&' + paramsString;
      }
      return url + paramsString + hash;
    }
  };

  if ((typeof define !== "undefined" && define !== null ? define.amd : void 0) != null) {
    define('joosy', function() {
      return Joosy;
    });
  }

}).call(this);
(function() {
  Joosy.Module = (function() {
    function Module() {}

    Module.__namespace__ = [];

    Module.__className = function(klass) {
      if (!Object.isFunction(klass)) {
        klass = klass.constructor;
      }
      if (klass.name != null) {
        return klass.name;
      } else {
        return klass.toString().replace(/^function ([a-zA-Z]+)\([\s\S]+/, '$1');
      }
    };

    Module.hasAncestor = function(what, klass) {
      var _ref;
      if (!((what != null) && (klass != null))) {
        return false;
      }
      what = what.prototype;
      klass = klass.prototype;
      while (what) {
        if (what === klass) {
          return true;
        }
        what = (_ref = what.constructor) != null ? _ref.__super__ : void 0;
      }
      return false;
    };

    Module.aliasMethodChain = function(method, feature, action) {
      var camelized, chained;
      camelized = feature.charAt(0).toUpperCase() + feature.slice(1);
      chained = "" + method + "Without" + camelized;
      if (!Object.isFunction(action)) {
        action = this.prototype[action];
      }
      this.prototype[chained] = this.prototype[method];
      return this.prototype[method] = action;
    };

    Module.aliasStaticMethodChain = function(method, feature, action) {
      var camelized, chained;
      camelized = feature.charAt(0).toUpperCase() + feature.slice(1);
      chained = "" + method + "Without" + camelized;
      this[chained] = this[method];
      return this[method] = action;
    };

    Module.merge = function(destination, source, unsafe) {
      var key, value;
      if (unsafe == null) {
        unsafe = true;
      }
      for (key in source) {
        value = source[key];
        if (source.hasOwnProperty(key)) {
          if (unsafe || !destination.hasOwnProperty(key)) {
            destination[key] = value;
          }
        }
      }
      return destination;
    };

    Module.include = function(object) {
      var key, value, _ref;
      if (!object) {
        throw new Error('include(object) requires obj');
      }
      for (key in object) {
        value = object[key];
        if (key !== 'included' && key !== 'extended') {
          this.prototype[key] = value;
        }
      }
      if ((_ref = object.included) != null) {
        _ref.apply(this);
      }
      return null;
    };

    Module.extend = function(object) {
      var _ref;
      if (!object) {
        throw new Error('extend(object) requires object');
      }
      this.merge(this, object);
      if ((_ref = object.extended) != null) {
        _ref.apply(this);
      }
      return null;
    };

    return Module;

  })();

  if ((typeof define !== "undefined" && define !== null ? define.amd : void 0) != null) {
    define('joosy/module', function() {
      return Joosy.Module;
    });
  }

}).call(this);
(function() {
  var __slice = [].slice;

  Joosy.Events.Namespace = (function() {
    function Namespace(parent) {
      this.parent = parent;
      this.bindings = [];
    }

    Namespace.prototype.bind = function() {
      var args, _ref;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return this.bindings.push((_ref = this.parent).bind.apply(_ref, args));
    };

    Namespace.prototype.unbind = function() {
      var b, _i, _len, _ref;
      _ref = this.bindings;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        b = _ref[_i];
        this.parent.unbind(b);
      }
      return this.bindings = [];
    };

    return Namespace;

  })();

}).call(this);
(function() {
  var SynchronizationContext,
    __slice = [].slice;

  SynchronizationContext = (function() {
    function SynchronizationContext() {
      this.actions = [];
    }

    SynchronizationContext.prototype["do"] = function(action) {
      return this.actions.push(action);
    };

    SynchronizationContext.prototype.after = function(after) {
      this.after = after;
    };

    return SynchronizationContext;

  })();

  Joosy.Modules.Events = {
    wait: function(name, events, callback) {
      if (!this.hasOwnProperty('__oneShotEvents')) {
        this.__oneShotEvents = {};
      }
      if (Object.isFunction(events)) {
        callback = events;
        events = name;
        name = Object.keys(this.__oneShotEvents).length.toString();
      }
      events = this.__splitEvents(events);
      if (events.length > 0) {
        this.__oneShotEvents[name] = [events, callback];
      } else {
        callback();
      }
      return name;
    },
    unwait: function(target) {
      if (this.hasOwnProperty('__oneShotEvents')) {
        return delete this.__oneShotEvents[target];
      }
    },
    bind: function(name, events, callback) {
      if (!this.hasOwnProperty('__boundEvents')) {
        this.__boundEvents = {};
      }
      if (Object.isFunction(events)) {
        callback = events;
        events = name;
        name = Object.keys(this.__boundEvents).length.toString();
      }
      events = this.__splitEvents(events);
      if (events.length > 0) {
        this.__boundEvents[name] = [events, callback];
      } else {
        callback();
      }
      return name;
    },
    unbind: function(target) {
      if (this.hasOwnProperty('__boundEvents')) {
        return delete this.__boundEvents[target];
      }
    },
    trigger: function() {
      var callback, data, event, events, fire, name, remember, _ref, _ref1, _ref2, _ref3,
        _this = this;
      event = arguments[0], data = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      Joosy.Modules.Log.debugAs(this, "Event " + event + " triggered");
      if (Object.isObject(event)) {
        remember = event.remember;
        event = event.name;
      } else {
        remember = false;
      }
      if (this.hasOwnProperty('__oneShotEvents')) {
        fire = [];
        _ref = this.__oneShotEvents;
        for (name in _ref) {
          _ref1 = _ref[name], events = _ref1[0], callback = _ref1[1];
          events.remove(event);
          if (events.length === 0) {
            fire.push(name);
          }
        }
        fire.each(function(name) {
          callback = _this.__oneShotEvents[name][1];
          delete _this.__oneShotEvents[name];
          return callback.apply(null, data);
        });
      }
      if (this.hasOwnProperty('__boundEvents')) {
        _ref2 = this.__boundEvents;
        for (name in _ref2) {
          _ref3 = _ref2[name], events = _ref3[0], callback = _ref3[1];
          if (events.any(event)) {
            callback.apply(null, data);
          }
        }
      }
      if (remember) {
        if (!this.hasOwnProperty('__triggeredEvents')) {
          this.__triggeredEvents = {};
        }
        return this.__triggeredEvents[event] = true;
      }
    },
    synchronize: function(block) {
      var context, counter,
        _this = this;
      context = new SynchronizationContext;
      counter = 0;
      block(context);
      if (context.actions.length === 0) {
        return context.after.call(this);
      } else {
        return context.actions.each(function(action) {
          return action.call(_this, function() {
            if (++counter >= context.actions.length) {
              return context.after.call(this);
            }
          });
        });
      }
    },
    __splitEvents: function(events) {
      var _this = this;
      if (Object.isString(events)) {
        if (events.isBlank()) {
          events = [];
        } else {
          events = events.trim().split(/\s+/);
        }
      }
      if (this.hasOwnProperty('__triggeredEvents')) {
        events = events.findAll(function(e) {
          return !_this.__triggeredEvents[e];
        });
      }
      return events;
    }
  };

  if ((typeof define !== "undefined" && define !== null ? define.amd : void 0) != null) {
    define('joosy/modules/events', function() {
      return Joosy.Modules.Events;
    });
  }

}).call(this);
(function() {
  var __slice = [].slice;

  Joosy.Modules.Log = {
    log: function() {
      var args;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      if (typeof console === "undefined" || console === null) {
        return;
      }
      if (console.log.apply != null) {
        args.unshift("Joosy>");
        return console.log.apply(console, args);
      } else {
        return console.log(args.first());
      }
    },
    debug: function() {
      var args;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      if (!Joosy.debug()) {
        return;
      }
      return this.log.apply(this, args);
    },
    debugAs: function() {
      var args, context, string;
      context = arguments[0], string = arguments[1], args = 3 <= arguments.length ? __slice.call(arguments, 2) : [];
      if (!Joosy.debug()) {
        return;
      }
      context = Joosy.Module.__className(context) || 'unknown context';
      return this.debug.apply(this, ["" + context + "> " + string].concat(__slice.call(args)));
    }
  };

  if ((typeof define !== "undefined" && define !== null ? define.amd : void 0) != null) {
    define('joosy/modules/log', function() {
      return Joosy.Modules.Log;
    });
  }

}).call(this);
(function() {
  Joosy.Modules.DOM = {
    eventSplitter: /^(\S+)\s*(.*)$/,
    included: function() {
      this.mapElements = function(map) {
        if (!this.prototype.hasOwnProperty("__elements")) {
          this.prototype.__elements = Object.clone(this.__super__.__elements) || {};
        }
        return Object.merge(this.prototype.__elements, map);
      };
      return this.mapEvents = function(map) {
        if (!this.prototype.hasOwnProperty("__events")) {
          this.prototype.__events = Object.clone(this.__super__.__events) || {};
        }
        return Object.merge(this.prototype.__events, map);
      };
    },
    $: function(selector, context) {
      return $(selector, context || this.$container);
    },
    __extractSelector: function(selector) {
      var _this = this;
      selector = selector.replace(/(\$[A-z0-9\.\$]+)/g, function(path) {
        var keyword, part, target, _i, _len, _ref;
        path = path.split('.');
        keyword = path.pop();
        target = _this;
        for (_i = 0, _len = path.length; _i < _len; _i++) {
          part = path[_i];
          target = target != null ? target[part] : void 0;
        }
        return target != null ? (_ref = target[keyword]) != null ? _ref.selector : void 0 : void 0;
      });
      return selector.trim();
    },
    __assignElements: function(root, entries) {
      var key, value, _results;
      root || (root = this);
      entries || (entries = this.__elements);
      if (!entries) {
        return;
      }
      _results = [];
      for (key in entries) {
        value = entries[key];
        if (Object.isObject(value)) {
          _results.push(this.__assignElements(root['$' + key] = {}, value));
        } else {
          value = this.__extractSelector(value);
          root['$' + key] = this.__wrapElement(value);
          _results.push(root['$' + key].selector = value);
        }
      }
      return _results;
    },
    __wrapElement: function(value) {
      var _this = this;
      return function(context) {
        if (!context) {
          return _this.$(value);
        }
        return _this.$(value, context);
      };
    },
    __delegateEvents: function() {
      var events, module,
        _this = this;
      module = this;
      events = this.__events;
      if (!events) {
        return;
      }
      return Object.each(events, function(key, method) {
        var callback, eventName, match, selector;
        if (!Object.isFunction(method)) {
          method = _this[method];
        }
        callback = function(event) {
          return method.call(module, $(this), event);
        };
        match = key.match(_this.eventSplitter);
        eventName = match[1];
        selector = _this.__extractSelector(match[2]);
        if (selector === "") {
          _this.$container.bind(eventName, callback);
          return Joosy.Modules.Log.debugAs(_this, "" + eventName + " binded on container");
        } else if (selector === void 0) {
          throw new Error("Unknown element " + match[2] + " in " + (Joosy.Module.__className(_this.constructor)) + " (maybe typo?)");
        } else {
          _this.$container.on(eventName, selector, callback);
          return Joosy.Modules.Log.debugAs(_this, "" + eventName + " binded on " + selector);
        }
      });
    },
    __clearContainer: function() {
      var _ref;
      if ((_ref = this.$container) != null) {
        _ref.unbind().off();
      }
      return this.$container = $();
    }
  };

  if ((typeof define !== "undefined" && define !== null ? define.amd : void 0) != null) {
    define('joosy/modules/dom', function() {
      return Joosy.Modules.DOM;
    });
  }

}).call(this);
(function() {
  (function(window) {
    var K, Metamorph, afterFunc, appendToFunc, document, endTagFunc, findChildById, firstNodeFor, fixParentage, guid, htmlFunc, movesWhitespace, needsShy, outerHTMLFunc, prependFunc, rangeFor, realNode, removeFunc, setInnerHTML, startTagFunc, supportsRange, wrapMap;
    K = function() {};
    guid = 0;
    document = window.document;
    supportsRange = document && ("createRange" in document) && (typeof Range !== "undefined") && Range.prototype.createContextualFragment;
    needsShy = document && (function() {
      var testEl;
      testEl = document.createElement("div");
      testEl.innerHTML = "<div></div>";
      testEl.firstChild.innerHTML = "<script></script>";
      return testEl.firstChild.innerHTML === "";
    })();
    movesWhitespace = document && (function() {
      var testEl;
      testEl = document.createElement("div");
      testEl.innerHTML = "Test: <script type='text/x-placeholder'></script>Value";
      return testEl.childNodes[0].nodeValue === "Test:" && testEl.childNodes[2].nodeValue === " Value";
    })();
    Metamorph = function(html) {
      var myGuid, self;
      self = void 0;
      if (this instanceof Metamorph) {
        self = this;
      } else {
        self = new K();
      }
      self.innerHTML = html;
      myGuid = "metamorph-" + (guid++);
      self.start = myGuid + "-start";
      self.end = myGuid + "-end";
      return self;
    };
    K.prototype = Metamorph.prototype;
    rangeFor = void 0;
    htmlFunc = void 0;
    removeFunc = void 0;
    outerHTMLFunc = void 0;
    appendToFunc = void 0;
    afterFunc = void 0;
    prependFunc = void 0;
    startTagFunc = void 0;
    endTagFunc = void 0;
    outerHTMLFunc = function() {
      return this.startTag() + this.innerHTML + this.endTag();
    };
    startTagFunc = function() {
      return "<script id='" + this.start + "' type='text/x-placeholder'></script>";
    };
    endTagFunc = function() {
      return "<script id='" + this.end + "' type='text/x-placeholder'></script>";
    };
    if (supportsRange) {
      rangeFor = function(morph, outerToo) {
        var after, before, range;
        range = document.createRange();
        before = document.getElementById(morph.start);
        after = document.getElementById(morph.end);
        if (outerToo) {
          range.setStartBefore(before);
          range.setEndAfter(after);
        } else {
          range.setStartAfter(before);
          range.setEndBefore(after);
        }
        return range;
      };
      htmlFunc = function(html, outerToo) {
        var fragment, range;
        range = rangeFor(this, outerToo);
        range.deleteContents();
        fragment = range.createContextualFragment(html);
        return range.insertNode(fragment);
      };
      removeFunc = function() {
        var range;
        range = rangeFor(this, true);
        return range.deleteContents();
      };
      appendToFunc = function(node) {
        var frag, range;
        range = document.createRange();
        range.setStart(node);
        range.collapse(false);
        frag = range.createContextualFragment(this.outerHTML());
        return node.appendChild(frag);
      };
      afterFunc = function(html) {
        var after, fragment, range;
        range = document.createRange();
        after = document.getElementById(this.end);
        range.setStartAfter(after);
        range.setEndAfter(after);
        fragment = range.createContextualFragment(html);
        return range.insertNode(fragment);
      };
      prependFunc = function(html) {
        var fragment, range, start;
        range = document.createRange();
        start = document.getElementById(this.start);
        range.setStartAfter(start);
        range.setEndAfter(start);
        fragment = range.createContextualFragment(html);
        return range.insertNode(fragment);
      };
    } else {
      /*
      This code is mostly taken from jQuery, with one exception. In jQuery's case, we
      have some HTML and we need to figure out how to convert it into some nodes.
      
      In this case, jQuery needs to scan the HTML looking for an opening tag and use
      that as the key for the wrap map. In our case, we know the parent node, and
      can use its type as the key for the wrap map.
      */

      wrapMap = {
        select: [1, "<select multiple='multiple'>", "</select>"],
        fieldset: [1, "<fieldset>", "</fieldset>"],
        table: [1, "<table>", "</table>"],
        tbody: [2, "<table><tbody>", "</tbody></table>"],
        tr: [3, "<table><tbody><tr>", "</tr></tbody></table>"],
        colgroup: [2, "<table><tbody></tbody><colgroup>", "</colgroup></table>"],
        map: [1, "<map>", "</map>"],
        _default: [0, "", ""]
      };
      findChildById = function(element, id) {
        var found, idx, len, node;
        if (element.getAttribute("id") === id) {
          return element;
        }
        len = element.childNodes.length;
        idx = void 0;
        node = void 0;
        found = void 0;
        idx = 0;
        while (idx < len) {
          node = element.childNodes[idx];
          found = node.nodeType === 1 && findChildById(node, id);
          if (found) {
            return found;
          }
          idx++;
        }
      };
      setInnerHTML = function(element, html) {
        var idx, len, matches, node, script, _results;
        matches = [];
        if (movesWhitespace) {
          html = html.replace(/(\s+)(<script id='([^']+)')/g, function(match, spaces, tag, id) {
            matches.push([id, spaces]);
            return tag;
          });
        }
        element.innerHTML = html;
        if (matches.length > 0) {
          len = matches.length;
          idx = void 0;
          idx = 0;
          _results = [];
          while (idx < len) {
            script = findChildById(element, matches[idx][0]);
            node = document.createTextNode(matches[idx][1]);
            script.parentNode.insertBefore(node, script);
            _results.push(idx++);
          }
          return _results;
        }
      };
      /*
      Given a parent node and some HTML, generate a set of nodes. Return the first
      node, which will allow us to traverse the rest using nextSibling.
      
      We need to do this because innerHTML in IE does not really parse the nodes.
      */

      firstNodeFor = function(parentNode, html) {
        var arr, depth, element, end, i, shyElement, start;
        arr = wrapMap[parentNode.tagName.toLowerCase()] || wrapMap._default;
        depth = arr[0];
        start = arr[1];
        end = arr[2];
        if (needsShy) {
          html = "&shy;" + html;
        }
        element = document.createElement("div");
        setInnerHTML(element, start + html + end);
        i = 0;
        while (i <= depth) {
          element = element.firstChild;
          i++;
        }
        if (needsShy) {
          shyElement = element;
          while (shyElement.nodeType === 1 && !shyElement.nodeName) {
            shyElement = shyElement.firstChild;
          }
          if (shyElement.nodeType === 3 && shyElement.nodeValue.charAt(0) === "­") {
            shyElement.nodeValue = shyElement.nodeValue.slice(1);
          }
        }
        return element;
      };
      /*
      In some cases, Internet Explorer can create an anonymous node in
      the hierarchy with no tagName. You can create this scenario via:
      
      div = document.createElement("div");
      div.innerHTML = "<table>&shy<script></script><tr><td>hi</td></tr></table>";
      div.firstChild.firstChild.tagName //=> ""
      
      If our script markers are inside such a node, we need to find that
      node and use *it* as the marker.
      */

      realNode = function(start) {
        while (start.parentNode.tagName === "") {
          start = start.parentNode;
        }
        return start;
      };
      /*
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
      */

      fixParentage = function(start, end) {
        if (start.parentNode !== end.parentNode) {
          return end.parentNode.insertBefore(start, end.parentNode.firstChild);
        }
      };
      htmlFunc = function(html, outerToo) {
        var end, last, nextSibling, node, parentNode, start, _results;
        start = realNode(document.getElementById(this.start));
        end = document.getElementById(this.end);
        parentNode = end.parentNode;
        node = void 0;
        nextSibling = void 0;
        last = void 0;
        fixParentage(start, end);
        node = start.nextSibling;
        while (node) {
          nextSibling = node.nextSibling;
          last = node === end;
          if (last) {
            if (outerToo) {
              end = node.nextSibling;
            } else {
              break;
            }
          }
          node.parentNode.removeChild(node);
          if (last) {
            break;
          }
          node = nextSibling;
        }
        node = firstNodeFor(start.parentNode, html);
        _results = [];
        while (node) {
          nextSibling = node.nextSibling;
          parentNode.insertBefore(node, end);
          _results.push(node = nextSibling);
        }
        return _results;
      };
      removeFunc = function() {
        var end, start;
        start = realNode(document.getElementById(this.start));
        end = document.getElementById(this.end);
        this.html("");
        start.parentNode.removeChild(start);
        return end.parentNode.removeChild(end);
      };
      appendToFunc = function(parentNode) {
        var nextSibling, node, _results;
        node = firstNodeFor(parentNode, this.outerHTML());
        nextSibling = void 0;
        _results = [];
        while (node) {
          nextSibling = node.nextSibling;
          parentNode.appendChild(node);
          _results.push(node = nextSibling);
        }
        return _results;
      };
      afterFunc = function(html) {
        var end, insertBefore, nextSibling, node, parentNode, _results;
        end = document.getElementById(this.end);
        insertBefore = end.nextSibling;
        parentNode = end.parentNode;
        nextSibling = void 0;
        node = void 0;
        node = firstNodeFor(parentNode, html);
        _results = [];
        while (node) {
          nextSibling = node.nextSibling;
          parentNode.insertBefore(node, insertBefore);
          _results.push(node = nextSibling);
        }
        return _results;
      };
      prependFunc = function(html) {
        var insertBefore, nextSibling, node, parentNode, start, _results;
        start = document.getElementById(this.start);
        parentNode = start.parentNode;
        nextSibling = void 0;
        node = void 0;
        node = firstNodeFor(parentNode, html);
        insertBefore = start.nextSibling;
        _results = [];
        while (node) {
          nextSibling = node.nextSibling;
          parentNode.insertBefore(node, insertBefore);
          _results.push(node = nextSibling);
        }
        return _results;
      };
    }
    Metamorph.prototype.html = function(html) {
      this.checkRemoved();
      if (html === undefined) {
        return this.innerHTML;
      }
      htmlFunc.call(this, html);
      return this.innerHTML = html;
    };
    Metamorph.prototype.replaceWith = function(html) {
      this.checkRemoved();
      return htmlFunc.call(this, html, true);
    };
    Metamorph.prototype.remove = removeFunc;
    Metamorph.prototype.outerHTML = outerHTMLFunc;
    Metamorph.prototype.appendTo = appendToFunc;
    Metamorph.prototype.after = afterFunc;
    Metamorph.prototype.prepend = prependFunc;
    Metamorph.prototype.startTag = startTagFunc;
    Metamorph.prototype.endTag = endTagFunc;
    Metamorph.prototype.isRemoved = function() {
      var after, before;
      before = document.getElementById(this.start);
      after = document.getElementById(this.end);
      return !before || !after;
    };
    Metamorph.prototype.checkRemoved = function() {
      if (this.isRemoved()) {
        throw new Error("Cannot perform operations on a Metamorph that is not in the DOM.");
      }
    };
    return window.Metamorph = Metamorph;
  })(this);

}).call(this);
(function() {
  var __slice = [].slice;

  Joosy.Modules.Renderer = {
    included: function() {
      this.view = function(template, options) {
        if (options == null) {
          options = {};
        }
        return this.prototype.__renderDefault = function(locals) {
          if (locals == null) {
            locals = {};
          }
          if (options.dynamic) {
            return this.renderDynamic(template, locals);
          } else {
            return this.render(template, locals);
          }
        };
      };
      return this.helper = function() {
        var helpers, _ref;
        helpers = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        if (!this.prototype.hasOwnProperty("__helpers")) {
          this.prototype.__helpers = ((_ref = this.__super__.__helpers) != null ? _ref.clone() : void 0) || [];
        }
        this.prototype.__helpers = this.prototype.__helpers.add(helpers).unique();
        return this.prototype.__helpers = this.prototype.__helpers.unique();
      };
    },
    render: function(template, locals, parentStackPointer) {
      if (locals == null) {
        locals = {};
      }
      if (parentStackPointer == null) {
        parentStackPointer = false;
      }
      return this.__render(false, template, locals, parentStackPointer);
    },
    renderDynamic: function(template, locals, parentStackPointer) {
      if (locals == null) {
        locals = {};
      }
      if (parentStackPointer == null) {
        parentStackPointer = false;
      }
      return this.__render(true, template, locals, parentStackPointer);
    },
    __assignHelpers: function() {
      var _this = this;
      if (this.__helpers == null) {
        return;
      }
      if (!this.hasOwnProperty("__helpers")) {
        this.__helpers = this.__helpers.clone();
      }
      return this.__helpers.each(function(helper, i) {
        if (!Object.isObject(helper)) {
          if (_this[helper] == null) {
            throw new Error("Cannot find method '" + helper + "' to use as helper");
          }
          _this.__helpers[i] = {};
          return _this.__helpers[i][helper] = function() {
            return _this[helper].apply(_this, arguments);
          };
        }
      });
    },
    __instantiateHelpers: function() {
      var helper, _i, _len, _ref;
      if (!this.__helpersInstance) {
        this.__assignHelpers();
        this.__helpersInstance = {};
        this.__helpersInstance.__renderer = this;
        Joosy.Module.merge(this.__helpersInstance, Joosy.Helpers.Application);
        if (Joosy.Helpers.Routes != null) {
          Joosy.Module.merge(this.__helpersInstance, Joosy.Helpers.Routes);
        }
        if (this.__helpers) {
          _ref = this.__helpers;
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            helper = _ref[_i];
            Joosy.Module.merge(this.__helpersInstance, helper);
          }
        }
      }
      return this.__helpersInstance;
    },
    __instantiateRenderers: function(parentStackPointer) {
      var _this = this;
      return {
        render: function(template, locals) {
          if (locals == null) {
            locals = {};
          }
          return _this.render(template, locals, parentStackPointer);
        },
        renderDynamic: function(template, locals) {
          if (locals == null) {
            locals = {};
          }
          return _this.renderDynamic(template, locals, parentStackPointer);
        },
        renderInline: function(locals, template) {
          if (locals == null) {
            locals = {};
          }
          return _this.renderDynamic(template, locals, parentStackPointer);
        }
      };
    },
    __render: function(dynamic, template, locals, parentStackPointer) {
      var binding, context, key, morph, object, result, stack, update,
        _this = this;
      if (locals == null) {
        locals = {};
      }
      if (parentStackPointer == null) {
        parentStackPointer = false;
      }
      stack = this.__renderingStackChildFor(parentStackPointer);
      stack.template = template;
      stack.locals = locals;
      if (Object.isString(template)) {
        if (this.__renderSection != null) {
          template = Joosy.templater().resolveTemplate(this.__renderSection(), template, this);
        }
        template = Joosy.templater().buildView(template);
      } else if (!Object.isFunction(template)) {
        throw new Error("" + (Joosy.Module.__className(this)) + "> template (maybe @view) does not look like a string or lambda");
      }
      if (!Object.isObject(locals) && Object.extended().constructor !== locals.constructor) {
        throw new Error("" + (Joosy.Module.__className(this)) + "> locals (maybe @data?) is not a hash");
      }
      context = function() {
        var data;
        data = {};
        Joosy.Module.merge(data, stack.locals);
        Joosy.Module.merge(data, _this.__instantiateHelpers(), false);
        Joosy.Module.merge(data, _this.__instantiateRenderers(stack));
        return data;
      };
      result = function() {
        return template(context());
      };
      if (dynamic) {
        morph = Metamorph(result());
        update = function() {
          var binding, child, object, _i, _j, _len, _len1, _ref, _ref1, _ref2, _results;
          if (morph.isRemoved()) {
            _ref = morph.__bindings;
            _results = [];
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              _ref1 = _ref[_i], object = _ref1[0], binding = _ref1[1];
              _results.push(object.unbind(binding));
            }
            return _results;
          } else {
            _ref2 = stack.children;
            for (_j = 0, _len1 = _ref2.length; _j < _len1; _j++) {
              child = _ref2[_j];
              _this.__removeMetamorphs(child);
            }
            stack.children = [];
            return morph.html(result());
          }
        };
        update = update.debounce(0);
        for (key in locals) {
          object = locals[key];
          if (locals.hasOwnProperty(key)) {
            if (((object != null ? object.bind : void 0) != null) && ((object != null ? object.unbind : void 0) != null)) {
              binding = [object, object.bind('changed', update)];
              stack.metamorphBindings.push(binding);
            }
          }
        }
        morph.__bindings = stack.metamorphBindings;
        return morph.outerHTML();
      } else {
        return result();
      }
    },
    __renderingStackElement: function(parent) {
      if (parent == null) {
        parent = null;
      }
      return {
        metamorphBindings: [],
        locals: null,
        template: null,
        children: [],
        parent: parent
      };
    },
    __renderingStackChildFor: function(parentPointer) {
      var element;
      if (!this.__renderingStack) {
        this.__renderingStack = [];
      }
      if (!parentPointer) {
        element = this.__renderingStackElement();
        this.__renderingStack.push(element);
        return element;
      } else {
        element = this.__renderingStackElement(parentPointer);
        parentPointer.children.push(element);
        return element;
      }
    },
    __removeMetamorphs: function(stackPointer) {
      var remove, _ref,
        _this = this;
      if (stackPointer == null) {
        stackPointer = false;
      }
      remove = function(stackPointer) {
        var callback, child, object, _i, _j, _len, _len1, _ref, _ref1, _ref2;
        if (stackPointer != null ? stackPointer.children : void 0) {
          _ref = stackPointer.children;
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            child = _ref[_i];
            _this.__removeMetamorphs(child);
          }
        }
        if (stackPointer != null ? stackPointer.metamorphBindings : void 0) {
          _ref1 = stackPointer.metamorphBindings;
          for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
            _ref2 = _ref1[_j], object = _ref2[0], callback = _ref2[1];
            object.unbind(callback);
          }
          return stackPointer.metamorphBindings = [];
        }
      };
      if (!stackPointer) {
        return (_ref = this.__renderingStack) != null ? _ref.each(function(stackPointer) {
          return remove(stackPointer);
        }) : void 0;
      } else {
        return remove(stackPointer);
      }
    }
  };

  if ((typeof define !== "undefined" && define !== null ? define.amd : void 0) != null) {
    define('joosy/modules/renderer', function() {
      return Joosy.Modules.Renderer;
    });
  }

}).call(this);
(function() {
  Joosy.Modules.TimeManager = {
    setTimeout: function(timeout, action) {
      var timer,
        _this = this;
      this.__timeouts || (this.__timeouts = []);
      timer = window.setTimeout((function() {
        return action();
      }), timeout);
      this.__timeouts.push(timer);
      return timer;
    },
    setInterval: function(delay, action) {
      var timer,
        _this = this;
      this.__intervals || (this.__intervals = []);
      timer = window.setInterval((function() {
        return action();
      }), delay);
      this.__intervals.push(timer);
      return timer;
    },
    clearTimeout: function(timer) {
      return window.clearTimeout(timer);
    },
    clearInterval: function(timer) {
      return window.clearInterval(timer);
    },
    __clearTime: function() {
      var entry, _i, _j, _len, _len1, _ref, _ref1, _results;
      if (this.__intervals) {
        _ref = this.__intervals;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          entry = _ref[_i];
          window.clearInterval(entry);
        }
      }
      if (this.__timeouts) {
        _ref1 = this.__timeouts;
        _results = [];
        for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
          entry = _ref1[_j];
          _results.push(window.clearTimeout(entry));
        }
        return _results;
      }
    }
  };

  if ((typeof define !== "undefined" && define !== null ? define.amd : void 0) != null) {
    define('joosy/modules/time_manager', function() {
      return Joosy.Modules.TimeManager;
    });
  }

}).call(this);
(function() {
  var __slice = [].slice;

  Joosy.Modules.Filters = {
    included: function() {
      var _this = this;
      this.__registerFilterCollector = function(filter) {
        _this[filter] = function(callback) {
          if (!this.prototype.hasOwnProperty("__" + filter + "s")) {
            this.prototype["__" + filter + "s"] = [].concat(this.__super__["__" + filter + "s"] || []);
          }
          return this.prototype["__" + filter + "s"].push(callback);
        };
        return filter.charAt(0).toUpperCase() + filter.slice(1);
      };
      this.registerPlainFilters = function() {
        var filters;
        filters = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        return filters.each(function(filter) {
          var camelized;
          camelized = _this.__registerFilterCollector(filter);
          return _this.prototype["__run" + camelized + "s"] = function() {
            var params,
              _this = this;
            params = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
            if (!this["__" + filter + "s"]) {
              return true;
            }
            return this["__" + filter + "s"].reduce(function(flag, callback) {
              if (!Object.isFunction(callback)) {
                callback = _this[callback];
              }
              return flag && callback.apply(_this, params) !== false;
            }, true);
          };
        });
      };
      return this.registerSequencedFilters = function() {
        var filters;
        filters = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        return filters.each(function(filter) {
          var camelized;
          camelized = _this.__registerFilterCollector(filter);
          return _this.prototype["__run" + camelized + "s"] = function(params, callback) {
            var filterer, runners;
            if (!this["__" + filter + "s"]) {
              return callback();
            }
            runners = this["__" + filter + "s"];
            filterer = this;
            if (runners.length === 1) {
              return runners[0].apply(this, params.include(callback));
            }
            return Joosy.synchronize(function(context) {
              runners.each(function(runner) {
                return context["do"](function(done) {
                  return runner.apply(filterer, params.include(done));
                });
              });
              return context.after(callback);
            });
          };
        });
      };
    }
  };

  if ((typeof define !== "undefined" && define !== null ? define.amd : void 0) != null) {
    define('joosy/modules/filters', function() {
      return Joosy.Modules.Filters;
    });
  }

}).call(this);
(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  Joosy.Widget = (function(_super) {
    __extends(Widget, _super);

    Widget.include(Joosy.Modules.Log);

    Widget.include(Joosy.Modules.Events);

    Widget.include(Joosy.Modules.DOM);

    Widget.include(Joosy.Modules.Renderer);

    Widget.include(Joosy.Modules.TimeManager);

    Widget.include(Joosy.Modules.Filters);

    Widget.mapWidgets = function(map) {
      if (!this.prototype.hasOwnProperty("__widgets")) {
        this.prototype.__widgets = Object.clone(this.__super__.__widgets) || {};
      }
      return Object.merge(this.prototype.__widgets, map);
    };

    Widget.independent = function() {
      return this.prototype.__independent = true;
    };

    Widget.registerPlainFilters('beforeLoad', 'afterLoad', 'afterUnload');

    Widget.registerSequencedFilters('beforePaint', 'paint', 'erase', 'fetch');

    function Widget(params, previous) {
      this.params = params;
      this.previous = previous;
    }

    Widget.prototype.registerWidget = function($container, widget) {
      if (Object.isString($container)) {
        $container = this.__normalizeSelector($container);
      }
      widget = this.__normalizeWidget(widget);
      widget.__bootstrapDefault($container);
      this.__nestedSections || (this.__nestedSections = []);
      this.__nestedSections.push(widget);
      return widget;
    };

    Widget.prototype.unregisterWidget = function(widget) {
      widget.__unload();
      return this.__nestedSections.splice(this.__nestedSections.indexOf(widget), 1);
    };

    Widget.prototype.replaceWidget = function(widget, replacement) {
      replacement = this.__normalizeWidget(replacement);
      replacement.previous = widget;
      return replacement.__bootstrapDefault(widget.$container);
    };

    Widget.prototype.navigate = function() {
      var _ref;
      return (_ref = Joosy.Router) != null ? _ref.navigate.apply(_ref, arguments) : void 0;
    };

    Widget.prototype.__renderSection = function() {
      return 'widgets';
    };

    Widget.prototype.__nestingMap = function() {
      var map, selector, widget, _ref;
      map = {};
      _ref = this.__widgets;
      for (selector in _ref) {
        widget = _ref[selector];
        widget = this.__normalizeWidget(widget);
        map[selector] = {
          instance: widget,
          nested: widget.__nestingMap()
        };
      }
      return map;
    };

    Widget.prototype.__bootstrapDefault = function($container) {
      return this.__bootstrap(this.__nestingMap(), $container);
    };

    Widget.prototype.__bootstrap = function(nestingMap, $container, fetch) {
      var _this = this;
      this.$container = $container;
      if (fetch == null) {
        fetch = true;
      }
      this.wait('section:fetched section:erased', function() {
        return _this.__runPaints([], function() {
          return _this.__paint(nestingMap, _this.$container);
        });
      });
      this.__erase();
      if (fetch) {
        return this.__fetch(nestingMap);
      }
    };

    Widget.prototype.__fetch = function(nestingMap) {
      var _this = this;
      this.data = {};
      return this.synchronize(function(context) {
        Object.each(nestingMap, function(selector, section) {
          section.instance.__fetch(section.nested);
          if (!section.instance.__independent) {
            return context["do"](function(done) {
              return section.instance.wait('section:fetched', done);
            });
          }
        });
        context["do"](function(done) {
          return _this.__runFetchs([], done);
        });
        return context.after(function() {
          return _this.trigger({
            name: 'section:fetched',
            remember: true
          });
        });
      });
    };

    Widget.prototype.__erase = function() {
      var _this = this;
      if (this.previous != null) {
        return this.previous.__runErases([], function() {
          _this.previous.__unload();
          return _this.__runBeforePaints([], function() {
            return _this.trigger({
              name: 'section:erased',
              remember: true
            });
          });
        });
      } else {
        return this.__runBeforePaints([], function() {
          return _this.trigger({
            name: 'section:erased',
            remember: true
          });
        });
      }
    };

    Widget.prototype.__paint = function(nestingMap, $container) {
      var _this = this;
      this.$container = $container;
      this.__nestedSections = [];
      this.$container.html(typeof this.__renderDefault === "function" ? this.__renderDefault(this.data || {}) : void 0);
      this.__load();
      return Object.each(nestingMap, function(selector, section) {
        var _ref;
        _this.__nestedSections.push(section.instance);
        $container = _this.__normalizeSelector(selector);
        if (!section.instance.__independent || ((_ref = section.instance.__triggeredEvents) != null ? _ref['section:fetched'] : void 0)) {
          return section.instance.__paint(section.nested, $container);
        } else {
          return section.instance.__bootstrap(section.nested, $container, false);
        }
      });
    };

    Widget.prototype.__load = function() {
      this.__assignElements();
      this.__delegateEvents();
      return this.__runAfterLoads();
    };

    Widget.prototype.__unload = function() {
      var section, _i, _len, _ref;
      _ref = this.__nestedSections;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        section = _ref[_i];
        section.__unload();
      }
      delete this.__nestedSections;
      this.__clearContainer();
      this.__clearTime();
      this.__removeMetamorphs();
      this.__runAfterUnloads();
      return delete this.previous;
    };

    Widget.prototype.__normalizeSelector = function(selector) {
      if (selector === '$container') {
        return this.$container;
      } else {
        return $(this.__extractSelector(selector), this.$container);
      }
    };

    Widget.prototype.__normalizeWidget = function(widget) {
      if (Object.isFunction(widget) && !Joosy.Module.hasAncestor(widget, Joosy.Widget)) {
        widget = widget.call(this);
      }
      if (Joosy.Module.hasAncestor(widget, Joosy.Widget)) {
        widget = new widget;
      }
      return widget;
    };

    return Widget;

  })(Joosy.Module);

  if ((typeof define !== "undefined" && define !== null ? define.amd : void 0) != null) {
    define('joosy/widget', function() {
      return Joosy.Widget;
    });
  }

}).call(this);
(function() {
  Joosy.helpers('Application', function() {
    var DOMnative, DOMtext;
    DOMtext = document.createTextNode("test");
    DOMnative = document.createElement("span");
    DOMnative.appendChild(DOMtext);
    this.escapeOnce = function(html) {
      DOMtext.nodeValue = html;
      return DOMnative.innerHTML;
    };
    this.tag = function(name, options, open, escape) {
      var element, tag, temp, value;
      if (options == null) {
        options = {};
      }
      if (open == null) {
        open = false;
      }
      if (escape == null) {
        escape = true;
      }
      element = document.createElement(name);
      temp = document.createElement('div');
      for (name in options) {
        value = options[name];
        if (escape) {
          value = this.escapeOnce(value);
        }
        element.setAttribute(name, value);
      }
      temp.appendChild(element);
      tag = temp.innerHTML;
      if (open) {
        tag = tag.replace('/>', '>');
      }
      return tag;
    };
    this.contentTag = function(name, contentOrOptions, options, escape) {
      var content, e, element, temp, value;
      if (contentOrOptions == null) {
        contentOrOptions = null;
      }
      if (options == null) {
        options = null;
      }
      if (escape == null) {
        escape = true;
      }
      if (Object.isString(contentOrOptions)) {
        options || (options = {});
        content = contentOrOptions;
      } else if (Object.isObject(contentOrOptions)) {
        if (Object.isFunction(options)) {
          escape = true;
          content = options();
        } else {
          escape = options;
          content = escape();
        }
        options = contentOrOptions;
      } else {
        options = {};
        content = contentOrOptions();
      }
      element = document.createElement(name);
      temp = document.createElement('div');
      for (name in options) {
        value = options[name];
        if (escape) {
          value = this.escapeOnce(value);
        }
        element.setAttribute(name, value);
      }
      try {
        element.innerHTML = content;
      } catch (_error) {
        e = _error;
        if (content) {
          throw e;
        }
      }
      temp.appendChild(element);
      return temp.innerHTML;
    };
    return this.renderWrapped = function(template, lambda) {
      return this.render(template, Joosy.Module.merge(this, {
        "yield": lambda()
      }));
    };
  });

}).call(this);
(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  Joosy.Layout = (function(_super) {
    __extends(Layout, _super);

    Layout.helper('page');

    function Layout(params, previous) {
      this.params = params;
      this.previous = previous;
      this.uid = Joosy.uid();
    }

    Layout.prototype.page = function(tag, options) {
      if (options == null) {
        options = {};
      }
      options.id = this.uid;
      return Joosy.Helpers.Application.tag(tag, options);
    };

    Layout.prototype.content = function() {
      return $("#" + this.uid);
    };

    Layout.prototype.__renderSection = function() {
      return 'layouts';
    };

    Layout.prototype.__nestingMap = function(page) {
      var map;
      map = Layout.__super__.__nestingMap.call(this);
      map["#" + this.uid] = {
        instance: page,
        nested: page.__nestingMap()
      };
      return map;
    };

    Layout.prototype.__bootstrapDefault = function(page, applicationContainer) {
      return this.__bootstrap(this.__nestingMap(page), applicationContainer);
    };

    return Layout;

  })(Joosy.Widget);

  if ((typeof define !== "undefined" && define !== null ? define.amd : void 0) != null) {
    define('joosy/layout', function() {
      return Joosy.Layout;
    });
  }

}).call(this);
(function() {
  Joosy.Modules.Page_Scrolling = {
    included: function() {
      this.scroll = function(element, options) {
        if (options == null) {
          options = {};
        }
        this.prototype.__scrollElement = element;
        this.prototype.__scrollSpeed = options.speed || 500;
        return this.prototype.__scrollMargin = options.margin || 0;
      };
      this.paint(function(complete) {
        if (this.__scrollElement && this.__scrollSpeed !== 0) {
          this.__fixHeight();
        }
        return complete();
      });
      return this.afterLoad(function() {
        if (this.__scrollElement) {
          return this.__performScrolling();
        }
      });
    },
    __performScrolling: function() {
      var scroll, _ref,
        _this = this;
      scroll = ((_ref = $(this.__extractSelector(this.__scrollElement)).offset()) != null ? _ref.top : void 0) + this.__scrollMargin;
      Joosy.Modules.Log.debugAs(this, "Scrolling to " + (this.__extractSelector(this.__scrollElement)));
      return $('html, body').animate({
        scrollTop: scroll
      }, this.__scrollSpeed, function() {
        if (_this.__scrollSpeed !== 0) {
          return _this.__releaseHeight();
        }
      });
    },
    __fixHeight: function() {
      return $('html').css('min-height', $(document).height());
    },
    __releaseHeight: function() {
      return $('html').css('min-height', '');
    }
  };

}).call(this);
(function() {
  Joosy.Modules.Page_Title = {
    title: function(title, separator) {
      if (separator == null) {
        separator = ' / ';
      }
      this.afterLoad(function() {
        var titleStr;
        titleStr = Object.isFunction(title) ? title.apply(this) : title;
        if (Object.isArray(titleStr)) {
          titleStr = titleStr.join(separator);
        }
        this.__previousTitle = document.title;
        return document.title = titleStr;
      });
      return this.afterUnload(function() {
        return document.title = this.__previousTitle;
      });
    }
  };

}).call(this);
(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  Joosy.Page = (function(_super) {
    __extends(Page, _super);

    Page.layout = function(layoutClass) {
      return this.prototype.__layoutClass = layoutClass;
    };

    Page.include(Joosy.Modules.Page_Scrolling);

    Page.extend(Joosy.Modules.Page_Title);

    function Page(params, previous) {
      var _ref;
      this.params = params;
      this.previous = previous;
      this.layoutShouldChange = ((_ref = this.previous) != null ? _ref.__layoutClass : void 0) !== this.__layoutClass;
      this.halted = !this.__runBeforeLoads();
      this.layout = (function() {
        var _ref1, _ref2;
        switch (false) {
          case !(this.layoutShouldChange && this.__layoutClass):
            return new this.__layoutClass(params, (_ref1 = this.previous) != null ? _ref1.layout : void 0);
          case !!this.layoutShouldChange:
            return (_ref2 = this.previous) != null ? _ref2.layout : void 0;
        }
      }).call(this);
      if (this.layoutShouldChange && !this.layout) {
        this.previous = this.previous.layout;
      }
    }

    Page.prototype.__renderSection = function() {
      return 'pages';
    };

    Page.prototype.__bootstrapDefault = function(applicationContainer) {
      var _ref;
      return this.__bootstrap(this.__nestingMap(), ((_ref = this.layout) != null ? _ref.content() : void 0) || applicationContainer);
    };

    return Page;

  })(Joosy.Widget);

  if ((typeof define !== "undefined" && define !== null ? define.amd : void 0) != null) {
    define('joosy/page', function() {
      return Joosy.Page;
    });
  }

}).call(this);
(function() {
  Joosy.helpers('Routes', function() {
    return this.linkTo = function(name, url, tagOptions) {
      if (name == null) {
        name = '';
      }
      if (url == null) {
        url = '';
      }
      if (tagOptions == null) {
        tagOptions = {};
      }
      return Joosy.Helpers.Application.contentTag('a', name, Joosy.Module.merge(tagOptions, {
        'data-joosy': true,
        href: url
      }));
    };
  });

}).call(this);
(function() {
  var _ref,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  Joosy.Router = (function(_super) {
    var Drawer,
      _this = this;

    __extends(Router, _super);

    function Router() {
      _ref = Router.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    Router.extend(Joosy.Modules.Events);

    $(window).bind('popstate', function(event) {
      if (window.history.loaded != null) {
        return Router.trigger('popstate', event);
      } else {
        return window.history.loaded = true;
      }
    });

    $(document).on('click', 'a[data-joosy]', function(event) {
      Router.navigate(event.target.getAttribute('href'));
      return false;
    });

    Drawer = (function() {
      Drawer.run = function(block, namespace, alias) {
        var context;
        if (namespace == null) {
          namespace = '';
        }
        if (alias == null) {
          alias = '';
        }
        context = new Drawer(namespace, alias);
        return block.call(context);
      };

      function Drawer(__namespace, __alias) {
        this.__namespace = __namespace;
        this.__alias = __alias;
      }

      Drawer.prototype.match = function(route, options) {
        var as;
        if (options == null) {
          options = {};
        }
        if (options.as != null) {
          if (this.__alias) {
            as = this.__alias + options.as.charAt(0).toUpperCase() + options.as.slice(1);
          } else {
            as = options.as;
          }
        }
        route = this.__namespace + route;
        return Joosy.Router.compileRoute(route, options.to, as);
      };

      Drawer.prototype.root = function(options) {
        if (options == null) {
          options = {};
        }
        return this.match("/", {
          to: options.to,
          as: options.as || 'root'
        });
      };

      Drawer.prototype.notFound = function(options) {
        if (options == null) {
          options = {};
        }
        return this.match(404, {
          to: options.to
        });
      };

      Drawer.prototype.namespace = function(name, options, block) {
        var _ref1;
        if (options == null) {
          options = {};
        }
        if (Object.isFunction(options)) {
          block = options;
          options = {};
        }
        return Drawer.run(block, this.__namespace + name, (_ref1 = options.as) != null ? _ref1.toString() : void 0);
      };

      return Drawer;

    })();

    Router.map = function(routes, namespace) {
      var _this = this;
      return Object.each(routes, function(path, to) {
        if (namespace != null) {
          path = namespace + '/' + path;
        }
        if (Object.isFunction(to) || to.prototype) {
          return _this.compileRoute(path, to);
        } else {
          return _this.map(to, path);
        }
      });
    };

    Router.draw = function(block) {
      return Drawer.run(block);
    };

    Router.setup = function(config, responder, respond) {
      var _base,
        _this = this;
      this.config = config;
      this.responder = responder;
      if (respond == null) {
        respond = true;
      }
      if (!history.pushState) {
        this.config.html5 = false;
      }
      (_base = this.config).prefix || (_base.prefix = '');
      if (this.config.html5) {
        this.config.prefix = ('/' + this.config.prefix + '/').replace(/\/{2,}/g, '/');
      }
      if (respond) {
        this.respond(this.canonizeLocation());
      }
      if (this.config.html5) {
        return this.listener = this.bind('popstate pushstate', function() {
          return _this.respond(_this.canonizeLocation());
        });
      } else {
        return $(window).bind('hashchange.JoosyRouter', function() {
          return _this.respond(_this.canonizeLocation());
        });
      }
    };

    Router.reset = function() {
      this.unbind(this.listener);
      $(window).unbind('.JoosyRouter');
      this.restriction = false;
      return this.routes = {};
    };

    Router.restrict = function(restriction) {
      this.restriction = restriction;
    };

    Router.navigate = function(to, options) {
      var path;
      if (options == null) {
        options = {};
      }
      path = to;
      if (this.config.html5) {
        if (path[0] === '/') {
          path = path.substr(1);
        }
        path = this.config.prefix + path;
      } else {
        if (path[0] === '#') {
          path = path.substr(1);
        }
        if (this.config.prefix && !path.startsWith(this.config.prefix)) {
          path = this.config.prefix + path;
        }
      }
      if (this.config.html5) {
        history.pushState({}, '', path);
        this.trigger('pushstate');
      } else {
        location.hash = path;
      }
    };

    Router.canonizeLocation = function() {
      if (this.config.html5) {
        return location.pathname.replace(RegExp("^" + (RegExp.escape(this.config.prefix)) + "?"), '/') + location.search;
      } else {
        return location.hash.replace(RegExp("^\\#(" + this.config.prefix + ")?\\/?"), '/');
      }
    };

    Router.compileRoute = function(path, to, as) {
      var matcher, params, result;
      if (path.toString() === '404') {
        this.wildcardAction = to;
        return;
      }
      if (path[0] === '/') {
        path = path.substr(1);
      }
      matcher = path.replace(/\/{2,}/g, '/');
      result = {};
      matcher = matcher.replace(/\/:([^\/]+)/g, '/([^/]+)');
      matcher = matcher.replace(/^\/?/, '^/?');
      matcher = matcher.replace(/\/?$/, '/?$');
      params = (path.match(/\/:[^\/]+/g) || []).map(function(str) {
        return str.substr(2);
      });
      this.routes || (this.routes = {});
      this.routes[matcher] = {
        to: to,
        capture: params,
        as: as
      };
      if (as != null) {
        return this.defineHelpers(path, as);
      }
    };

    Router.respond = function(path) {
      var match, query, regex, route, _ref1, _ref2;
      Joosy.Modules.Log.debug("Router> Answering '" + path + "'");
      if (this.restriction && path.match(this.restriction) === null) {
        this.trigger('restricted', path);
        return;
      }
      _ref1 = path.split('?'), path = _ref1[0], query = _ref1[1];
      query = (query != null ? typeof query.split === "function" ? query.split('&') : void 0 : void 0) || [];
      _ref2 = this.routes;
      for (regex in _ref2) {
        route = _ref2[regex];
        if (this.routes.hasOwnProperty(regex)) {
          if (match = path.match(new RegExp(regex))) {
            this.responder(route.to, this.__grabParams(query, route, match));
            this.trigger('responded', path);
            return;
          }
        }
      }
      if (this.wildcardAction != null) {
        this.responder(this.wildcardAction, path);
        return this.trigger('responded');
      } else {
        return this.trigger('missed');
      }
    };

    Router.defineHelpers = function(path, as) {
      var helper;
      helper = function(options) {
        var result, _ref1;
        result = path;
        if ((_ref1 = path.match(/\/:[^\/]+/g)) != null) {
          if (typeof _ref1.each === "function") {
            _ref1.each(function(param) {
              return result = result.replace(param.substr(1), options[param.substr(2)]);
            });
          }
        }
        if (Joosy.Router.config.html5) {
          return "" + Joosy.Router.config.prefix + result;
        } else {
          return "#" + Joosy.Router.config.prefix + result;
        }
      };
      return Joosy.helpers('Routes', function() {
        this["" + as + "Path"] = helper;
        return this["" + as + "Url"] = function(options) {
          if (Joosy.Router.config.html5) {
            return "" + location.origin + (helper(options));
          } else {
            return "" + location.origin + location.pathname + (helper(options));
          }
        };
      });
    };

    Router.__grabParams = function(query, route, match) {
      var params, _ref1;
      if (route == null) {
        route = null;
      }
      if (match == null) {
        match = [];
      }
      params = {};
      match.shift();
      if (route != null) {
        if ((_ref1 = route.capture) != null) {
          _ref1.each(function(key) {
            return params[key] = decodeURIComponent(match.shift());
          });
        }
      }
      query.each(function(entry) {
        var key, value, _ref2;
        if (!entry.isBlank()) {
          _ref2 = entry.split('='), key = _ref2[0], value = _ref2[1];
          return params[key] = value;
        }
      });
      return params;
    };

    return Router;

  }).call(this, Joosy.Module);

  if ((typeof define !== "undefined" && define !== null ? define.amd : void 0) != null) {
    define('joosy/router', function() {
      return Joosy.Router;
    });
  }

}).call(this);
(function() {
  Joosy.Templaters.JST = (function() {
    function JST(config) {
      this.config = config != null ? config : {};
      if ((this.config.prefix != null) && this.config.prefix.length > 0) {
        this.prefix = this.config.prefix;
      }
    }

    JST.prototype.buildView = function(name) {
      var haystack, path, template, _i, _len;
      template = false;
      if (this.prefix) {
        haystack = ["" + this.prefix + "/templates/" + name + "-" + (typeof I18n !== "undefined" && I18n !== null ? I18n.locale : void 0), "" + this.prefix + "/templates/" + name];
      } else {
        haystack = ["templates/" + name + "-" + (typeof I18n !== "undefined" && I18n !== null ? I18n.locale : void 0), "templates/" + name];
      }
      for (_i = 0, _len = haystack.length; _i < _len; _i++) {
        path = haystack[_i];
        if (window.JST[path]) {
          return window.JST[path];
        }
      }
      throw new Error("Template '" + name + "' not found. Checked at: '" + (haystack.join(', ')) + "'");
    };

    JST.prototype.resolveTemplate = function(section, template, entity) {
      var path, _ref, _ref1;
      if (template.startsWith('/')) {
        return template.substr(1);
      }
      path = ((_ref = entity.constructor) != null ? (_ref1 = _ref.__namespace__) != null ? _ref1.map('underscore') : void 0 : void 0) || [];
      path.unshift(section);
      return "" + (path.join('/')) + "/" + template;
    };

    return JST;

  })();

  if ((typeof define !== "undefined" && define !== null ? define.amd : void 0) != null) {
    define('joosy/templaters/jst', function() {
      return Joosy.Templaters.JST;
    });
  }

}).call(this);
(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  Joosy.Resources.Watcher = (function(_super) {
    __extends(Watcher, _super);

    Watcher.include(Joosy.Modules.Events);

    Watcher.cache = function(cacheKey) {
      return this.prototype.__cacheKey = cacheKey;
    };

    Watcher.fetcher = function(fetcher) {
      return this.prototype.__fetcher = fetcher;
    };

    Watcher.beforeLoad = function(action) {
      if (!this.prototype.hasOwnProperty('__beforeLoads')) {
        this.prototype.__beforeLoads = [].concat(this.__super__.__beforeLoads || []);
      }
      return this.prototype.__beforeLoads.push(action);
    };

    function Watcher(cacheKey, fetcher) {
      if (cacheKey == null) {
        cacheKey = false;
      }
      if (fetcher == null) {
        fetcher = false;
      }
      if (Object.isFunction(cacheKey)) {
        fetcher = cacheKey;
        cacheKey = void 0;
      }
      if (fetcher) {
        this.__fetcher = fetcher;
      }
      if (cacheKey) {
        this.__cacheKey = cacheKey;
      }
    }

    Watcher.prototype.load = function(callback) {
      var _this = this;
      if (this.__cacheKey && localStorage[this.__cacheKey]) {
        this.data = this.prepare(JSON.parse(localStorage[this.__cacheKey]));
        this.trigger('changed');
        this.refresh();
        return typeof callback === "function" ? callback(this) : void 0;
      } else {
        return this.__fetcher(function(result) {
          if (_this.__cacheKey) {
            localStorage[_this.__cacheKey] = JSON.stringify(result);
          }
          _this.data = _this.prepare(result);
          _this.trigger('changed');
          return typeof callback === "function" ? callback(_this) : void 0;
        });
      }
    };

    Watcher.prototype.clone = function() {
      var copy;
      copy = new this.constructor(this.__cacheKey, this.__fetcher);
      copy.data = Object.clone(this.data, true);
      copy.trigger('changed');
      return copy;
    };

    Watcher.prototype.refresh = function(callback) {
      var _this = this;
      return this.__fetcher(function(result) {
        if (_this.__cacheKey) {
          localStorage[_this.__cacheKey] = JSON.stringify(result);
        }
        _this.data = _this.prepare(result);
        _this.trigger('changed');
        return typeof callback === "function" ? callback(_this) : void 0;
      });
    };

    Watcher.prototype.prepare = function(data) {
      var bl, _i, _len, _ref;
      if (this.__beforeLoads != null) {
        _ref = this.__beforeLoads;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          bl = _ref[_i];
          data = bl.call(this, data);
        }
      }
      return data;
    };

    return Watcher;

  })(Joosy.Module);

  if ((typeof define !== "undefined" && define !== null ? define.amd : void 0) != null) {
    define('joosy/resources/watcher', function() {
      return Joosy.Resources.Watcher;
    });
  }

}).call(this);
(function() {
  Joosy.helpers('Application', function() {
    return this.widget = function(tag, options, widget) {
      var _this = this;
      if (widget == null) {
        widget = options;
        options = {};
      }
      options.id = Joosy.uid();
      this.__renderer.setTimeout(0, function() {
        return _this.__renderer.registerWidget($('#' + options.id), widget);
      });
      return this.tag(tag, options);
    };
  });

}).call(this);
(function() {
  Joosy.Application = (function() {
    function Application() {}

    Application.Pages = {};

    Application.Layouts = {};

    Application.Controls = {};

    Application.initialized = false;

    Application.loading = true;

    Application.config = {
      test: false,
      debug: false,
      templater: {
        prefix: ''
      },
      router: {
        html5: false,
        base: '',
        prefix: ''
      }
    };

    Application.initialize = function(selector, options) {
      var _this = this;
      this.selector = selector;
      if (options == null) {
        options = {};
      }
      if (this.initialized) {
        throw new Error('Attempted to initialize Application twice');
      }
      if (window.JoosyEnvironment != null) {
        Object.merge(this.config, window.JoosyEnvironment, true);
      }
      Object.merge(this.config, options, true);
      if (this.config.test) {
        this.forceSandbox();
      }
      Joosy.templater(new Joosy.Templaters.JST(this.config.templater));
      Joosy.debug(this.config.debug);
      Joosy.Router.setup(this.config.router, function(action, params) {
        if (Joosy.Module.hasAncestor(action, Joosy.Page)) {
          return _this.changePage(action, params);
        } else if (Object.isFunction(action)) {
          return action(params);
        } else {
          throw new "Unknown kind of route action";
        }
      });
      return this.initialized = true;
    };

    Application.reset = function() {
      var _ref;
      Joosy.Router.reset();
      Joosy.templater(false);
      Joosy.debug(false);
      if ((_ref = this.page) != null) {
        _ref.__unload();
      }
      delete this.page;
      this.loading = true;
      return this.initialized = false;
    };

    Application.content = function() {
      return $(this.selector);
    };

    Application.changePage = function(page, params) {
      var attempt;
      attempt = new page(params, this.page);
      if (!attempt.halted) {
        if (attempt.layoutShouldChange && attempt.layout) {
          attempt.layout.__bootstrapDefault(attempt, this.content());
        } else {
          attempt.__bootstrapDefault(this.content());
        }
        return this.page = attempt;
      }
    };

    Application.forceSandbox = function() {
      var sandbox;
      sandbox = Joosy.uid();
      this.selector = "#" + sandbox;
      return $('body').append($('<div/>').attr('id', sandbox).css({
        height: '0px',
        width: '0px',
        overflow: 'hidden'
      }));
    };

    return Application;

  })();

  if ((typeof define !== "undefined" && define !== null ? define.amd : void 0) != null) {
    define('joosy/application', function() {
      return Joosy.Application;
    });
  }

}).call(this);
(function() {


}).call(this);
