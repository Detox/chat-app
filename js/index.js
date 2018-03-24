// Generated by LiveScript 1.5.0
/**
 * @package Detox chat app
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
(function(){
  var DEBUG, requirejs_config, ready;
  DEBUG = in$('debug', location.search.substr(1).split('&')) || localStorage['debug'] === '1';
  requirejs_config = {
    'baseUrl': '/node_modules/',
    'paths': {
      '@detox/base-x': '@detox/base-x/index',
      '@detox/chat': '@detox/chat/src/index',
      '@detox/core': '@detox/core/src/index',
      '@detox/crypto': '@detox/crypto/src/index',
      '@detox/dht': '@detox/dht/dist/detox-dht.browser',
      '@detox/transport': '@detox/transport/src/index',
      '@detox/utils': '@detox/utils/src/index',
      'async-eventer': 'async-eventer/src/index',
      'fixed-size-multiplexer': 'fixed-size-multiplexer/src/index',
      'ronion': 'ronion/dist/ronion.browser',
      'pako': 'pako/dist/pako',
      'state': '/js/state'
    },
    'packages': [
      {
        'name': 'aez.wasm',
        'location': 'aez.wasm',
        'main': 'src/index'
      }, {
        'name': 'ed25519-to-x25519.wasm',
        'location': 'ed25519-to-x25519.wasm',
        'main': 'src/index'
      }, {
        'name': 'noise-c.wasm',
        'location': 'noise-c.wasm',
        'main': 'src/index'
      }, {
        'name': 'supercop.wasm',
        'location': 'supercop.wasm',
        'main': 'src/index'
      }
    ]
  };
  if (!DEBUG) {
    (function(paths){
      var pkg, main;
      for (pkg in paths) {
        main = paths[pkg];
        if (main.substr(0, 1) !== '/') {
          paths[pkg] += '.min';
        }
      }
    }.call(this, requirejs_config['paths']));
    (function(packages){
      var i$, len$, pkg;
      for (i$ = 0, len$ = packages.length; i$ < len$; ++i$) {
        pkg = packages[i$];
        pkg['main'] += '.min';
      }
    }.call(this, requirejs_config['packages']));
  }
  requirejs['config'](requirejs_config);
  ready = new Promise(function(resolve){
    var ref$;
    if ((ref$ = window['WebComponents']) != null && ref$['ready']) {
      resolve();
    } else {
      window.addEventListener('WebComponentsReady', resolve);
    }
  });
  ready.then(function(){
    var suffix;
    suffix = DEBUG ? '' : '.min';
    document.head.insertAdjacentHTML('beforeend', '<link rel="import" href="html/index' + suffix + '.html">');
  });
  function in$(x, xs){
    var i = -1, l = xs.length >>> 0;
    while (++i < l) if (x === xs[i]) return true;
    return false;
  }
}).call(this);
