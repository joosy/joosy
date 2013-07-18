

/***  src/joosy/core/joosy  ***/

this.Joosy = {
  Modules: {},
  Resources: {},
  Templaters: {},
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
    return Joosy.namespace("Joosy.Helpers." + name, generator);
  },
  synchronize: function() {
    var _ref;
    if (!Joosy.Modules.Events) {
      return console.error("Events module is required to use `Joosy.synchronize'!");
    } else {
      return (_ref = Joosy.Modules.Events).synchronize.apply(_ref, arguments);
    }
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
  preloadImages: function(images, callback) {
    var checker, p, result, ticks, _i, _len;
    if (!Object.isArray(images)) {
      images = [images];
    }
    if (images.length === 0) {
      callback();
    }
    ticks = images.length;
    result = [];
    checker = function() {
      if ((ticks -= 1) === 0) {
        return typeof callback === "function" ? callback() : void 0;
      }
    };
    for (_i = 0, _len = images.length; _i < _len; _i++) {
      p = images[_i];
      result.push($('<img/>').on('load', checker).on('error', checker).attr('src', p));
    }
    return result;
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


/***  src/joosy/core/module  ***/

this.Joosy.Module = (function() {
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
    var _ref, _ref1;
    if (!((what != null) && (klass != null))) {
      return false;
    }
    _ref = [what.prototype, klass.prototype], what = _ref[0], klass = _ref[1];
    while (what) {
      if (what === klass) {
        return true;
      }
      what = (_ref1 = what.constructor) != null ? _ref1.__super__ : void 0;
    }
    return false;
  };

  Module.alias = function(method, feature, action) {
    var chained;
    chained = "" + method + "Without" + (feature.camelize());
    this.prototype[chained] = this.prototype[method];
    return this.prototype[method] = action;
  };

  Module.aliasStatic = function(method, feature, action) {
    var chained;
    chained = "" + method + "Without" + (feature.camelize());
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


/***  src/joosy/core/application  ***/

Joosy.Application = {
  Pages: {},
  Layouts: {},
  Controls: {},
  loading: true,
  identity: true,
  debounceForms: false,
  config: {
    debug: false,
    router: {
      html5: false,
      base: '/'
    }
  },
  initialize: function(name, selector, options) {
    this.name = name;
    this.selector = selector;
    if (options == null) {
      options = {};
    }
    if (window.JoosyEnvironment != null) {
      this.mergeConfig(window.JoosyEnvironment);
    }
    this.mergeConfig(options);
    this.templater = new Joosy.Templaters.RailsJST(this.name);
    return Joosy.Router.__setupRoutes();
  },
  content: function() {
    return $(this.selector);
  },
  sandbox: function() {
    return $(this.sandboxSelector);
  },
  setCurrentPage: function(page, params) {
    var attempt;
    attempt = new page(params, this.page);
    if (!attempt.halted) {
      return this.page = attempt;
    }
  },
  mergeConfig: function(options) {
    var key, value, _results;
    _results = [];
    for (key in options) {
      value = options[key];
      if (Object.isObject(this.config[key])) {
        _results.push(Object.merge(this.config[key], value));
      } else {
        _results.push(this.config[key] = value);
      }
    }
    return _results;
  }
};


/***  src/joosy/core/helpers/view  ***/

Joosy.helpers('Application', function() {
  this.tag = function(name, options, content) {
    var e, element, temp;
    if (options == null) {
      options = {};
    }
    if (content == null) {
      content = '';
    }
    if (Object.isFunction(content)) {
      content = content();
    }
    element = document.createElement(name);
    temp = document.createElement('div');
    Object.each(options, function(name, value) {
      return element.setAttribute(name, value);
    });
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


/***  src/joosy/core/helpers/widgets  ***/

Joosy.helpers('Application', function() {
  return this.widget = function(element, widget) {
    var params, parts, uuid;
    uuid = Joosy.uid();
    params = {
      id: uuid
    };
    parts = element.split('.');
    if (parts[1]) {
      params["class"] = parts.from(1).join(' ');
    }
    return this.tag(parts[0], params);
  };
});


/***  src/joosy/core/modules/log  ***/

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
    if (!Joosy.Application.config.debug) {
      return;
    }
    return this.log.apply(this, args);
  },
  debugAs: function() {
    var args, context, string;
    context = arguments[0], string = arguments[1], args = 3 <= arguments.length ? __slice.call(arguments, 2) : [];
    if (!Joosy.Application.config.debug) {
      return;
    }
    context = Joosy.Module.__className(context) || 'unknown context';
    return this.debug.apply(this, ["" + context + "> " + string].concat(__slice.call(args)));
  }
};


/***  src/joosy/core/modules/events  ***/

var __slice = [].slice;

Joosy.Modules.Events = {
  wait: function(name, events, callback) {
    this.__oneShotEvents || (this.__oneShotEvents = {});
    if (Object.isFunction(events)) {
      callback = events;
      events = name;
      name = Object.keys(this.__oneShotEvents).length.toString();
    }
    events = this.__splitEvents(events);
    this.__validateEvents(events);
    this.__oneShotEvents[name] = [events, callback];
    return name;
  },
  unwait: function(target) {
    return delete this.__oneShotEvents[target];
  },
  bind: function(name, events, callback) {
    this.__boundEvents || (this.__boundEvents = {});
    if (Object.isFunction(events)) {
      callback = events;
      events = name;
      name = Object.keys(this.__boundEvents).length.toString();
    }
    events = this.__splitEvents(events);
    this.__validateEvents(events);
    this.__boundEvents[name] = [events, callback];
    return name;
  },
  unbind: function(target) {
    return delete this.__boundEvents[target];
  },
  trigger: function() {
    var callback, data, event, events, fire, name, _ref, _ref1, _ref2, _ref3, _results,
      _this = this;
    event = arguments[0], data = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    Joosy.Modules.Log.debugAs(this, "Event " + event + " triggered");
    if (this.__oneShotEvents) {
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
    if (this.__boundEvents) {
      _ref2 = this.__boundEvents;
      _results = [];
      for (name in _ref2) {
        _ref3 = _ref2[name], events = _ref3[0], callback = _ref3[1];
        if (events.any(event)) {
          _results.push(callback.apply(null, data));
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    }
  },
  synchronize: function(block) {
    var context,
      _this = this;
    context = new Joosy.Events.SynchronizationContext(this);
    block.call(this, context);
    if (context.expectations.length === 0) {
      return context.after.call(this);
    } else {
      this.wait(context.expectations, function() {
        return context.after.call(_this);
      });
      return context.actions.each(function(data) {
        return data[0].call(_this, function() {
          return _this.trigger(data[1]);
        });
      });
    }
  },
  __splitEvents: function(events) {
    if (Object.isString(events)) {
      if (events.isBlank()) {
        return [];
      } else {
        return events.trim().split(/\s+/);
      }
    } else {
      return events;
    }
  },
  __validateEvents: function(events) {
    if (!(Object.isArray(events) && events.length > 0)) {
      throw new Error("" + (Joosy.Module.__className(this)) + "> bind invalid events: " + events);
    }
  }
};

Joosy.Events = {};

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

Joosy.Events.SynchronizationContext = (function() {
  SynchronizationContext.uid = 0;

  function SynchronizationContext(parent) {
    this.parent = parent;
    this.expectations = [];
    this.actions = [];
  }

  SynchronizationContext.prototype.uid = function() {
    return this.constructor.uid += 1;
  };

  SynchronizationContext.prototype["do"] = function(action) {
    var event;
    event = "synchro-" + (this.uid());
    this.expectations.push(event);
    return this.actions.push([action, event]);
  };

  SynchronizationContext.prototype.after = function(after) {
    this.after = after;
  };

  return SynchronizationContext;

})();


/***  src/joosy/core/modules/container  ***/

Joosy.Modules.Container = {
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
  $: function(selector) {
    return $(selector, this.container);
  },
  reloadContainer: function(htmlCallback) {
    if (typeof this.__removeMetamorphs === "function") {
      this.__removeMetamorphs();
    }
    return this.container.html(htmlCallback());
  },
  swapContainer: function(container, data) {
    container.unbind().off();
    container.html(data);
    return container;
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
    var _this = this;
    root || (root = this);
    entries || (entries = this.__elements);
    if (!entries) {
      return;
    }
    return Object.each(entries, function(key, value) {
      if (Object.isObject(value)) {
        return _this.__assignElements(root['$' + key] = {}, value);
      } else {
        value = _this.__extractSelector(value);
        root['$' + key] = function(filter) {
          if (!filter) {
            return _this.$(value);
          }
          return _this.$(value).filter(filter);
        };
        return root['$' + key].selector = value;
      }
    });
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
        _this.container.bind(eventName, callback);
        return Joosy.Modules.Log.debugAs(_this, "" + eventName + " binded on container");
      } else if (selector === void 0) {
        throw new Error("Unknown element " + match[2] + " in " + (Joosy.Module.__className(_this.constructor)) + " (maybe typo?)");
      } else {
        _this.container.on(eventName, selector, callback);
        return Joosy.Modules.Log.debugAs(_this, "" + eventName + " binded on " + selector);
      }
    });
  }
};


/***  src/joosy/core/templaters/rails_jst  ***/

Joosy.Templaters.RailsJST = (function() {
  function RailsJST(applicationName) {
    this.applicationName = applicationName;
  }

  RailsJST.prototype.buildView = function(name) {
    var haystack, template;
    template = false;
    haystack = ["" + this.applicationName + "/templates/" + name + "-" + (typeof I18n !== "undefined" && I18n !== null ? I18n.locale : void 0), "" + this.applicationName + "/templates/" + name, "templates/" + name + "-" + (typeof I18n !== "undefined" && I18n !== null ? I18n.locale : void 0), "templates/" + name];
    haystack.each(function(path) {
      var location;
      if (JST[path]) {
        location = path;
        return template = JST[path];
      }
    });
    if (!template) {
      throw new Error("Template '" + name + "' not found. Checked at: " + location);
    }
    return template;
  };

  RailsJST.prototype.resolveTemplate = function(section, template, entity) {
    var path, _ref, _ref1;
    if (template.startsWith('/')) {
      return template.substr(1);
    }
    path = ((_ref = entity.constructor) != null ? (_ref1 = _ref.__namespace__) != null ? _ref1.map('underscore') : void 0 : void 0) || [];
    path.unshift(section);
    return "" + (path.join('/')) + "/" + template;
  };

  return RailsJST;

})();


/***  src/vendor/metamorph  ***/

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


/***  src/joosy/core/modules/renderer  ***/

var __slice = [].slice;

Joosy.Modules.Renderer = {
  __renderer: function() {
    throw new Error("" + (Joosy.Module.__className(this.constructor)) + " does not have an attached template");
  },
  __helpers: null,
  included: function() {
    this.view = function(template, options) {
      if (options == null) {
        options = {};
      }
      if (Object.isFunction(template)) {
        return this.prototype.__renderer = template;
      } else {
        return this.prototype.__renderer = function(locals) {
          if (locals == null) {
            locals = {};
          }
          if (options.dynamic) {
            return this.renderDynamic(template, locals);
          } else {
            return this.render(template, locals);
          }
        };
      }
    };
    return this.helpers = function() {
      var helpers, _base,
        _this = this;
      helpers = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      (_base = this.prototype).__helpers || (_base.__helpers = []);
      helpers.map(function(helper) {
        var module;
        module = Joosy.Helpers[helper];
        if (!module) {
          throw new Error("Cannot find helper module " + helper);
        }
        return _this.prototype.__helpers.push(module);
      });
      return this.prototype.__helpers = this.prototype.__helpers.unique();
    };
  },
  __instantiateHelpers: function() {
    var helper, _i, _len, _ref,
      _this = this;
    if (!this.__helpersInstance) {
      this.__helpersInstance = Object.extended(Joosy.Helpers.Application);
      if (this.onRefresh) {
        this.__helpersInstance.onRefresh = function(callback) {
          return _this.onRefresh(callback);
        };
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
  __proxifyHelpers: function(locals) {
    if (locals.hasOwnProperty('__proto__')) {
      locals.__proto__ = this.__instantiateHelpers();
      return locals;
    } else {
      if (!this.__helpersProxyInstance) {
        this.__helpersProxyInstance = function(locals) {
          return Joosy.Module.merge(this, locals);
        };
        this.__helpersProxyInstance.prototype = this.__instantiateHelpers();
      }
      return new this.__helpersProxyInstance(locals);
    }
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
  __render: function(dynamic, template, locals, parentStackPointer) {
    var assignContext, binding, context, key, morph, object, renderers, result, stack, update,
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
    assignContext = false;
    if (Object.isString(template)) {
      if (this.__renderSection != null) {
        template = Joosy.Application.templater.resolveTemplate(this.__renderSection(), template, this);
      }
      template = Joosy.Application.templater.buildView(template);
    } else if (Object.isFunction(template)) {
      assignContext = true;
    } else if (!Object.isFunction(template)) {
      throw new Error("" + (Joosy.Module.__className(this)) + "> template (maybe @view) does not look like a string or lambda");
    }
    if (!Object.isObject(locals) && Object.extended().constructor !== locals.constructor) {
      throw new Error("" + (Joosy.Module.__className(this)) + "> locals (maybe @data?) is not a hash");
    }
    renderers = {
      render: function(template, locals) {
        if (locals == null) {
          locals = {};
        }
        return _this.render(template, locals, stack);
      },
      renderDynamic: function(template, locals) {
        if (locals == null) {
          locals = {};
        }
        return _this.renderDynamic(template, locals, stack);
      },
      renderInline: function(locals, template) {
        if (locals == null) {
          locals = {};
        }
        return _this.renderDynamic(template, locals, stack);
      }
    };
    context = function() {
      var data;
      data = {};
      Joosy.Module.merge(data, stack.locals);
      Joosy.Module.merge(data, _this.__instantiateHelpers(), false);
      Joosy.Module.merge(data, renderers);
      return data;
    };
    result = function() {
      if (assignContext) {
        return template.call(context());
      } else {
        return template(context());
      }
    };
    if (dynamic) {
      morph = Metamorph(result());
      update = function() {
        var callback, child, object, _i, _j, _len, _len1, _ref, _ref1, _ref2, _results;
        if (morph.isRemoved()) {
          _ref = morph.__bindings;
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            _ref1 = _ref[_i], object = _ref1[0], callback = _ref1[1];
            _results.push(object.unbind(callback));
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


/***  src/joosy/core/modules/time_manager  ***/

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


/***  src/joosy/core/modules/widgets_manager  ***/

Joosy.Modules.WidgetsManager = {
  included: function() {
    return this.mapWidgets = function(map) {
      if (!this.prototype.hasOwnProperty("__widgets")) {
        this.prototype.__widgets = Object.clone(this.__super__.__widgets) || {};
      }
      return Object.merge(this.prototype.__widgets, map);
    };
  },
  registerWidget: function(container, widget) {
    if (Joosy.Module.hasAncestor(widget, Joosy.Widget)) {
      widget = new widget();
    }
    if (Object.isFunction(widget)) {
      widget = widget();
    }
    this.__activeWidgets || (this.__activeWidgets = []);
    this.__activeWidgets.push(widget.__load(this, $(container)));
    return widget;
  },
  unregisterWidget: function(widget) {
    widget.__unload();
    return this.__activeWidgets.splice(this.__activeWidgets.indexOf(widget), 1);
  },
  __setupWidgets: function() {
    var registered, widgets,
      _this = this;
    widgets = this.__widgets;
    registered = Object.extended();
    if (!widgets) {
      return;
    }
    Object.each(widgets, function(selector, widget) {
      var activeSelector;
      if (selector === '$container') {
        activeSelector = _this.container;
      } else {
        if (_this.__extractSelector != null) {
          selector = _this.__extractSelector(selector);
        }
        activeSelector = $(selector, _this.container);
      }
      registered[selector] = Object.extended();
      return activeSelector.each(function(index, elem) {
        var instance, _base, _name;
        if (Joosy.Module.hasAncestor(widget, Joosy.Widget)) {
          instance = new widget;
        } else {
          instance = widget.call(_this, index);
        }
        (_base = registered[selector])[_name = Joosy.Module.__className(instance)] || (_base[_name] = 0);
        registered[selector][Joosy.Module.__className(instance)] += 1;
        return _this.registerWidget($(elem), instance);
      });
    });
    return registered.each(function(selector, value) {
      return value.each(function(widget, count) {
        return Joosy.Modules.Log.debugAs(_this, "Widget " + widget + " registered at '" + selector + "'. Elements: " + count);
      });
    });
  },
  __unloadWidgets: function() {
    var widget, _i, _len, _ref, _results;
    if (this.__activeWidgets) {
      _ref = this.__activeWidgets;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        widget = _ref[_i];
        _results.push(widget.__unload());
      }
      return _results;
    }
  }
};


/***  src/joosy/core/modules/filters  ***/

var _this = this,
  __slice = [].slice;

Joosy.Modules.Filters = {
  included: function() {
    var _this = this;
    return ['beforeLoad', 'afterLoad', 'afterUnload'].each(function(filter) {
      return _this[filter] = function(callback) {
        if (!this.prototype.hasOwnProperty("__" + filter + "s")) {
          this.prototype["__" + filter + "s"] = [].concat(this.__super__["__" + filter + "s"] || []);
        }
        return this.prototype["__" + filter + "s"].push(callback);
      };
    });
  }
};

['beforeLoad', 'afterLoad', 'afterUnload'].each(function(filter) {
  return Joosy.Modules.Filters["__run" + (filter.camelize(true)) + "s"] = function() {
    var opts,
      _this = this;
    opts = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    if (!this["__" + filter + "s"]) {
      return true;
    }
    return this["__" + filter + "s"].reduce(function(flag, func) {
      if (!Object.isFunction(func)) {
        func = _this[func];
      }
      return flag && func.apply(_this, opts) !== false;
    }, true);
  };
});


/***  src/joosy/core/layout  ***/

var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __slice = [].slice;

Joosy.Layout = (function(_super) {
  __extends(Layout, _super);

  Layout.include(Joosy.Modules.Log);

  Layout.include(Joosy.Modules.Events);

  Layout.include(Joosy.Modules.Container);

  Layout.include(Joosy.Modules.Renderer);

  Layout.include(Joosy.Modules.TimeManager);

  Layout.include(Joosy.Modules.WidgetsManager);

  Layout.include(Joosy.Modules.Filters);

  Layout.view('default');

  Layout.beforePaint = function(callback) {
    return this.prototype.__beforePaint = callback;
  };

  Layout.paint = function(callback) {
    return this.prototype.__paint = callback;
  };

  Layout.erase = function(callback) {
    return this.prototype.__erase = callback;
  };

  Layout.fetch = function(callback) {
    return this.prototype.__fetch = function(complete) {
      var _this = this;
      this.data = {};
      return callback.call(this, function() {
        _this.dataFetched = true;
        return complete();
      });
    };
  };

  Layout.prototype.data = false;

  Layout.prototype.dataFetched = false;

  function Layout(params) {
    this.params = params;
  }

  Layout.prototype.navigate = function() {
    var args, _ref;
    args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    return (_ref = Joosy.Router).navigate.apply(_ref, args);
  };

  Layout.prototype.__renderSection = function() {
    return 'layouts';
  };

  Layout.prototype.__load = function(container) {
    this.container = container;
    this.__assignElements();
    this.__delegateEvents();
    this.__setupWidgets();
    return this.__runAfterLoads();
  };

  Layout.prototype.__unload = function() {
    this.__clearTime();
    this.__unloadWidgets();
    this.__removeMetamorphs();
    return this.__runAfterUnloads();
  };

  Layout.prototype["yield"] = function() {
    return this.uuid = Joosy.uuid();
  };

  Layout.prototype.content = function() {
    return $("#" + this.uuid);
  };

  return Layout;

})(Joosy.Module);


/***  src/joosy/core/page  ***/

var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __slice = [].slice;

Joosy.Page = (function(_super) {
  __extends(Page, _super);

  Page.include(Joosy.Modules.Log);

  Page.include(Joosy.Modules.Events);

  Page.include(Joosy.Modules.Container);

  Page.include(Joosy.Modules.Renderer);

  Page.include(Joosy.Modules.TimeManager);

  Page.include(Joosy.Modules.WidgetsManager);

  Page.include(Joosy.Modules.Filters);

  Page.prototype.halted = false;

  Page.prototype.layout = false;

  Page.prototype.previous = false;

  Page.prototype.params = false;

  Page.prototype.data = false;

  Page.prototype.dataFetched = false;

  Page.layout = function(layoutClass) {
    return this.prototype.__layoutClass = layoutClass;
  };

  Page.beforePaint = function(callback) {
    return this.prototype.__beforePaint = callback;
  };

  Page.paint = function(callback) {
    return this.prototype.__paint = callback;
  };

  Page.afterPaint = function(callback) {
    return this.prototype.__afterPaint = callback;
  };

  Page.erase = function(callback) {
    return this.prototype.__erase = callback;
  };

  Page.fetch = function(callback) {
    return this.prototype.__fetch = function(complete) {
      var _this = this;
      this.data = {};
      return callback.call(this, function() {
        _this.dataFetched = true;
        return complete();
      });
    };
  };

  Page.fetchSynchronized = function(callback) {
    return this.prototype.__fetch = function(complete) {
      return this.synchronize(function(context) {
        context.after(function() {
          return complete();
        });
        return callback.call(this, context);
      });
    };
  };

  Page.scroll = function(element, options) {
    if (options == null) {
      options = {};
    }
    this.prototype.__scrollElement = element;
    this.prototype.__scrollSpeed = options.speed || 500;
    return this.prototype.__scrollMargin = options.margin || 0;
  };

  Page.prototype.__performScrolling = function() {
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
  };

  Page.title = function(title, separator) {
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
  };

  function Page(params, previous) {
    var _ref, _ref1, _ref2;
    this.params = params;
    this.previous = previous;
    this.__layoutClass || (this.__layoutClass = ApplicationLayout);
    if (!(this.halted = !this.__runBeforeLoads(this.params, this.previous))) {
      Joosy.Application.loading = true;
      if ((((_ref = this.previous) != null ? (_ref1 = _ref.layout) != null ? _ref1.uuid : void 0 : void 0) == null) || ((_ref2 = this.previous) != null ? _ref2.__layoutClass : void 0) !== this.__layoutClass) {
        this.__bootstrapLayout();
      } else {
        this.__bootstrap();
      }
    }
  }

  Page.prototype.navigate = function() {
    var args, _ref;
    args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    return (_ref = Joosy.Router).navigate.apply(_ref, args);
  };

  Page.prototype.__renderSection = function() {
    return 'pages';
  };

  Page.prototype.__fixHeight = function() {
    return $('html').css('min-height', $(document).height());
  };

  Page.prototype.__releaseHeight = function() {
    return $('html').css('min-height', '');
  };

  Page.prototype.__load = function() {
    this.__assignElements();
    this.__delegateEvents();
    this.__setupWidgets();
    this.__runAfterLoads(this.params, this.previous);
    if (this.__scrollElement) {
      this.__performScrolling();
    }
    Joosy.Application.loading = false;
    Joosy.Router.trigger('loaded', this);
    this.trigger('loaded');
    return Joosy.Modules.Log.debugAs(this, "Page loaded");
  };

  Page.prototype.__unload = function() {
    this.__clearTime();
    this.__unloadWidgets();
    this.__removeMetamorphs();
    this.__runAfterUnloads(this.params, this.previous);
    return delete this.previous;
  };

  Page.prototype.__callSyncedThrough = function(entity, receiver, params, callback) {
    if ((entity != null ? entity[receiver] : void 0) != null) {
      return entity[receiver].apply(entity, params.clone().add(callback));
    } else {
      return callback();
    }
  };

  Page.prototype.__bootstrap = function() {
    var callbacksParams,
      _this = this;
    Joosy.Modules.Log.debugAs(this, "Boostraping page");
    this.layout = this.previous.layout;
    callbacksParams = [this.layout.content()];
    if (this.__scrollElement && this.__scrollSpeed !== 0) {
      this.__fixHeight();
    }
    this.wait("stageClear dataReceived", function() {
      var _ref;
      if ((_ref = _this.previous) != null) {
        if (typeof _ref.__afterPaint === "function") {
          _ref.__afterPaint(callbacksParams);
        }
      }
      return _this.__callSyncedThrough(_this, '__paint', callbacksParams, function() {
        _this.swapContainer(_this.layout.content(), _this.__renderer(_this.data || {}));
        _this.container = _this.layout.content();
        _this.__load();
        return _this.layout.content();
      });
    });
    this.__callSyncedThrough(this.previous, '__erase', callbacksParams, function() {
      var _ref;
      if ((_ref = _this.previous) != null) {
        _ref.__unload();
      }
      return _this.__callSyncedThrough(_this, '__beforePaint', callbacksParams, function() {
        return _this.trigger('stageClear');
      });
    });
    return this.__callSyncedThrough(this, '__fetch', [], function() {
      Joosy.Modules.Log.debugAs(_this, "Fetch complete");
      return _this.trigger('dataReceived');
    });
  };

  Page.prototype.__bootstrapLayout = function() {
    var callbacksParams, _ref,
      _this = this;
    Joosy.Modules.Log.debugAs(this, "Boostraping page with layout");
    this.layout = new this.__layoutClass(this.params);
    callbacksParams = [Joosy.Application.content(), this];
    if (this.__scrollElement && this.__scrollSpeed !== 0) {
      this.__fixHeight();
    }
    this.wait("stageClear dataReceived", function() {
      return _this.__callSyncedThrough(_this.layout, '__paint', callbacksParams, function() {
        var data;
        data = Joosy.Module.merge({}, _this.layout.data || {});
        data = Joosy.Module.merge(data, {
          "yield": function() {
            return _this.layout["yield"]();
          }
        });
        _this.swapContainer(Joosy.Application.content(), _this.layout.__renderer(data));
        _this.swapContainer(_this.layout.content(), _this.__renderer(_this.data || {}));
        _this.container = _this.layout.content();
        _this.layout.__load(Joosy.Application.content());
        _this.__load();
        return Joosy.Application.content();
      });
    });
    this.__callSyncedThrough((_ref = this.previous) != null ? _ref.layout : void 0, '__erase', callbacksParams, function() {
      var _ref1, _ref2, _ref3;
      if ((_ref1 = _this.previous) != null) {
        if ((_ref2 = _ref1.layout) != null) {
          if (typeof _ref2.__unload === "function") {
            _ref2.__unload();
          }
        }
      }
      if ((_ref3 = _this.previous) != null) {
        _ref3.__unload();
      }
      return _this.__callSyncedThrough(_this.layout, '__beforePaint', callbacksParams, function() {
        return _this.trigger('stageClear');
      });
    });
    return this.__callSyncedThrough(this.layout, '__fetch', [], function() {
      return _this.__callSyncedThrough(_this, '__fetch', [], function() {
        Joosy.Modules.Log.debugAs(_this, "Fetch complete");
        return _this.trigger('dataReceived');
      });
    });
  };

  return Page;

})(Joosy.Module);


/***  src/joosy/core/resources/watcher  ***/

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


/***  src/joosy/core/router  ***/

Joosy.Router = {
  rawRoutes: Object.extended(),
  routes: Object.extended(),
  restrictPattern: false,
  __namespace: "",
  __asNamespace: "",
  prefix: '',
  restrict: function(restrictPattern) {
    this.restrictPattern = restrictPattern;
  },
  reset: function() {
    this.rawRoutes = Object.extended();
    this.routes = Object.extended();
    this.__namespace = "";
    return this.__asNamespace = "";
  },
  draw: function(block) {
    if (Object.isFunction(block)) {
      return block.call(this);
    }
  },
  map: function(routes) {
    return Joosy.Module.merge(this.rawRoutes, routes);
  },
  navigate: function(to, options) {
    var path,
      _this = this;
    if (options == null) {
      options = {};
    }
    path = to;
    if (path[0] === '#') {
      path = path.substr(1);
    }
    if (!path.startsWith(this.prefix)) {
      path = this.prefix + path;
    }
    if (options.respond !== false) {
      return location.hash = path;
    } else {
      if (!history.pushState) {
        this.__ignoreRequest = to;
        location.hash = path;
        return setTimeout((function() {
          return _this.__ignoreRequest = false;
        }), 0);
      } else {
        return history[options.replaceState ? 'replaceState' : 'pushState']({}, '', '#' + path);
      }
    }
  },
  match: function(route, options) {
    var as, map, routeName;
    if (options == null) {
      options = {};
    }
    if (this.__asNamespace) {
      as = this.__asNamespace + options["as"].capitalize();
    } else {
      as = options["as"];
    }
    routeName = this.__namespace + route;
    map = {};
    map[route] = options["to"];
    Joosy.Module.merge(this.rawRoutes, map);
    return this.__injectReverseUrl(as, routeName);
  },
  root: function(options) {
    var as;
    if (options == null) {
      options = {};
    }
    as = options["as"] || "root";
    return this.match("/", {
      to: options["to"],
      as: as
    });
  },
  notFound: function(options) {
    if (options == null) {
      options = {};
    }
    return this.match(404, {
      to: options["to"]
    });
  },
  namespace: function(name, options, block) {
    var newScope;
    if (options == null) {
      options = {};
    }
    if (Object.isFunction(options)) {
      block = options;
      options = {};
    }
    newScope = $.extend({}, this);
    newScope.rawRoutes = {};
    newScope.__namespace += name;
    if (options["as"]) {
      newScope.__asNamespace += "" + options["as"];
    }
    if (Object.isFunction(block)) {
      block.call(newScope);
    }
    return this.rawRoutes[name] = newScope.rawRoutes;
  },
  __setupRoutes: function() {
    var _this = this;
    $(window).on('hashchange', function() {
      if (!(_this.__ignoreRequest && location.hash.match(_this.__ignoreRequest))) {
        return _this.__respondRoute(location.hash);
      }
    });
    this.__prepareRoutes(this.rawRoutes);
    return this.__respondRoute(location.hash);
  },
  __prepareRoutes: function(routes, namespace) {
    var _this = this;
    if (namespace == null) {
      namespace = '';
    }
    if (!namespace && routes[404]) {
      this.wildcardAction = routes[404];
      delete routes[404];
    }
    return Object.each(routes, function(path, response) {
      path = (namespace + path).replace(/\/{2,}/, '/');
      if (response && (Object.isFunction(response) || (response.prototype != null))) {
        return Joosy.Module.merge(_this.routes, _this.__prepareRoute(path, response));
      } else {
        return _this.__prepareRoutes(response, path);
      }
    });
  },
  __prepareRoute: function(path, response) {
    var matchPath, result;
    matchPath = path.replace(/\/:([^\/]+)/g, '/([^/]+)').replace(/^\/?/, '^/?').replace(/\/?$/, '/?$');
    result = Object.extended();
    result[matchPath] = {
      capture: (path.match(/\/:[^\/]+/g) || []).map(function(str) {
        return str.substr(2);
      }),
      action: response
    };
    return result;
  },
  __respondRoute: function(hash) {
    var found, fullPath, params, path, queryArray, regex, route, urlParams, vals, _ref;
    Joosy.Modules.Log.debug("Router> Answering '" + hash + "'");
    fullPath = hash.replace(RegExp("^\\#(" + this.prefix + ")?"), '');
    if (this.restrictPattern && fullPath.match(this.restrictPattern) === null) {
      this.trigger('restricted', fullPath);
      return;
    } else {
      this.trigger('responded', fullPath);
    }
    this.currentPath = fullPath;
    found = false;
    queryArray = fullPath.split('&');
    path = queryArray.shift();
    urlParams = this.__paramsFromQueryArray(queryArray);
    _ref = this.routes;
    for (regex in _ref) {
      route = _ref[regex];
      if (this.routes.hasOwnProperty(regex)) {
        if (vals = path.match(new RegExp(regex))) {
          params = this.__paramsFromRouteMatch(vals, route).merge(urlParams);
          if (Joosy.Module.hasAncestor(route.action, Joosy.Page)) {
            Joosy.Application.setCurrentPage(route.action, params);
          } else {
            route.action.call(this, params);
          }
          found = true;
          break;
        }
      }
    }
    if (!found && (this.wildcardAction != null)) {
      if (Joosy.Module.hasAncestor(this.wildcardAction, Joosy.Page)) {
        return Joosy.Application.setCurrentPage(this.wildcardAction, urlParams);
      } else {
        return this.wildcardAction(path, urlParams);
      }
    }
  },
  __paramsFromRouteMatch: function(vals, route) {
    var param, params, _i, _len, _ref;
    params = Object.extended();
    vals.shift();
    _ref = route.capture;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      param = _ref[_i];
      params[param] = vals.shift();
    }
    return params;
  },
  __paramsFromQueryArray: function(queryArray) {
    var params;
    params = Object.extended();
    if (queryArray) {
      $.each(queryArray, function() {
        var pair;
        if (!this.isBlank()) {
          pair = this.split('=');
          return params[pair[0]] = pair[1];
        }
      });
    }
    return params;
  },
  __injectReverseUrl: function(as, route) {
    var fnc,
      _this = this;
    if (as === void 0) {
      return;
    }
    fnc = function(options) {
      var url;
      url = route;
      (route.match(/\/:[^\/]+/g) || []).each(function(str) {
        return url = url.replace(str.substr(1), options[str.substr(2)]);
      });
      return "#" + _this.prefix + url;
    };
    Joosy.Helpers.Application["" + as + "Path"] = function(options) {
      return fnc(options);
    };
    return Joosy.Helpers.Application["" + as + "Url"] = function(options) {
      var url;
      url = 'http://' + window.location.host + window.location.pathname;
      return "" + url + (fnc(options));
    };
  }
};

Joosy.Module.merge(Joosy.Router, Joosy.Modules.Events);


/***  src/joosy/core/widget  ***/

var _ref,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __slice = [].slice;

Joosy.Widget = (function(_super) {
  __extends(Widget, _super);

  function Widget() {
    _ref = Widget.__super__.constructor.apply(this, arguments);
    return _ref;
  }

  Widget.include(Joosy.Modules.Log);

  Widget.include(Joosy.Modules.Events);

  Widget.include(Joosy.Modules.Container);

  Widget.include(Joosy.Modules.Renderer);

  Widget.include(Joosy.Modules.Filters);

  Widget.include(Joosy.Modules.TimeManager);

  Widget.include(Joosy.Modules.WidgetsManager);

  Widget.prototype.__renderer = false;

  Widget.prototype.data = false;

  Widget.prototype.navigate = function() {
    var args, _ref1;
    args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    return (_ref1 = Joosy.Router).navigate.apply(_ref1, args);
  };

  Widget.prototype.__renderSection = function() {
    return 'widgets';
  };

  Widget.prototype.__load = function(parent, container, render) {
    this.parent = parent;
    this.container = container;
    if (render == null) {
      render = true;
    }
    this.__runBeforeLoads();
    if (render && this.__renderer) {
      this.swapContainer(this.container, this.__renderer(this.data || {}));
    }
    this.__assignElements();
    this.__delegateEvents();
    this.__setupWidgets();
    this.__runAfterLoads();
    return this;
  };

  Widget.prototype.__unload = function() {
    this.__clearTime();
    this.__unloadWidgets();
    this.__removeMetamorphs();
    return this.__runAfterUnloads();
  };

  return Widget;

})(Joosy.Module);


/***  src/joosy  ***/


;
