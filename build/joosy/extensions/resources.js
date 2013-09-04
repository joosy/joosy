(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  Joosy.Resources.Base = (function(_super) {
    __extends(Base, _super);

    Base.include(Joosy.Modules.Log);

    Base.include(Joosy.Modules.Events);

    Base.include(Joosy.Modules.Filters);

    Base.prototype.__primaryKey = 'id';

    Base.resetIdentity = function() {
      return Joosy.Resources.Base.identity = {};
    };

    Base.registerPlainFilters('beforeLoad');

    Base.primaryKey = function(primaryKey) {
      return this.prototype.__primaryKey = primaryKey;
    };

    Base.entity = function(name) {
      return this.prototype.__entityName = name;
    };

    Base.map = function(name, klass) {
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
        if (!Joosy.Module.hasAncestor(klass, Joosy.Resources.Base)) {
          klass = klass();
        }
        return this.__map(data, name, klass);
      });
    };

    Base.build = function(data) {
      var id, klass, _base, _base1, _base2;
      if (data == null) {
        data = {};
      }
      if (Object.isNumber(data) || Object.isString(data)) {
        id = data;
        data = {};
        data[this.prototype.__primaryKey] = id;
      }
      klass = this.prototype.__entityName;
      id = data[this.prototype.__primaryKey];
      if ((klass != null) && (id != null)) {
        if ((_base = Joosy.Resources.Base).identity == null) {
          _base.identity = {};
        }
        if ((_base1 = Joosy.Resources.Base.identity)[klass] == null) {
          _base1[klass] = {};
        }
        if ((_base2 = Joosy.Resources.Base.identity[klass])[id] == null) {
          _base2[id] = new this({
            id: id
          });
        }
        return Joosy.Resources.Base.identity[klass][id].load(data);
      } else {
        return new this(data);
      }
    };

    Base.grab = function(form) {
      return this.build({}).grab(form);
    };

    function Base(data) {
      if (data == null) {
        data = {};
      }
      return Base.__super__.constructor.call(this, function() {
        return this.__fillData(data, false);
      });
    }

    Base.prototype.id = function() {
      var _ref;
      return (_ref = this.data) != null ? _ref[this.__primaryKey] : void 0;
    };

    Base.prototype.knownAttributes = function() {
      return Object.keys(this.data);
    };

    Base.prototype.load = function(data, clear) {
      if (clear == null) {
        clear = false;
      }
      if (clear) {
        this.data = {};
      }
      this.__fillData(data);
      return this;
    };

    Base.prototype.grab = function(form) {
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
    };

    Base.prototype.__get = function(path) {
      var target;
      target = this.__callTarget(path, true);
      if (!target) {
        return void 0;
      } else if (target[0] instanceof Joosy.Resources.Base) {
        return target[0](target[1]);
      } else {
        return target[0][target[1]];
      }
    };

    Base.prototype.__set = function(path, value) {
      var target;
      target = this.__callTarget(path);
      if (target[0] instanceof Joosy.Resources.Base) {
        target[0](target[1], value);
      } else {
        target[0][target[1]] = value;
      }
      this.trigger('changed');
      return null;
    };

    Base.prototype.__callTarget = function(path, safe) {
      var keyword, part, target, _i, _len;
      if (safe == null) {
        safe = false;
      }
      if (path.has(/\./) && (this.data[path] == null)) {
        path = path.split('.');
        keyword = path.pop();
        target = this.data;
        for (_i = 0, _len = path.length; _i < _len; _i++) {
          part = path[_i];
          if (safe && (target[part] == null)) {
            return false;
          }
          target[part] || (target[part] = {});
          if (target instanceof Joosy.Resources.Base) {
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

    Base.prototype.__call = function(path, value) {
      if (arguments.length > 1) {
        return this.__set(path, value);
      } else {
        return this.__get(path);
      }
    };

    Base.prototype.__fillData = function(data, notify) {
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

    Base.prototype.__prepareData = function(data) {
      var name;
      if (Object.isObject(data) && Object.keys(data).length === 1 && this.__entityName) {
        name = this.__entityName.camelize(false);
        if (data[name]) {
          data = data[name];
        }
      }
      return this.__applyBeforeLoads(data);
    };

    Base.prototype.__map = function(data, name, klass) {
      var entries;
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
    };

    Base.prototype.toString = function() {
      return "<Resource " + this.__entityName + "> " + (JSON.stringify(this.data));
    };

    return Base;

  })(Joosy.Function);

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
      var args,
        _this = this;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
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
      }].concat(__slice.call(args)));
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
      var id, result, _ref1,
        _this = this;
      if (options == null) {
        options = {};
      }
      if (callback == null) {
        callback = false;
      }
      _ref1 = this.prototype.__extractOptionsAndCallback(options, callback), options = _ref1[0], callback = _ref1[1];
      id = where instanceof Array ? where[where.length - 1] : where;
      result = this.build(id);
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

  })(Joosy.Resources.Base);

}).call(this);
(function() {


}).call(this);
