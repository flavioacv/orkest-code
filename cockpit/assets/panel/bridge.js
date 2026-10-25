// Ponte dos arquivos `.panel` (plano 67). Injetada pelo app no início do
// documento; a página só vê `window.orkest`.
//
//   const r = await orkest("exec git status --short");
//   r.ok, r.code, r.stdout, r.stderr, r.json (stdout parseado quando é JSON)
//   orkest.on("theme", vars => ...)   // troca de tema do app
//   orkest.theme                       // as CSS variables --ckp-* atuais
//   orkest.route / orkest.on("route") // hash routing (multi-página)
// Libs embarcadas (sem rede): /__orkest__/{orkest.css,petite-vue.js,
// chart.js,marked.js,tailwind.js} — servidas dos assets do app.
(function () {
  if (window.orkest) return;
  var listeners = {};

  function ready() {
    if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
      return Promise.resolve();
    }
    return new Promise(function (resolve) {
      window.addEventListener('flutterInAppWebViewPlatformReady', function () {
        resolve();
      }, { once: true });
    });
  }

  function orkest(line) {
    return ready().then(function () {
      return window.flutter_inappwebview.callHandler('orkest', String(line));
    });
  }

  orkest.on = function (event, fn) {
    (listeners[event] = listeners[event] || []).push(fn);
    return function () {
      listeners[event] = (listeners[event] || []).filter(function (f) {
        return f !== fn;
      });
    };
  };

  orkest.theme = {};


  orkest.__emit = function (event, data) {
    (listeners[event] || []).forEach(function (fn) {
      try {
        fn(data);
      } catch (e) {
        console.error(e);
      }
    });
  };

  orkest.__setTheme = function (vars) {
    orkest.theme = vars;
    var root = document.documentElement;
    for (var k in vars) root.style.setProperty(k, vars[k]);
    orkest.__emit('theme', vars);
  };

  // Roteamento por hash para painéis com mais de uma "página" num arquivo só.
  //   orkest.route.path            // "/" | "/detail/3" (location.hash sem "#")
  //   orkest.route.params          // { id: "3" } quando casou com um pattern
  //   orkest.route.go("/detail/3") // navega (muda o hash)
  //   orkest.route.match("/detail/:id")  // params ou null
  //   orkest.on("route", route => ...)   // dispara a cada mudança
  var route = {
    path: '/',
    params: {},
    go: function (path) {
      location.hash = path.charAt(0) === '/' ? path : '/' + path;
    },
    match: function (pattern) {
      var p = pattern.split('/').filter(Boolean);
      var c = route.path.split('/').filter(Boolean);
      if (p.length !== c.length) return null;
      var params = {};
      for (var i = 0; i < p.length; i++) {
        if (p[i].charAt(0) === ':') params[p[i].slice(1)] = decodeURIComponent(c[i]);
        else if (p[i] !== c[i]) return null;
      }
      return params;
    },
  };
  function readHash() {
    var h = location.hash.replace(/^#/, '');
    route.path = h.charAt(0) === '/' ? h : '/' + h;
    route.params = {};
    orkest.__emit('route', route);
  }
  window.addEventListener('hashchange', readHash);
  readHash();
  orkest.route = route;

  window.orkest = orkest;
})();
