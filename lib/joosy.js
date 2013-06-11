

/***  src/joosy/core/joosy  ***/

var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

this.Joosy = {
  Modules: {},
  Resource: {},
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
      space = space[part] != null ? space[part] : space[part] = {};
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
  test: function() {
    var text;
    text = "Hi :). I'm Joosy. And everything is just fine!";
    if (console) {
      return console.log(text);
    } else {
      return alert(text);
    }
  },
  synchronize: function() {
    var _ref;
    return (_ref = Joosy.Modules.Events).synchronize.apply(_ref, arguments);
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
      result.push($('<img/>').load(checker).error(checker).attr('src', p));
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
  },
  defineResources: function(resources) {
    return Object.extended(resources).each(function(namespace, resources) {
      if (namespace.isBlank()) {
        return Object.extended(resources).each(function(resource, path) {
          return Joosy.defineResource(resource, path);
        });
      } else {
        return Joosy.namespace(namespace, function() {
          var _this = this;
          return Object.extended(resources).each(function(resource, path) {
            return Joosy.defineResource(resource, path, _this);
          });
        });
      }
    });
  },
  defineResource: function(resource, path, space) {
    var className, collectionName, _ref, _ref1;
    if (space == null) {
      space = window;
    }
    className = resource.camelize();
    collectionName = "" + (resource.pluralize().camelize()) + "Collection";
    if (!space[className]) {
      Joosy.Modules.Log.debugAs(space, "Define " + className);
      space[className] = (function(_super) {
        __extends(_Class, _super);

        function _Class() {
          _ref = _Class.__super__.constructor.apply(this, arguments);
          return _ref;
        }

        _Class.entity(resource);

        _Class.source(path);

        _Class.prototype.__collection = function() {
          return space[collectionName];
        };

        return _Class;

      })(Joosy.Resource.REST);
    }
    if (!space[collectionName]) {
      Joosy.Modules.Log.debugAs(space, "Define " + collectionName);
      return space[collectionName] = (function(_super) {
        __extends(_Class, _super);

        function _Class() {
          _ref1 = _Class.__super__.constructor.apply(this, arguments);
          return _ref1;
        }

        _Class.model(space[className]);

        return _Class;

      })(Joosy.Resource.RESTCollection);
    }
  }
};


/***  src/joosy/core/application  ***/

Joosy.Application = {
  Pages: {},
  Layouts: {},
  Controls: {},
  loading: true,
  identity: true,
  debug: false,
  debounceForms: false,
  initialize: function(name, selector, options) {
    var key, value;
    this.name = name;
    this.selector = selector;
    if (options == null) {
      options = {};
    }
    for (key in options) {
      value = options[key];
      this[key] = value;
    }
    this.templater = new Joosy.Templaters.RailsJST(this.name);
    Joosy.Router.__setupRoutes();
    this.sandboxSelector = Joosy.uuid();
    this.content().after("<div id='" + this.sandboxSelector + "' style='display:none'></div>");
    return this.sandboxSelector = '#' + this.sandboxSelector;
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
  }
};


/***  src/joosy/core/modules/module  ***/

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
    if (!Joosy.Application.debug) {
      return;
    }
    return this.log.apply(this, args);
  },
  debugAs: function() {
    var args, context, string;
    context = arguments[0], string = arguments[1], args = 3 <= arguments.length ? __slice.call(arguments, 2) : [];
    if (!Joosy.Application.debug) {
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
    this.__oneShotEvents || (this.__oneShotEvents = Object.extended());
    if (Object.isFunction(events)) {
      callback = events;
      events = name;
      name = this.__oneShotEvents.keys().length.toString();
    }
    events = this.__splitEvents(events);
    this.__validateEvents(events);
    this.__oneShotEvents[name] = [events, callback];
    return name;
  },
  bind: function(name, events, callback) {
    this.__boundEvents || (this.__boundEvents = Object.extended());
    if (Object.isFunction(events)) {
      callback = events;
      events = name;
      name = this.__boundEvents.keys().length.toString();
    }
    events = this.__splitEvents(events);
    this.__validateEvents(events);
    this.__boundEvents[name] = [events, callback];
    return name;
  },
  unbind: function(target) {
    var callback, events, name, needle, _ref, _ref1;
    needle = void 0;
    _ref = this.__boundEvents;
    for (name in _ref) {
      _ref1 = _ref[name], events = _ref1[0], callback = _ref1[1];
      if ((Object.isFunction(target) && callback === target) || name === target) {
        needle = name;
        break;
      }
    }
    if (needle != null) {
      return delete this.__boundEvents[needle];
    }
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
  events: false,
  elements: false,
  eventSplitter: /^(\S+)\s*(.*)$/,
  onRefresh: function(callback) {
    if (!this.hasOwnProperty("__onRefreshes")) {
      this.__onRefreshes = [];
    }
    return this.__onRefreshes.push(callback);
  },
  $: function(selector) {
    return $(selector, this.container);
  },
  refreshElements: function() {
    var _this = this;
    this.__collectElements().each(function(key, value) {
      return _this[key] = _this.$(value);
    });
    if (this.hasOwnProperty("__onRefreshes")) {
      this.__onRefreshes.each(function(callback) {
        return callback.apply(_this);
      });
      return this.__onRefreshes = [];
    }
  },
  reloadContainer: function(htmlCallback) {
    if (typeof this.__removeMetamorphs === "function") {
      this.__removeMetamorphs();
    }
    this.container.html(htmlCallback());
    return this.refreshElements();
  },
  swapContainer: function(container, data) {
    container.unbind().off();
    container.html(data);
    return container;
  },
  __collectElements: function() {
    var elements, klass;
    elements = Object.extended(this.elements || {});
    klass = this;
    while (klass = klass.constructor.__super__) {
      Joosy.Module.merge(elements, klass.elements, false);
    }
    return elements;
  },
  __collectEvents: function() {
    var events, klass;
    events = Object.extended(this.events || {});
    klass = this;
    while (klass = klass.constructor.__super__) {
      Joosy.Module.merge(events, klass.events, false);
    }
    return events;
  },
  __extractSelector: function(selector) {
    var r;
    if (r = selector.match(/\$([A-z]+)/)) {
      selector = this.__collectElements()[r[1]];
    }
    return selector;
  },
  __delegateEvents: function() {
    var events, module,
      _this = this;
    module = this;
    events = this.__collectEvents();
    return events.each(function(key, method) {
      var callback, eventName, match, selector;
      if (!Object.isFunction(method)) {
        method = _this[method];
      }
      callback = function(event) {
        return method.call(module, this, event);
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


/***  src/joosy/core/form  ***/

var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Joosy.Form = (function(_super) {
  __extends(Form, _super);

  Form.include(Joosy.Modules.Container);

  Form.include(Joosy.Modules.Log);

  Form.include(Joosy.Modules.Events);

  Form.prototype.invalidationClass = 'field_with_errors';

  Form.prototype.substitutions = {};

  Form.prototype.elements = {
    'fields': 'input,select,textarea'
  };

  Form.submit = function(form, options) {
    if (options == null) {
      options = {};
    }
    form = new this(form, options);
    form.container.submit();
    form.unbind();
    return null;
  };

  Form.attach = function() {
    return (function(func, args, ctor) {
      ctor.prototype = func.prototype;
      var child = new ctor, result = func.apply(child, args);
      return Object(result) === result ? result : child;
    })(Joosy.Form, arguments, function(){});
  };

  function Form(form, options) {
    var method, _ref,
      _this = this;
    if (options == null) {
      options = {};
    }
    if (Object.isFunction(options)) {
      this.success = options;
    } else {
      Object.each(options, function(key, value) {
        return _this[key] = value;
      });
    }
    this.container = $(form);
    if (this.container.length === 0) {
      return;
    }
    this.refreshElements();
    this.__delegateEvents();
    method = (_ref = this.container.get(0).getAttribute('method')) != null ? _ref.toLowerCase() : void 0;
    if (method && !['get', 'post'].any(method)) {
      this.__markMethod(method);
      this.container.attr('method', 'POST');
    }
    this.container.ajaxForm({
      dataType: 'json',
      beforeSend: function() {
        if (_this.__debounce.apply(_this, arguments)) {
          return false;
        }
        _this.__before.apply(_this, arguments);
        _this.__pending_request = true;
        _this.debugAs(_this, 'beforeSend: pending_request = true');
        return true;
      },
      success: function() {
        _this.__pending_request = false;
        _this.debugAs(_this, 'success: pending_request = false');
        return _this.__success.apply(_this, arguments);
      },
      error: function() {
        _this.__pending_request = false;
        _this.debugAs(_this, 'error: pending_request = false');
        return _this.__error.apply(_this, arguments);
      },
      xhr: function() {
        var xhr;
        xhr = $.ajaxSettings.xhr();
        if ((xhr.upload != null) && _this.progress) {
          xhr.upload.onprogress = function(event) {
            if (event.lengthComputable) {
              return _this.progress((event.position / event.total * 100).round(2));
            }
          };
        }
        return xhr;
      }
    });
    if (this.resource != null) {
      this.fill(this.resource, options);
      delete this.resource;
    }
    if (this.action != null) {
      this.container.attr('action', this.action);
      this.container.attr('method', 'POST');
    }
    if (this.method != null) {
      this.__markMethod(this.method);
    }
  }

  Form.prototype.unbind = function() {
    return this.container.unbind('submit').find('input:submit,input:image,button:submit').unbind('click');
  };

  Form.prototype.fill = function(resource, options) {
    var data, filler, url,
      _this = this;
    if (Object.isFunction(resource.build)) {
      resource = resource.build();
    }
    this.__resource = resource;
    if ((options != null ? options.decorator : void 0) != null) {
      data = options.decorator(resource.data);
    } else {
      data = resource.data;
    }
    filler = function(data, scope) {
      if (data.__joosy_form_filler_lock) {
        return;
      }
      data.__joosy_form_filler_lock = true;
      Object.each(data, function(property, val) {
        var entity, i, input, key, _i, _len, _ref, _results;
        key = _this.concatFieldName(scope, property);
        input = _this.fields.filter("[name='" + key + "']:not(:file),[name='" + (key.underscore()) + "']:not(:file),[name='" + (key.camelize(false)) + "']:not(:file)");
        if (input.length > 0) {
          if (input.is(':checkbox')) {
            if (val) {
              input.attr('checked', 'checked');
            } else {
              input.removeAttr('checked');
            }
          } else if (input.is(':radio')) {
            input.filter("[value='" + val + "']").attr('checked', 'checked');
          } else {
            input.val(val);
          }
        }
        if (val instanceof Joosy.Resource.RESTCollection) {
          _ref = val.data;
          _results = [];
          for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
            entity = _ref[i];
            _results.push(filler(entity.data, _this.concatFieldName(scope, "[" + property + "_attributes][" + i + "]")));
          }
          return _results;
        } else if (val instanceof Joosy.Resource.REST) {
          return filler(val.data, _this.concatFieldName(scope, "[" + property + "_attributes][0]"));
        } else if (Object.isObject(val) || Object.isArray(val)) {
          return filler(val, key);
        } else {

        }
      });
      return delete data.__joosy_form_filler_lock;
    };
    filler(data, resource.__entityName || options.resourceName);
    $('input[name=_method]', this.container).remove();
    if (resource.id()) {
      this.__markMethod((options != null ? options.method : void 0) || 'PUT');
    }
    url = (options != null ? options.action : void 0) || (resource.id() != null ? resource.memberPath() : resource.collectionPath());
    this.container.attr('action', url);
    return this.container.attr('method', 'POST');
  };

  Form.prototype.submit = function() {
    return this.container.submit();
  };

  Form.prototype.serialize = function(skipMethod) {
    var data;
    if (skipMethod == null) {
      skipMethod = true;
    }
    data = this.container.serialize();
    if (skipMethod) {
      data = data.replace(/\&?\_method\=put/i, '');
    }
    return data;
  };

  Form.prototype.__success = function(response, status, xhr) {
    var _ref;
    if (xhr) {
      return typeof this.success === "function" ? this.success(response) : void 0;
    } else if ((200 <= (_ref = response.status) && _ref < 300)) {
      return this.success(response.json);
    } else {
      return this.__error(response.json);
    }
  };

  Form.prototype.__before = function(xhr, settings) {
    if ((this.before == null) || this.before.apply(this, arguments) === true) {
      return this.fields.removeClass(this.invalidationClass);
    }
  };

  Form.prototype.__error = function(data) {
    var error, errors,
      _this = this;
    errors = (function() {
      if (data.responseText) {
        try {
          return data = jQuery.parseJSON(data.responseText);
        } catch (_error) {
          error = _error;
          return {};
        }
      } else {
        return data;
      }
    })();
    if ((this.error == null) || this.error(errors) === true) {
      errors = this.__stringifyErrors(errors);
      Object.each(errors, function(field, notifications) {
        var input;
        input = _this.findField(field).addClass(_this.invalidationClass);
        return typeof _this.notification === "function" ? _this.notification(input, notifications) : void 0;
      });
      return errors;
    }
    return false;
  };

  Form.prototype.__debounce = function(xhr) {
    this.debugAs(this, "debounce: pending_request == " + this.__pending_request);
    if (this.__pending_request && this.debounce !== false) {
      if (this.debounce || Joosy.Application.debounceForms) {
        xhr.abort();
        this.debugAs(this, "debounce: xhr aborted");
        return true;
      }
    }
    return false;
  };

  Form.prototype.findField = function(field) {
    return this.fields.filter("[name='" + field + "']");
  };

  Form.prototype.__markMethod = function(method) {
    if (method == null) {
      method = 'PUT';
    }
    method = $('<input/>', {
      type: 'hidden',
      name: '_method',
      value: method
    });
    return this.container.append(method);
  };

  Form.prototype.__stringifyErrors = function(errors) {
    var result,
      _this = this;
    result = {};
    Object.each(errors, function(field, notifications) {
      var f, name, splited, _i, _len;
      if (_this.substitutions[field] != null) {
        field = _this.substitutions[field];
      }
      if (Object.isObject(notifications) || _this.isArrayOfObjects(notifications)) {
        return Object.each(_this.__foldInlineEntities(notifications), function(key, value) {
          return result[field + key] = value;
        });
      } else {
        if (field.indexOf(".") !== -1) {
          splited = field.split('.');
          field = splited.shift();
          if (_this.resourceName || _this.__resource) {
            name = _this.resourceName || _this.__resource.__entityName;
            field = name + ("[" + field + "]");
          }
          for (_i = 0, _len = splited.length; _i < _len; _i++) {
            f = splited[_i];
            field += "[" + f + "]";
          }
        } else if (_this.resourceName || _this.__resource) {
          name = _this.resourceName || _this.__resource.__entityName;
          field = name + ("[" + field + "]");
        }
        return result[field] = notifications;
      }
    });
    return result;
  };

  Form.prototype.__foldInlineEntities = function(hash, scope, result) {
    var _this = this;
    if (scope == null) {
      scope = "";
    }
    if (result == null) {
      result = {};
    }
    Object.each(hash, function(key, value) {
      if (Object.isObject(value) || _this.isArrayOfObjects(value)) {
        return _this.__foldInlineEntities(value, "" + scope + "[" + key + "]", result);
      } else {
        return result["" + scope + "[" + key + "]"] = value;
      }
    });
    return result;
  };

  Form.prototype.concatFieldName = function(wrapper, name) {
    var items;
    items = this.splitFieldName(wrapper).concat(this.splitFieldName(name));
    return "" + items[0] + "[" + (items.slice(1).join('][')) + "]";
  };

  Form.prototype.splitFieldName = function(name) {
    var first, items;
    items = name.split('][');
    first = items[0].split('[');
    if (first.length === 2) {
      if (first[0].isBlank()) {
        items.splice(0, 1, first[1]);
      } else {
        items.splice(0, 1, first[0], first[1]);
      }
      items[items.length - 1] = items[items.length - 1].split(']')[0];
    }
    return items;
  };

  Form.prototype.isArrayOfObjects = function(array) {
    return Object.isArray(array) && array.every(function(elem) {
      return Object.isObject(elem);
    });
  };

  return Form;

})(Joosy.Module);


/***  src/joosy/core/helpers/form  ***/

Joosy.helpers('Application', function() {
  var Form, description, input,
    _this = this;
  description = function(resource, method, extendIds, idSuffix) {
    var id;
    if (Joosy.Module.hasAncestor(resource.constructor, Joosy.Resource.Generic)) {
      id = resource.id();
      resource = resource.__entityName;
    }
    return {
      name: resource + ("" + (method.match(/^\[.*\]$/) ? method : "[" + method + "]")),
      id: resource + (id && extendIds ? '_' + id : '') + ("_" + (method.parameterize().underscore())) + (idSuffix ? '_' + idSuffix : '')
    };
  };
  input = function(type, resource, method, options) {
    var d;
    if (options == null) {
      options = {};
    }
    d = description(resource, method, options.extendIds, options.idSuffix);
    delete options.extendIds;
    delete options.idSuffix;
    return _this.tag('input', Joosy.Module.merge({
      type: type,
      name: d.name,
      id: d.id
    }, options));
  };
  Form = (function() {
    function Form(context, resource, options) {
      this.context = context;
      this.resource = resource;
      this.options = options;
    }

    Form.prototype.label = function(method, options, content) {
      if (options == null) {
        options = {};
      }
      if (content == null) {
        content = '';
      }
      if (!Object.isObject(options)) {
        content = options;
        options = {};
      }
      return this.context.label(this.resource, method, Joosy.Module.merge({
        extendIds: this.options.extendIds
      }, options), content);
    };

    Form.prototype.radioButton = function(method, tagValue, options) {
      if (options == null) {
        options = {};
      }
      return this.context.radioButton(this.resource, method, tagValue, Joosy.Module.merge({
        extendIds: this.options.extendIds
      }, options));
    };

    Form.prototype.textArea = function(method, options) {
      if (options == null) {
        options = {};
      }
      return this.context.textArea(this.resource, method, Joosy.Module.merge({
        extendIds: this.options.extendIds
      }, options));
    };

    Form.prototype.checkBox = function(method, options, checkedValue, uncheckedValue) {
      if (options == null) {
        options = {};
      }
      if (checkedValue == null) {
        checkedValue = 1;
      }
      if (uncheckedValue == null) {
        uncheckedValue = 0;
      }
      return this.context.checkBox(this.resource, method, Joosy.Module.merge({
        extendIds: this.options.extendIds
      }, options), checkedValue, uncheckedValue);
    };

    Form.prototype.select = function(method, options, htmlOptions) {
      if (options == null) {
        options = {};
      }
      if (htmlOptions == null) {
        htmlOptions = {};
      }
      return this.context.select(this.resource, method, options, Joosy.Module.merge({
        extendIds: this.options.extendIds
      }, htmlOptions));
    };

    return Form;

  })();
  ['text', 'file', 'hidden', 'password'].each(function(type) {
    return Form.prototype[type + 'Field'] = function(method, options) {
      if (options == null) {
        options = {};
      }
      return this.context[type + 'Field'](this.resource, method, Joosy.Module.merge({
        extendIds: this.options.extendIds
      }, options));
    };
  });
  this.formFor = function(resource, options, block) {
    var form, uuid;
    if (options == null) {
      options = {};
    }
    if (Object.isFunction(options)) {
      block = options;
      options = {};
    }
    uuid = Joosy.uuid();
    form = this.tag('form', Joosy.Module.merge(options.html || {}, {
      id: uuid
    }), block != null ? block.call(this, new Form(this, resource, options)) : void 0);
    if (typeof this.onRefresh === "function") {
      this.onRefresh(function() {
        return Joosy.Form.attach('#' + uuid, Joosy.Module.merge(options, {
          resource: resource
        }));
      });
    }
    return form;
  };
  this.label = function(resource, method, options, content) {
    var d;
    if (options == null) {
      options = {};
    }
    if (content == null) {
      content = '';
    }
    if (!Object.isObject(options)) {
      content = options;
      options = {};
    }
    d = description(resource, method, options.extendIds);
    delete options.extendIds;
    return this.tag('label', Joosy.Module.merge(options, {
      "for": d.id
    }), content);
  };
  ['text', 'file', 'hidden', 'password'].each(function(type) {
    return _this[type + 'Field'] = function(resource, method, options) {
      if (options == null) {
        options = {};
      }
      return input(type, resource, method, options);
    };
  });
  this.radioButton = function(resource, method, tagValue, options) {
    if (options == null) {
      options = {};
    }
    return input('radio', resource, method, Joosy.Module.merge({
      value: tagValue,
      idSuffix: tagValue
    }, options));
  };
  this.checkBox = function(resource, method, options, checkedValue, uncheckedValue) {
    var box, spy;
    if (options == null) {
      options = {};
    }
    if (checkedValue == null) {
      checkedValue = 1;
    }
    if (uncheckedValue == null) {
      uncheckedValue = 0;
    }
    spy = this.tag('input', Joosy.Module.merge({
      name: description(resource, method).name,
      value: uncheckedValue,
      type: 'hidden'
    }));
    box = input('checkbox', resource, method, Joosy.Module.merge({
      value: checkedValue
    }, options));
    return spy + box;
  };
  this.select = function(resource, method, options, htmlOptions) {
    var extendIds, key, opts, val,
      _this = this;
    if (Object.isObject(options)) {
      opts = [];
      for (key in options) {
        val = options[key];
        opts.push([val, key]);
      }
    } else {
      opts = options;
    }
    if (htmlOptions.includeBlank) {
      delete htmlOptions.includeBlank;
      opts.unshift(['', '']);
    }
    opts = opts.reduce(function(str, vals) {
      var params;
      params = Object.isArray(vals) ? [
        'option', {
          value: vals[1]
        }, vals[0]
      ] : ['option', {}, vals];
      if (htmlOptions.value === (Object.isArray(vals) ? vals[1] : vals)) {
        params[1].selected = 'selected';
      }
      return str += _this.tag.apply(_this, params);
    }, '');
    extendIds = htmlOptions.extendIds;
    delete htmlOptions.value;
    delete htmlOptions.extendIds;
    return this.tag('select', Joosy.Module.merge(description(resource, method, extendIds), htmlOptions), opts);
  };
  return this.textArea = function(resource, method, options) {
    var extendIds, value;
    if (options == null) {
      options = {};
    }
    value = options.value;
    extendIds = options.extendIds;
    delete options.value;
    delete options.extendIds;
    return this.tag('textarea', Joosy.Module.merge(description(resource, method, extendIds), options), value);
  };
});


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
  this.nl2br = function(text) {
    return text.toString().replace(/\n/g, '<br/>');
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
    uuid = Joosy.uuid();
    params = {
      id: uuid
    };
    parts = element.split('.');
    if (parts[1]) {
      params["class"] = parts.from(1).join(' ');
    }
    element = this.tag(parts[0], params);
    this.onRefresh(function() {
      return this.registerWidget('#' + uuid, widget);
    });
    return element;
  };
});


/***  src/joosy/core/templaters/rails_jst  ***/

Joosy.Templaters.RailsJST = (function() {
  function RailsJST(applicationName) {
    this.applicationName = applicationName;
  }

  RailsJST.prototype.buildView = function(name) {
    var location, template;
    if (!(template = JST[location = "" + this.applicationName + "/templates/" + name + "-" + (typeof I18n !== "undefined" && I18n !== null ? I18n.locale : void 0)])) {
      template = JST[location = "" + this.applicationName + "/templates/" + name];
    }
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
    var assignContext, binding, context, isCollection, isResource, key, morph, object, renderers, resource, result, stack, update, _i, _len, _ref,
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
    isResource = Joosy.Module.hasAncestor(locals.constructor, Joosy.Resource.Generic);
    isCollection = Joosy.Module.hasAncestor(locals.constructor, Joosy.Resource.Collection);
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
    if (!Object.isObject(locals) && Object.extended().constructor !== locals.constructor && !isResource && !isCollection) {
      throw new Error("" + (Joosy.Module.__className(this)) + "> locals (maybe @data?) not in: dumb hash, Resource, Collection");
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
      if (isResource) {
        Joosy.Module.merge(data, stack.locals.data);
      } else {
        Joosy.Module.merge(data, stack.locals);
      }
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
          morph.html(result());
          return typeof _this.refreshElements === "function" ? _this.refreshElements() : void 0;
        }
      };
      update = update.debounce(0);
      morph.__bindings = [];
      if (isCollection) {
        _ref = locals.data;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          resource = _ref[_i];
          binding = [resource, update];
          resource.bind('changed', update);
          stack.metamorphBindings.push(binding);
          morph.__bindings.push(binding);
        }
      }
      if (isResource || isCollection) {
        binding = [locals, update];
        locals.bind('changed', update);
        stack.metamorphBindings.push(binding);
        morph.__bindings.push(binding);
      } else {
        for (key in locals) {
          object = locals[key];
          if (locals.hasOwnProperty(key)) {
            if (((object != null ? object.bind : void 0) != null) && ((object != null ? object.unbind : void 0) != null)) {
              binding = [object, update];
              object.bind('changed', update);
              stack.metamorphBindings.push(binding);
              morph.__bindings.push(binding);
            }
          }
        }
      }
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
  __collectWidgets: function() {
    var klass, widgets;
    widgets = Object.extended(this.widgets || {});
    klass = this;
    while (klass = klass.constructor.__super__) {
      Joosy.Module.merge(widgets, klass.widgets, false);
    }
    return widgets;
  },
  __setupWidgets: function() {
    var registered, widgets,
      _this = this;
    widgets = this.__collectWidgets();
    registered = Object.extended();
    widgets.each(function(selector, widget) {
      var activeSelector, r;
      if (selector === '$container') {
        activeSelector = _this.container;
      } else {
        if (r = selector.match(/\$([A-z_]+)/)) {
          selector = _this.elements[r[1]];
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
    this.refreshElements();
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
    this.refreshElements();
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


/***  src/joosy/core/preloader  ***/

this.Preloader = {
  load: function(libraries, options) {
    var key, val, _ref;
    for (key in options) {
      val = options[key];
      this[key] = val;
    }
    return (_ref = this.complete) != null ? _ref.call(window) : void 0;
  }
};


/***  src/joosy/core/resource/collection  ***/

var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __slice = [].slice;

Joosy.Resource.Collection = (function(_super) {
  __extends(Collection, _super);

  Collection.include(Joosy.Modules.Events);

  Collection.beforeLoad = function(action) {
    return this.prototype.__beforeLoad = action;
  };

  Collection.model = function(model) {
    return this.prototype.model = model;
  };

  function Collection(model, findOptions) {
    if (model == null) {
      model = false;
    }
    this.findOptions = findOptions;
    if (model) {
      this.model = model;
    }
    this.data = [];
    if (!this.model) {
      throw new Error("" + (Joosy.Module.__className(this)) + "> model can't be empty");
    }
  }

  Collection.prototype.load = function(entities, notify) {
    if (notify == null) {
      notify = true;
    }
    if (this.__beforeLoad != null) {
      entities = this.__beforeLoad(entities);
    }
    this.data = this.modelize(entities);
    if (notify) {
      this.trigger('changed');
    }
    return this;
  };

  Collection.prototype.modelize = function(collection) {
    var root,
      _this = this;
    root = this.model.prototype.__entityName.pluralize();
    if (!(collection instanceof Array)) {
      collection = collection != null ? collection[root.camelize(false)] : void 0;
      if (!(collection instanceof Array)) {
        throw new Error("Can not read incoming JSON");
      }
    }
    return collection.map(function(x) {
      return _this.model.build(x);
    });
  };

  Collection.prototype.each = function(callback) {
    return this.data.each(callback);
  };

  Collection.prototype.size = function() {
    return this.data.length;
  };

  Collection.prototype.find = function(description) {
    return this.data.find(description);
  };

  Collection.prototype.sortBy = function() {
    var params, _ref;
    params = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    return (_ref = this.data).sortBy.apply(_ref, params);
  };

  Collection.prototype.findById = function(id) {
    return this.data.find(function(x) {
      return x.id().toString() === id.toString();
    });
  };

  Collection.prototype.at = function(i) {
    return this.data[i];
  };

  Collection.prototype.remove = function(target, notify) {
    var index, result;
    if (notify == null) {
      notify = true;
    }
    if (Object.isNumber(target)) {
      index = target;
    } else {
      index = this.data.indexOf(target);
    }
    if (index >= 0) {
      result = this.data.splice(index, 1)[0];
      if (notify) {
        this.trigger('changed');
      }
    }
    return result;
  };

  Collection.prototype.add = function(element, index, notify) {
    if (index == null) {
      index = false;
    }
    if (notify == null) {
      notify = true;
    }
    if (typeof index === 'number') {
      this.data.splice(index, 0, element);
    } else {
      this.data.push(element);
    }
    if (notify) {
      this.trigger('changed');
    }
    return element;
  };

  return Collection;

})(Joosy.Module);


/***  src/joosy/core/resource/generic  ***/

var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Joosy.Resource.Generic = (function(_super) {
  __extends(Generic, _super);

  Generic.include(Joosy.Modules.Log);

  Generic.include(Joosy.Modules.Events);

  Generic.prototype.__primaryKey = 'id';

  Generic.prototype.__source = false;

  Generic.resetIdentity = function() {
    return Joosy.Resource.Generic.identity = {};
  };

  Generic.beforeLoad = function(action) {
    if (!this.prototype.hasOwnProperty('__beforeLoads')) {
      this.prototype.__beforeLoads = [].concat(this.__super__.__beforeLoads || []);
    }
    return this.prototype.__beforeLoads.push(action);
  };

  Generic.primaryKey = function(primaryKey) {
    return this.prototype.__primaryKey = primaryKey;
  };

  Generic.source = function(location) {
    return this.__source = location;
  };

  Generic.at = function(entity) {
    var Clone, _ref;
    Clone = (function(_super1) {
      __extends(Clone, _super1);

      function Clone() {
        _ref = Clone.__super__.constructor.apply(this, arguments);
        return _ref;
      }

      return Clone;

    })(this);
    if (entity instanceof Joosy.Resource.Generic) {
      Clone.__source = entity.memberPath();
      if (this.prototype.__entityName) {
        Clone.__source += '/' + this.prototype.__entityName.pluralize();
      }
    } else {
      Clone.__source = entity;
    }
    return Clone;
  };

  Generic.entity = function(name) {
    return this.prototype.__entityName = name;
  };

  Generic.collection = function(klass) {
    return this.prototype.__collection = function() {
      return klass;
    };
  };

  Generic.prototype.__collection = function() {
    var named;
    named = this.__entityName.camelize().pluralize() + 'Collection';
    if (window[named]) {
      return window[named];
    } else {
      return Joosy.Resource.Collection;
    }
  };

  Generic.map = function(name, klass) {
    if (klass == null) {
      klass = false;
    }
    if (!klass) {
      klass = window[name.singularize().camelize()];
    }
    if (!klass) {
      throw new Error("" + (Joosy.Module.__className(this)) + "> class can not be detected for '" + name + "' mapping");
    }
    return this.beforeLoad(function(data) {
      if (!Joosy.Module.hasAncestor(klass, Joosy.Resource.Generic)) {
        klass = klass();
      }
      return this.__map(data, name, klass);
    });
  };

  Generic.build = function(data) {
    var id, key, klass, shim, value, _base, _base1, _ref;
    if (data == null) {
      data = {};
    }
    klass = this.prototype.__entityName;
    (_base = Joosy.Resource.Generic).identity || (_base.identity = {});
    (_base1 = Joosy.Resource.Generic.identity)[klass] || (_base1[klass] = {});
    shim = function() {
      return shim.__call.apply(shim, arguments);
    };
    if (shim.__proto__) {
      shim.__proto__ = this.prototype;
    } else {
      _ref = this.prototype;
      for (key in _ref) {
        value = _ref[key];
        shim[key] = value;
      }
    }
    shim.constructor = this;
    if (Object.isNumber(data) || Object.isString(data)) {
      id = data;
      data = {};
      data[shim.__primaryKey] = id;
    }
    if (Joosy.Application.identity) {
      id = data[shim.__primaryKey];
      if ((id != null) && Joosy.Resource.Generic.identity[klass][id]) {
        shim = Joosy.Resource.Generic.identity[klass][id];
        shim.load(data);
      } else {
        Joosy.Resource.Generic.identity[klass][id] = shim;
        this.apply(shim, [data]);
      }
    } else {
      this.apply(shim, [data]);
    }
    return shim;
  };

  function Generic(data) {
    if (data == null) {
      data = {};
    }
    this.__fillData(data, false);
  }

  Generic.prototype.id = function() {
    return this.data[this.__primaryKey];
  };

  Generic.prototype.knownAttributes = function() {
    return this.data.keys();
  };

  Generic.prototype.load = function(data) {
    this.__fillData(data);
    return this;
  };

  Generic.prototype.__get = function(path) {
    var target;
    target = this.__callTarget(path);
    if (target[0] instanceof Joosy.Resource.Generic) {
      return target[0](target[1]);
    } else {
      return target[0][target[1]];
    }
  };

  Generic.prototype.__set = function(path, value) {
    var target;
    target = this.__callTarget(path);
    if (target[0] instanceof Joosy.Resource.Generic) {
      target[0](target[1], value);
    } else {
      target[0][target[1]] = value;
    }
    this.trigger('changed');
    return null;
  };

  Generic.prototype.__callTarget = function(path) {
    var keyword, part, target, _i, _len;
    if (path.has(/\./) && (this.data[path] == null)) {
      path = path.split('.');
      keyword = path.pop();
      target = this.data;
      for (_i = 0, _len = path.length; _i < _len; _i++) {
        part = path[_i];
        target[part] || (target[part] = {});
        if (target instanceof Joosy.Resource.Generic) {
          target = target(part);
        } else {
          target = target[part];
        }
      }
      return [target, keyword];
    } else {
      return [this.data, path];
    }
  };

  Generic.prototype.__call = function(path, value) {
    if (arguments.length > 1) {
      return this.__set(path, value);
    } else {
      return this.__get(path);
    }
  };

  Generic.prototype.__fillData = function(data, notify) {
    if (notify == null) {
      notify = true;
    }
    this.raw = data;
    if (!this.hasOwnProperty('data')) {
      this.data = {};
    }
    Joosy.Module.merge(this.data, this.__prepareData(data));
    if (notify) {
      this.trigger('changed');
    }
    return null;
  };

  Generic.prototype.__prepareData = function(data) {
    var bl, name, _i, _len, _ref;
    if (Object.isObject(data) && Object.keys(data).length === 1 && this.__entityName) {
      name = this.__entityName.camelize(false);
      if (data[name]) {
        data = data[name];
      }
    }
    if (this.__beforeLoads != null) {
      _ref = this.__beforeLoads;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        bl = _ref[_i];
        data = bl.call(this, data);
      }
    }
    return data;
  };

  Generic.prototype.__map = function(data, name, klass) {
    var entry;
    if (Object.isArray(data[name])) {
      entry = new (klass.prototype.__collection())(klass);
      entry.load(data[name]);
      data[name] = entry;
    } else if (Object.isObject(data[name])) {
      data[name] = klass.build(data[name]);
    }
    return data;
  };

  return Generic;

})(Joosy.Module);


/***  src/joosy/core/resource/rest  ***/

var _ref,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Joosy.Resource.REST = (function(_super) {
  __extends(REST, _super);

  function REST() {
    _ref = REST.__super__.constructor.apply(this, arguments);
    return _ref;
  }

  REST.prototype.__collection = function() {
    var named;
    named = this.__entityName.camelize().pluralize() + 'Collection';
    if (window[named]) {
      return window[named];
    } else {
      return Joosy.Resource.RESTCollection;
    }
  };

  REST.__parentsPath = function(parents) {
    return parents.reduce(function(path, parent) {
      return path += Joosy.Module.hasAncestor(parent.constructor, Joosy.Resource.REST) ? parent.memberPath() : parent;
    }, '');
  };

  REST.basePath = function(options) {
    var path;
    if (options == null) {
      options = {};
    }
    if ((this.__source != null) && (options.parent == null)) {
      path = this.__source;
    } else {
      path = '/';
      if (this.__namespace__.length > 0) {
        path += this.__namespace__.map(function(s) {
          return s.toLowerCase();
        }).join('/') + '/';
      }
      path += this.prototype.__entityName.pluralize();
    }
    if (options.parent != null) {
      path = this.__parentsPath(Object.isArray(options.parent) ? options.parent : [options.parent]) + path;
    }
    return path;
  };

  REST.prototype.basePath = function(options) {
    if (options == null) {
      options = {};
    }
    return this.constructor.basePath(options);
  };

  REST.memberPath = function(id, options) {
    var path;
    if (options == null) {
      options = {};
    }
    path = this.basePath(options) + ("/" + id);
    if (options.from != null) {
      path += "/" + options.from;
    }
    return path;
  };

  REST.prototype.memberPath = function(options) {
    if (options == null) {
      options = {};
    }
    return this.constructor.memberPath(this.id(), options);
  };

  REST.collectionPath = function(options) {
    var path;
    if (options == null) {
      options = {};
    }
    path = this.basePath(options);
    if (options.from != null) {
      path += "/" + options.from;
    }
    return path;
  };

  REST.prototype.collectionPath = function(options) {
    if (options == null) {
      options = {};
    }
    return this.constructor.collectionPath(options);
  };

  REST.get = function(options, callback) {
    if (Object.isFunction(options)) {
      callback = options;
      options = {};
    }
    return this.__query(this.collectionPath(options), 'GET', options.params, callback);
  };

  REST.post = function(options, callback) {
    if (Object.isFunction(options)) {
      callback = options;
      options = {};
    }
    return this.__query(this.collectionPath(options), 'POST', options.params, callback);
  };

  REST.put = function(options, callback) {
    if (Object.isFunction(options)) {
      callback = options;
      options = {};
    }
    return this.__query(this.collectionPath(options), 'PUT', options.params, callback);
  };

  REST["delete"] = function(options, callback) {
    if (Object.isFunction(options)) {
      callback = options;
      options = {};
    }
    return this.__query(this.collectionPath(options), 'DELETE', options.params, callback);
  };

  REST.prototype.get = function(options, callback) {
    if (Object.isFunction(options)) {
      callback = options;
      options = {};
    }
    return this.constructor.__query(this.memberPath(options), 'GET', options.params, callback);
  };

  REST.prototype.post = function(options, callback) {
    if (Object.isFunction(options)) {
      callback = options;
      options = {};
    }
    return this.constructor.__query(this.memberPath(options), 'POST', options.params, callback);
  };

  REST.prototype.put = function(options, callback) {
    if (Object.isFunction(options)) {
      callback = options;
      options = {};
    }
    return this.constructor.__query(this.memberPath(options), 'PUT', options.params, callback);
  };

  REST.prototype["delete"] = function(options, callback) {
    if (Object.isFunction(options)) {
      callback = options;
      options = {};
    }
    return this.constructor.__query(this.memberPath(options), 'DELETE', options.params, callback);
  };

  REST.find = function(where, options, callback) {
    var result,
      _this = this;
    if (options == null) {
      options = {};
    }
    if (callback == null) {
      callback = false;
    }
    if (Object.isFunction(options)) {
      callback = options;
      options = {};
    }
    if (where === 'all') {
      result = new (this.prototype.__collection())(this, options);
      this.__query(this.collectionPath(options), 'GET', options.params, function(data) {
        result.load(data);
        return typeof callback === "function" ? callback(result, data) : void 0;
      });
    } else {
      result = this.build(where);
      this.__query(this.memberPath(where, options), 'GET', options.params, function(data) {
        result.load(data);
        return typeof callback === "function" ? callback(result, data) : void 0;
      });
    }
    return result;
  };

  REST.__query = function(path, method, params, callback) {
    var options;
    options = {
      data: params,
      type: method,
      cache: false,
      dataType: 'json'
    };
    if (Object.isFunction(callback)) {
      options.success = callback;
    } else {
      Joosy.Module.merge(options, callback);
    }
    return $.ajax(path, options);
  };

  REST.prototype.reload = function(options, callback) {
    var _this = this;
    if (options == null) {
      options = {};
    }
    if (callback == null) {
      callback = false;
    }
    if (Object.isFunction(options)) {
      callback = options;
      options = {};
    }
    return this.constructor.__query(this.memberPath(options), 'GET', options.params, function(data) {
      _this.load(data);
      return typeof callback === "function" ? callback(_this) : void 0;
    });
  };

  return REST;

})(Joosy.Resource.Generic);


/***  src/joosy/core/resource/rest_collection  ***/

var _ref,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Joosy.Resource.RESTCollection = (function(_super) {
  __extends(RESTCollection, _super);

  function RESTCollection() {
    _ref = RESTCollection.__super__.constructor.apply(this, arguments);
    return _ref;
  }

  RESTCollection.include(Joosy.Modules.Log);

  RESTCollection.include(Joosy.Modules.Events);

  RESTCollection.prototype.reload = function(options, callback) {
    var _this = this;
    if (options == null) {
      options = {};
    }
    if (callback == null) {
      callback = false;
    }
    if (Object.isFunction(options)) {
      callback = options;
      options = {};
    }
    return this.model.__query(this.model.collectionPath(options), 'GET', options.params, function(data) {
      _this.load(data);
      return typeof callback === "function" ? callback(data) : void 0;
    });
  };

  return RESTCollection;

})(Joosy.Resource.Collection);


/***  src/joosy/core/router  ***/

Joosy.Router = {
  rawRoutes: Object.extended(),
  routes: Object.extended(),
  restrictPattern: false,
  __namespace: "",
  __asNamespace: "",
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
    path = to.replace(/^\#?\!?/, '!');
    if (options.respond !== false) {
      return location.hash = path;
    } else {
      if (!history.pushState) {
        this.__ignoreRequest = to;
        location.hash = path;
        return setTimeout(function() {
          return _this.__ignoreRequest = false;
        }, 2);
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
    fullPath = hash.replace(/^#!?/, '');
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
    var fnc;
    if (as === void 0) {
      return;
    }
    fnc = function(options) {
      var url;
      url = route;
      (route.match(/\/:[^\/]+/g) || []).each(function(str) {
        return url = url.replace(str.substr(1), options[str.substr(2)]);
      });
      return "#!" + url;
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
    if (render && this.__renderer) {
      this.swapContainer(this.container, this.__renderer(this.data || {}));
    }
    this.refreshElements();
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


/***  src/joosy/preloaders/caching  ***/

this.CachingPreloader = {
  force: false,
  prefix: "cache:",
  counter: 0,
  load: function(libraries, options) {
    var i, key, lib, val, _i, _len, _ref, _ref1;
    if (options == null) {
      options = {};
    }
    for (key in options) {
      val = options[key];
      this[key] = val;
    }
    this.libraries = libraries.slice();
    _ref = this.libraries;
    for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
      lib = _ref[i];
      this.libraries[i] = this.prefix + lib[0];
    }
    if (!this.force && this.check()) {
      return this.restore();
    } else {
      if ((_ref1 = this.start) != null) {
        _ref1.call(window);
      }
      this.clean();
      return this.download(libraries);
    }
  },
  check: function() {
    var flag, i, name, _i, _len, _ref;
    flag = true;
    _ref = this.libraries;
    for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
      name = _ref[i];
      flag && (flag = window.localStorage.getItem(name) != null);
    }
    return flag;
  },
  escapeStr: function(str) {
    return str.replace(new RegExp("\u0001", 'g'), "\\u0001").replace(new RegExp("\u000B", 'g'), "\\u000B");
  },
  restore: function() {
    var i, name, _i, _len, _ref, _ref1;
    _ref = this.libraries;
    for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
      name = _ref[i];
      window.evalGlobaly(window.localStorage.getItem(name));
    }
    return (_ref1 = this.complete) != null ? _ref1.call(window, true) : void 0;
  },
  download: function(libraries) {
    var lib, size, url, _ref,
      _this = this;
    if (libraries.length > 0) {
      this.counter += 1;
      lib = libraries.shift();
      url = lib[0];
      size = lib[1];
      return this.ajax(url, size, function(xhr) {
        var code;
        code = xhr.responseText;
        if (window.navigator.appName === "Microsoft Internet Explorer") {
          code = _this.escapeStr(code);
        }
        window.localStorage.setItem(_this.prefix + url, code);
        window.evalGlobaly(xhr.responseText);
        return _this.download(libraries);
      });
    } else {
      return (_ref = this.complete) != null ? _ref.call(window) : void 0;
    }
  },
  ajax: function(url, size, callback) {
    var poller, x,
      _this = this;
    if (window.XMLHttpRequest) {
      x = new XMLHttpRequest;
    } else {
      x = new ActiveXObject('Microsoft.XMLHTTP');
    }
    x.open('GET', url, 1);
    x.onreadystatechange = function() {
      if (x.readyState > 3) {
        clearInterval(_this.interval);
        return typeof callback === "function" ? callback(x) : void 0;
      }
    };
    if (this.progress) {
      poller = function() {
        var e;
        try {
          return _this.progress.call(window, Math.round((x.responseText.length / size) * (_this.counter / _this.libraries.length) * 100));
        } catch (_error) {
          e = _error;
        }
      };
      this.interval = setInterval(poller, 100);
    }
    return x.send();
  },
  clean: function() {
    var find, i, key, _results;
    i = 0;
    find = function(arr, obj) {
      var x, _i, _len;
      for (_i = 0, _len = arr.length; _i < _len; _i++) {
        x = arr[_i];
        if (obj === x) {
          return i;
        }
      }
      return -1;
    };
    _results = [];
    while (i < window.localStorage.length && (key = window.localStorage.key(i))) {
      if (key.indexOf(this.prefix) === 0 && find(this.libraries, key) < 0) {
        _results.push(window.localStorage.removeItem(key));
      } else {
        _results.push(i += 1);
      }
    }
    return _results;
  }
};

window.evalGlobaly = function(src) {
  if (src.length === 0) {
    return;
  }
  if (window.execScript) {
    return window.execScript(src);
  } else {
    return window["eval"](src);
  }
};

this.Preloader = this.CachingPreloader;


/***  src/joosy/preloaders/inline  ***/

this.InlinePreloader = {
  load: function(libraries, options) {
    var key, val,
      _this = this;
    for (key in options) {
      val = options[key];
      this[key] = val;
    }
    if (typeof this.start === "function") {
      this.start();
    }
    if (libraries.length > 0) {
      return this.receive(libraries.shift()[0], function() {
        return _this.load(libraries);
      });
    } else {
      return typeof this.complete === "function" ? this.complete() : void 0;
    }
  },
  receive: function(url, callback) {
    var done, head, proceed, script;
    head = document.getElementsByTagName("head")[0];
    script = document.createElement("script");
    script.src = url;
    done = false;
    proceed = function() {
      if (!done && ((this.readyState == null) || this.readyState === "loaded" || this.readyState === "complete")) {
        done = true;
        if (typeof callback === "function") {
          callback();
        }
        return script.onload = script.onreadystatechange = null;
      }
    };
    script.onload = script.onreadystatechange = proceed;
    head.appendChild(script);
    return void 0;
  }
};

this.Preloader = this.InlinePreloader;


/***  src/joosy/joosy  ***/


;
