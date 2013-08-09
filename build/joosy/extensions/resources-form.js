(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  Joosy.Form = (function(_super) {
    __extends(Form, _super);

    Form.include(Joosy.Modules.DOM);

    Form.include(Joosy.Modules.Log);

    Form.include(Joosy.Modules.Events);

    Form.prototype.invalidationClass = 'field_with_errors';

    Form.prototype.substitutions = {};

    Form.mapElements({
      'fields': 'input,select,textarea'
    });

    Form.submit = function(form, options) {
      if (options == null) {
        options = {};
      }
      form = new this(form, options);
      form.$container.submit();
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
      this.$container = $(form);
      if (this.$container.length === 0) {
        return;
      }
      this.__assignElements();
      this.__delegateEvents();
      method = (_ref = this.$container.get(0).getAttribute('method')) != null ? _ref.toLowerCase() : void 0;
      if (method && !['get', 'post'].any(method)) {
        this.__markMethod(method);
        this.$container.attr('method', 'POST');
      }
      this.$container.ajaxForm({
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
        this.$container.attr('action', this.action);
        this.$container.attr('method', 'POST');
      }
      if (this.method != null) {
        this.__markMethod(this.method);
      }
    }

    Form.prototype.unbind = function() {
      return this.$container.unbind('submit').find('input:submit,input:image,button:submit').unbind('click');
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
          input = _this.$fields().filter("[name='" + key + "']:not(:file),[name='" + (key.underscore()) + "']:not(:file),[name='" + (key.camelize(false)) + "']:not(:file)");
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
          if (val instanceof Joosy.Resources.RESTCollection) {
            _ref = val.data;
            _results = [];
            for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
              entity = _ref[i];
              _results.push(filler(entity.data, _this.concatFieldName(scope, "[" + property + "_attributes][" + i + "]")));
            }
            return _results;
          } else if (val instanceof Joosy.Resources.REST) {
            return filler(val.data, _this.concatFieldName(scope, "[" + property + "_attributes][0]"));
          } else if (Object.isObject(val) || Object.isArray(val)) {
            return filler(val, key);
          } else {

          }
        });
        return delete data.__joosy_form_filler_lock;
      };
      filler(data, resource.__entityName || options.resourceName);
      $('input[name=_method]', this.$container).remove();
      if (resource.id()) {
        this.__markMethod((options != null ? options.method : void 0) || 'PUT');
      }
      url = (options != null ? options.action : void 0) || (resource.id() != null ? resource.memberPath() : resource.collectionPath());
      this.$container.attr('action', url);
      return this.$container.attr('method', 'POST');
    };

    Form.prototype.submit = function() {
      return this.$container.submit();
    };

    Form.prototype.serialize = function(skipMethod) {
      var data;
      if (skipMethod == null) {
        skipMethod = true;
      }
      data = this.$container.serialize();
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
        return this.$fields().removeClass(this.invalidationClass);
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
        if (this.debounce || Joosy.Form.debounceForms) {
          xhr.abort();
          this.debugAs(this, "debounce: xhr aborted");
          return true;
        }
      }
      return false;
    };

    Form.prototype.findField = function(field) {
      return this.$fields().filter("[name='" + field + "']");
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
      return this.$container.append(method);
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

}).call(this);
(function() {
  Joosy.helpers('Application', function() {
    var Form, description, input,
      _this = this;
    description = function(resource, method, extendIds, idSuffix) {
      var id;
      if (Joosy.Module.hasAncestor(resource.constructor, Joosy.Resources.Base)) {
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
