(function() {
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

}).call(this);
(function() {
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

}).call(this);
(function() {


}).call(this);
