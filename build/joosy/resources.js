(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  Joosy.Resources.Array = (function(_super) {
    __extends(Array, _super);

    Joosy.Module.merge(Array, Joosy.Module);

    Array.include(Joosy.Modules.Events);

    Array.include(Joosy.Modules.Filters);

    Array.registerPlainFilters('beforeLoad');

    function Array() {
      this.__fillData(arguments, false);
    }

    Array.prototype.set = function(index, value) {
      this[index] = value;
      this.trigger('changed');
      return value;
    };

    Array.prototype.load = function() {
      return this.__fillData(arguments);
    };

    Array.prototype.clone = function(callback) {
      var clone;
      clone = new this.constructor;
      clone.data = this.slice(0);
      return clone;
    };

    Array.prototype.push = function() {
      var result;
      result = Array.__super__.push.apply(this, arguments);
      this.trigger('changed');
      return result;
    };

    Array.prototype.pop = function() {
      var result;
      result = Array.__super__.pop.apply(this, arguments);
      this.trigger('changed');
      return result;
    };

    Array.prototype.shift = function() {
      var result;
      result = Array.__super__.shift.apply(this, arguments);
      this.trigger('changed');
      return result;
    };

    Array.prototype.unshift = function() {
      var result;
      result = Array.__super__.unshift.apply(this, arguments);
      this.trigger('changed');
      return result;
    };

    Array.prototype.splice = function() {
      var result;
      result = Array.__super__.splice.apply(this, arguments);
      this.trigger('changed');
      return result;
    };

    Array.prototype.__fillData = function(data, notify) {
      var entry, _i, _len, _ref;
      if (notify == null) {
        notify = true;
      }
      data = this.slice.call(data, 0);
      if (this.length > 0) {
        this.splice(0, this.length);
      }
      _ref = this.__applyBeforeLoads(data);
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        entry = _ref[_i];
        this.push(entry);
      }
      if (notify) {
        this.trigger('changed');
      }
      return null;
    };

    return Array;

  })(Array);

  if ((typeof define !== "undefined" && define !== null ? define.amd : void 0) != null) {
    define('joosy/resources/array', function() {
      return Joosy.Resources.Array;
    });
  }

}).call(this);
(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  Joosy.Resources.Hash = (function(_super) {
    __extends(Hash, _super);

    Hash.include(Joosy.Modules.Events);

    Hash.include(Joosy.Modules.Filters);

    Hash.registerPlainFilters('beforeLoad');

    function Hash(data) {
      if (data == null) {
        data = {};
      }
      return Hash.__super__.constructor.call(this, function() {
        return this.__fillData(data, false);
      });
    }

    Hash.prototype.load = function(data) {
      this.__fillData(data);
      return this;
    };

    Hash.prototype.clone = function(callback) {
      return new this.constructor(Object.clone(this.data, true));
    };

    Hash.prototype.__get = function(path) {
      var instance, property, _ref;
      _ref = this.__callTarget(path, true), instance = _ref[0], property = _ref[1];
      if (!instance) {
        return void 0;
      }
      if (instance instanceof Joosy.Resources.Hash) {
        return instance(property);
      } else {
        return instance[property];
      }
    };

    Hash.prototype.__set = function(path, value) {
      var instance, property, _ref;
      _ref = this.__callTarget(path), instance = _ref[0], property = _ref[1];
      if (instance instanceof Joosy.Resources.Hash) {
        instance(property, value);
      } else {
        instance[property] = value;
      }
      this.trigger('changed');
      return value;
    };

    Hash.prototype.__call = function(path, value) {
      if (arguments.length > 1) {
        return this.__set(path, value);
      } else {
        return this.__get(path);
      }
    };

    Hash.prototype.__callTarget = function(path, safe) {
      var keyword, part, target, _i, _len;
      if (safe == null) {
        safe = false;
      }
      if (path.indexOf('.') !== -1 && (this.data[path] == null)) {
        path = path.split('.');
        keyword = path.pop();
        target = this.data;
        for (_i = 0, _len = path.length; _i < _len; _i++) {
          part = path[_i];
          if (safe && (target[part] == null)) {
            return false;
          }
          if (target[part] == null) {
            target[part] = {};
          }
          target = target instanceof Joosy.Resources.Hash ? target(part) : target[part];
        }
        return [target, keyword];
      } else {
        return [this.data, path];
      }
    };

    Hash.prototype.__fillData = function(data, notify) {
      if (notify == null) {
        notify = true;
      }
      this.data = this.__applyBeforeLoads(data);
      if (notify) {
        this.trigger('changed');
      }
      return null;
    };

    Hash.prototype.toString = function() {
      return JSON.stringify(this.data);
    };

    return Hash;

  })(Joosy.Function);

  if ((typeof define !== "undefined" && define !== null ? define.amd : void 0) != null) {
    define('joosy/resources/hash', function() {
      return Joosy.Resources.Hash;
    });
  }

}).call(this);
(function() {
  Joosy.Modules.Resources = {};

}).call(this);
(function() {
  Joosy.Modules.Resources.Model = {
    included: function() {
      this.primaryKey = function(primaryKey) {
        return this.prototype.__primaryKey = primaryKey;
      };
      this.entity = function(name) {
        return this.prototype.__entityName = name;
      };
      this.map = function(name, klass) {
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
          var entries;
          if (klass.build == null) {
            klass = klass();
          }
          if (Object.isArray(data[name])) {
            entries = data[name].map(function(x) {
              return klass.build(x);
            });
            data[name] = (function(func, args, ctor) {
              ctor.prototype = func.prototype;
              var child = new ctor, result = func.apply(child, args);
              return Object(result) === result ? result : child;
            })(Joosy.Resources.Array, entries, function(){});
          } else if (Object.isObject(data[name])) {
            data[name] = klass.build(data[name]);
          }
          return data;
        });
      };
      this.build = function(data) {
        if (data == null) {
          data = {};
        }
        return new this(data);
      };
      return this.grab = function(form) {
        return this.build({}).grab(form);
      };
    },
    __primaryKey: 'id',
    id: function() {
      var _ref;
      return (_ref = this.data) != null ? _ref[this.__primaryKey] : void 0;
    },
    knownAttributes: function() {
      return Object.keys(this.data);
    },
    load: function(data, clear) {
      if (clear == null) {
        clear = false;
      }
      if (clear) {
        this.data = {};
      }
      this.__fillData(data);
      return this;
    },
    __fillData: function(data, notify) {
      if (notify == null) {
        notify = true;
      }
      this.raw = data;
      if (!this.hasOwnProperty('data')) {
        this.data = {};
      }
      Joosy.Module.merge(this.data, this.__applyBeforeLoads(data));
      if (notify) {
        this.trigger('changed');
      }
      return null;
    },
    grab: function(form) {
      var data, field, _i, _len, _ref;
      data = {};
      _ref = $(form).serializeArray();
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        field = _ref[_i];
        if (!data[field.name]) {
          data[field.name] = field.value;
        } else {
          if (!(data[field.name] instanceof Array)) {
            data[field.name] = [data[field.name]];
          }
          data[field.name].push(field.value);
        }
      }
      return this.load(data);
    },
    toString: function() {
      return "<Resource " + this.__entityName + "> " + (JSON.stringify(this.data));
    }
  };

}).call(this);
(function() {
  var _ref,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __slice = [].slice;

  Joosy.Resources.REST = (function(_super) {
    __extends(REST, _super);

    function REST() {
      _ref = REST.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    REST.include(Joosy.Modules.Resources.Model);

    REST.beforeLoad(function(data) {
      var name;
      if (Object.isObject(data) && Object.keys(data).length === 1 && this.__entityName) {
        name = this.__entityName.camelize(false);
        if (data[name]) {
          data = data[name];
        }
      }
      return data;
    });

    REST.requestOptions = function(options) {
      return this.prototype.__requestOptions = options;
    };

    REST.source = function(location) {
      return this.__source = location;
    };

    REST.__atWrapper = function() {
      var args, definer,
        _this = this;
      definer = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      if (args.length === 1 && Object.isArray(args[0])) {
        return this.__atWrapper.apply(this, [definer].concat(__slice.call(args[0])));
      } else {
        return definer(function(clone) {
          clone.__source = args.reduce(function(path, arg) {
            return path += arg instanceof Joosy.Resources.REST ? arg.memberPath() : arg.replace(/^\/?/, '/');
          }, '');
          return clone.__source += '/' + _this.prototype.__entityName.pluralize();
        });
      }
    };

    REST.at = function() {
      var _this = this;
      return this.__atWrapper.apply(this, [function(callback) {
        var Clone, _ref1;
        return Clone = (function(_super1) {
          __extends(Clone, _super1);

          function Clone() {
            _ref1 = Clone.__super__.constructor.apply(this, arguments);
            return _ref1;
          }

          callback(Clone);

          return Clone;

        })(_this);
      }].concat(__slice.call(arguments)));
    };

    REST.prototype.at = function() {
      var args, _ref1;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return new ((_ref1 = this.constructor).at.apply(_ref1, args))(this.data);
    };

    REST.prototype.__interpolatePath = function(source, ids) {
      if (!Object.isArray(ids)) {
        ids = [ids];
      }
      return ids.reduce(function(path, id) {
        if (id instanceof Joosy.Resources.REST) {
          id = id.id();
        }
        return path.replace(/:[^\/]+/, id);
      }, source);
    };

    REST.collectionPath = function() {
      var args, _ref1;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return (_ref1 = this.prototype).collectionPath.apply(_ref1, args);
    };

    REST.prototype.collectionPath = function(ids, options) {
      var path, source;
      if (ids == null) {
        ids = [];
      }
      if (options == null) {
        options = {};
      }
      if (Object.isObject(ids)) {
        options = ids;
        ids = [];
      }
      if (options.url) {
        return options.url;
      }
      source = this.__source || this.constructor.__source;
      if (source) {
        path = this.__interpolatePath(source, ids);
      } else {
        path = '/';
        if (this.constructor.__namespace__.length > 0) {
          path += this.constructor.__namespace__.map(String.prototype.underscore).join('/') + '/';
        }
        path += this.__entityName.pluralize();
      }
      if (options.action) {
        path += "/" + options.action;
      }
      return path;
    };

    REST.memberPath = function() {
      var args, _ref1;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return (_ref1 = this.prototype).memberPath.apply(_ref1, args);
    };

    REST.prototype.memberPath = function(ids, options) {
      var action, id, path;
      if (ids == null) {
        ids = [];
      }
      if (options == null) {
        options = {};
      }
      if (Object.isObject(ids)) {
        options = ids;
        ids = [];
      }
      if (options.url) {
        return options.url;
      }
      if (!Object.isArray(ids)) {
        ids = [ids];
      }
      id = this.id() || ids.pop();
      action = options.action;
      ids.push(this.id());
      path = this.collectionPath(ids, Object.merge(options, {
        action: void 0
      })) + ("/" + id);
      if (action != null) {
        path += "/" + action;
      }
      return path;
    };

    REST.get = function(options, callback) {
      var _ref1;
      _ref1 = this.prototype.__extractOptionsAndCallback(options, callback), options = _ref1[0], callback = _ref1[1];
      return this.__query(this.collectionPath(options), 'GET', options.params, callback);
    };

    REST.post = function(options, callback) {
      var _ref1;
      _ref1 = this.prototype.__extractOptionsAndCallback(options, callback), options = _ref1[0], callback = _ref1[1];
      return this.__query(this.collectionPath(options), 'POST', options.params, callback);
    };

    REST.put = function(options, callback) {
      var _ref1;
      _ref1 = this.prototype.__extractOptionsAndCallback(options, callback), options = _ref1[0], callback = _ref1[1];
      return this.__query(this.collectionPath(options), 'PUT', options.params, callback);
    };

    REST["delete"] = function(options, callback) {
      var _ref1;
      _ref1 = this.prototype.__extractOptionsAndCallback(options, callback), options = _ref1[0], callback = _ref1[1];
      return this.__query(this.collectionPath(options), 'DELETE', options.params, callback);
    };

    REST.prototype.get = function(options, callback) {
      var _ref1;
      _ref1 = this.__extractOptionsAndCallback(options, callback), options = _ref1[0], callback = _ref1[1];
      return this.constructor.__query(this.memberPath(options), 'GET', options.params, callback);
    };

    REST.prototype.post = function(options, callback) {
      var _ref1;
      _ref1 = this.__extractOptionsAndCallback(options, callback), options = _ref1[0], callback = _ref1[1];
      return this.constructor.__query(this.memberPath(options), 'POST', options.params, callback);
    };

    REST.prototype.put = function(options, callback) {
      var _ref1;
      _ref1 = this.__extractOptionsAndCallback(options, callback), options = _ref1[0], callback = _ref1[1];
      return this.constructor.__query(this.memberPath(options), 'PUT', options.params, callback);
    };

    REST.prototype["delete"] = function(options, callback) {
      var _ref1;
      _ref1 = this.__extractOptionsAndCallback(options, callback), options = _ref1[0], callback = _ref1[1];
      return this.constructor.__query(this.memberPath(options), 'DELETE', options.params, callback);
    };

    REST.prototype.reload = function(options, callback) {
      var _ref1,
        _this = this;
      if (options == null) {
        options = {};
      }
      if (callback == null) {
        callback = false;
      }
      _ref1 = this.__extractOptionsAndCallback(options, callback), options = _ref1[0], callback = _ref1[1];
      return this.constructor.__query(this.memberPath(options), 'GET', options.params, function(error, data, xhr) {
        if (data != null) {
          _this.load(data);
        }
        return typeof callback === "function" ? callback(error, _this, data, xhr) : void 0;
      });
    };

    REST.find = function(where, options, callback) {
      var result, _ref1,
        _this = this;
      if (options == null) {
        options = {};
      }
      if (callback == null) {
        callback = false;
      }
      _ref1 = this.prototype.__extractOptionsAndCallback(options, callback), options = _ref1[0], callback = _ref1[1];
      result = {};
      result[this.prototype.__primaryKey] = where instanceof Array ? where[where.length - 1] : where;
      result = this.build(result);
      if (where instanceof Array && where.length > 1) {
        result.__source = this.collectionPath(where);
      }
      this.__query(this.memberPath(where, options), 'GET', options.params, function(error, data, xhr) {
        if (data != null) {
          result.load(data);
        }
        return typeof callback === "function" ? callback(error, result, data, xhr) : void 0;
      });
      return result;
    };

    REST.all = function(where, options, callback) {
      var result, _ref1, _ref2,
        _this = this;
      if (options == null) {
        options = {};
      }
      if (callback == null) {
        callback = false;
      }
      if (Object.isFunction(where) || Object.isObject(where)) {
        _ref1 = this.prototype.__extractOptionsAndCallback(where, options), options = _ref1[0], callback = _ref1[1];
        where = [];
      } else {
        _ref2 = this.prototype.__extractOptionsAndCallback(options, callback), options = _ref2[0], callback = _ref2[1];
      }
      result = new Joosy.Resources.Array;
      this.__query(this.collectionPath(where, options), 'GET', options.params, function(error, rawData, xhr) {
        var data;
        if ((data = rawData) != null) {
          if (Object.isObject(data) && !(data = data[_this.prototype.__entityName.pluralize()])) {
            throw new Error("Invalid data for `all` received: " + (JSON.stringify(data)));
          }
          data = data.map(function(x) {
            var instance;
            instance = _this.build(x);
            if (where.length > 1) {
              instance.__source = _this.collectionPath(where);
            }
            return instance;
          });
          result.load.apply(result, data);
        }
        return typeof callback === "function" ? callback(error, result, rawData, xhr) : void 0;
      });
      return result;
    };

    REST.__query = function(path, method, params, callback) {
      var options;
      options = {
        url: path,
        data: params,
        type: method,
        cache: false,
        dataType: 'json'
      };
      if (Object.isFunction(callback)) {
        options.success = function(data, _, xhr) {
          return callback(false, data, xhr);
        };
        options.error = function(xhr) {
          return callback(xhr);
        };
      } else {
        Joosy.Module.merge(options, callback);
      }
      if (this.prototype.__requestOptions instanceof Function) {
        this.prototype.__requestOptions(options);
      } else if (this.prototype.__requestOptions) {
        Joosy.Module.merge(options, this.prototype.__requestOptions);
      }
      return $.ajax(options);
    };

    REST.prototype.__extractOptionsAndCallback = function(options, callback) {
      if (Object.isFunction(options)) {
        callback = options;
        options = {};
      }
      return [options, callback];
    };

    return REST;

  })(Joosy.Resources.Hash);

  if ((typeof define !== "undefined" && define !== null ? define.amd : void 0) != null) {
    define('joosy/resources/rest', function() {
      return Joosy.Resources.REST;
    });
  }

}).call(this);
(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  Joosy.Resources.Scalar = (function(_super) {
    __extends(Scalar, _super);

    Scalar.include(Joosy.Modules.Events);

    Scalar.include(Joosy.Modules.Filters);

    Scalar.registerPlainFilters('beforeLoad');

    function Scalar(value) {
      return Scalar.__super__.constructor.call(this, function() {
        return this.load(value);
      });
    }

    Scalar.prototype.load = function(value) {
      this.value = this.__applyBeforeLoads(value);
      this.trigger('changed');
      return this.value;
    };

    Scalar.prototype.clone = function(callback) {
      return new this.constructor(this.value);
    };

    Scalar.prototype.__call = function() {
      if (arguments.length > 0) {
        return this.__set(arguments[0]);
      } else {
        return this.__get();
      }
    };

    Scalar.prototype.__get = function() {
      return this.value;
    };

    Scalar.prototype.__set = function(value) {
      this.value = value;
      return this.trigger('changed');
    };

    Scalar.prototype.valueOf = function() {
      return this.value.valueOf();
    };

    Scalar.prototype.toString = function() {
      return this.value.toString();
    };

    return Scalar;

  })(Joosy.Function);

  if ((typeof define !== "undefined" && define !== null ? define.amd : void 0) != null) {
    define('joosy/resources/scalar', function() {
      return Joosy.Resources.Scalar;
    });
  }

}).call(this);
(function() {
  var __slice = [].slice;

  Joosy.Modules.Resources.Cacher = {
    included: function() {
      this.cache = function(cacheKey) {
        return this.prototype.__cacheKey = cacheKey;
      };
      this.fetcher = function(fetcher) {
        return this.prototype.__fetcher = fetcher;
      };
      this.cached = function(callback, cacheKey, fetcher) {
        var instance,
          _this = this;
        if (cacheKey == null) {
          cacheKey = false;
        }
        if (fetcher == null) {
          fetcher = false;
        }
        if (typeof cacheKey === 'function') {
          fetcher = cacheKey;
          cacheKey = void 0;
        }
        cacheKey || (cacheKey = this.prototype.__cacheKey);
        fetcher || (fetcher = this.prototype.__fetcher);
        if (cacheKey && localStorage && localStorage[cacheKey]) {
          instance = (function(func, args, ctor) {
            ctor.prototype = func.prototype;
            var child = new ctor, result = func.apply(child, args);
            return Object(result) === result ? result : child;
          })(this, JSON.parse(localStorage[cacheKey]), function(){});
          if (typeof callback === "function") {
            callback(instance);
          }
          return instance.refresh();
        } else {
          return this.fetch(function(results) {
            instance = (function(func, args, ctor) {
              ctor.prototype = func.prototype;
              var child = new ctor, result = func.apply(child, args);
              return Object(result) === result ? result : child;
            })(_this, results, function(){});
            return typeof callback === "function" ? callback(instance) : void 0;
          });
        }
      };
      return this.fetch = function(callback) {
        var _this = this;
        return this.prototype.__fetcher(function() {
          var results;
          results = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
          if (_this.prototype.__cacheKey && localStorage) {
            localStorage[_this.prototype.__cacheKey] = JSON.stringify(results);
          }
          return callback(results);
        });
      };
    },
    refresh: function(callback) {
      var _this = this;
      return this.constructor.fetch(function(results) {
        _this.load.apply(_this, results);
        return typeof callback === "function" ? callback(_this) : void 0;
      });
    }
  };

  if ((typeof define !== "undefined" && define !== null ? define.amd : void 0) != null) {
    define('joosy/modules/resources/cacher', function() {
      return Joosy.Modules.Resources.Cacher;
    });
  }

}).call(this);
(function() {
  Joosy.Modules.Resources.IdentityMap = {
    extended: function() {
      return this.prototype.__identityHolder = this;
    },
    identityReset: function() {
      return this.prototype.__identityHolder.identity = {};
    },
    identityPath: function(data) {
      return [this.prototype.__entityName, "s" + (this.__source || ''), data[this.prototype.__primaryKey]];
    },
    build: function(data) {
      var destination, element, elements, location, preload, _base, _i, _len;
      if (data == null) {
        data = {};
      }
      elements = this.identityPath(data);
      if (elements.filter(function(element) {
        return element == null;
      }).length === 0) {
        location = (_base = this.prototype.__identityHolder).identity != null ? (_base = this.prototype.__identityHolder).identity : _base.identity = {};
        destination = elements.pop();
        for (_i = 0, _len = elements.length; _i < _len; _i++) {
          element = elements[_i];
          location = location[element] != null ? location[element] : location[element] = {};
        }
        preload = {};
        preload[this.prototype.__primaryKey] = data[this.prototype.__primaryKey];
        if (location[destination] == null) {
          location[destination] = new this(preload);
        }
        return location[destination].load(data);
      } else {
        return new this(data);
      }
    }
  };

}).call(this);
(function() {
  Joosy.helpers('Application', function() {
    var Form, description, input,
      _this = this;
    description = function(resource, method, extendIds, idSuffix) {
      var id;
      if ((resource.__entityName != null) && (resource.id != null)) {
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
      return this.contentTag('label', content, Joosy.Module.merge(options, {
        "for": d.id
      }));
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
          'option', vals[0], {
            value: vals[1]
          }
        ] : ['option', vals, {}];
        if (htmlOptions.value === (Object.isArray(vals) ? vals[1] : vals)) {
          params[2].selected = 'selected';
        }
        return str += _this.contentTag.apply(_this, params);
      }, '');
      extendIds = htmlOptions.extendIds;
      delete htmlOptions.value;
      delete htmlOptions.extendIds;
      return this.contentTag('select', opts, Joosy.Module.merge(description(resource, method, extendIds), htmlOptions));
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
      return this.contentTag('textarea', value, Joosy.Module.merge(description(resource, method, extendIds), options));
    };
  });

}).call(this);
(function() {


}).call(this);
