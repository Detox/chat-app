// Generated by LiveScript 1.5.0
/**
 * @package Detox chat app
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
(function(){
  var cleanCss, crypto, del, exec, fs, gulp, gulpHtmlmin, gulpRename, gulpRequirejsOptimize, runSequence, uglifyEs, uglify, minify_css, instance, minify_js, file_hash, FONTS_REGEXP, IMAGES_REGEXP, SCRIPTS_REGEXP, BLACKLISTED_FONTS, BUNDLED_CSS, BUNDLED_HTML, BUNDLED_JS, BUNDLED_MANIFEST, DESTINATION, MINIFIED_CSS, MINIFIED_HTML, MINIFIED_JS, SOURCE_CSS, SOURCE_HTML, SOURCE_MANIFEST, requirejs_config;
  cleanCss = require('clean-css');
  crypto = require('crypto');
  del = require('del');
  exec = require('child_process').exec;
  fs = require('fs');
  gulp = require('gulp');
  gulpHtmlmin = require('gulp-htmlmin');
  gulpRename = require('gulp-rename');
  gulpRequirejsOptimize = require('gulp-requirejs-optimize');
  runSequence = require('run-sequence');
  uglifyEs = require('uglify-es');
  uglify = require('gulp-uglify/composer')(uglifyEs, console);
  minify_css = (instance = new cleanCss({
    level: {
      1: {
        specialComments: 0
      }
    }
  }), function(text){
    var result;
    result = instance.minify(text);
    if (result.error) {
      console.log(result.error);
    }
    return result.styles;
  });
  minify_js = function(text){
    var result;
    result = uglifyEs.minify(text);
    if (result.error) {
      console.log(result.error);
    }
    return result.code;
  };
  file_hash = function(file){
    var file_contents;
    file_contents = fs.readFileSync(file);
    return crypto.createHash('md5').update(file_contents).digest('hex').substr(0, 5);
  };
  FONTS_REGEXP = /url\(.+?\.woff2.+?\)/g;
  IMAGES_REGEXP = /url\(\.\.\/img\/.+?\)/g;
  SCRIPTS_REGEXP = /<script>[^]+?<\/script>\n*/g;
  BLACKLISTED_FONTS = ['fa-regular-400.woff2', 'fa-brands-400.woff2'];
  BUNDLED_CSS = 'style.css';
  BUNDLED_HTML = 'index.html';
  BUNDLED_JS = 'script.js';
  BUNDLED_MANIFEST = 'manifest.json';
  DESTINATION = 'dist';
  MINIFIED_CSS = 'style.min.css';
  MINIFIED_HTML = 'index.min.html';
  MINIFIED_JS = 'script.min.js';
  SOURCE_CSS = 'css/style.css';
  SOURCE_HTML = 'html/index.html';
  SOURCE_MANIFEST = 'manifest.json';
  requirejs_config = {
    'baseUrl': '.',
    'paths': {
      '@detox/base-x': 'node_modules/@detox/base-x/index.min',
      '@detox/chat': 'node_modules/@detox/chat/src/index.min',
      '@detox/core': 'node_modules/@detox/core/src/index.min',
      '@detox/crypto': 'node_modules/@detox/crypto/src/index.min',
      '@detox/dht': 'node_modules/@detox/dht/dist/detox-dht.browser.min',
      '@detox/transport': 'node_modules/@detox/transport/src/index',
      '@detox/utils': 'node_modules/@detox/utils/src/index.min',
      'async-eventer': 'node_modules/async-eventer/src/index.min',
      'autosize': 'node_modules/autosize/dist/autosize.min',
      'fixed-size-multiplexer': 'node_modules/fixed-size-multiplexer/src/index.min',
      'ronion': 'node_modules/ronion/dist/ronion.browser.min',
      'pako': 'node_modules/pako/dist/pako.min',
      'simple-peer': 'node_modules/simple-peer/simplepeer.min'
    },
    'packages': [
      {
        'name': 'aez.wasm',
        'location': 'node_modules/aez.wasm',
        'main': 'src/index.min'
      }, {
        'name': 'ed25519-to-x25519.wasm',
        'location': 'node_modules/ed25519-to-x25519.wasm',
        'main': 'src/index.min'
      }, {
        'name': 'jssha',
        'location': 'node_modules/jssha',
        'main': 'src/sha'
      }, {
        'name': 'noise-c.wasm',
        'location': 'node_modules/noise-c.wasm',
        'main': 'src/index.min'
      }, {
        'name': 'supercop.wasm',
        'location': 'node_modules/supercop.wasm',
        'main': 'src/index.min'
      }
    ]
  };
  gulp.task('bundle-css', function(){
    var css, images, i$, len$, image, image_path, base_name, hash;
    css = fs.readFileSync(SOURCE_CSS + "", {
      encoding: 'utf8'
    });
    images = css.match(IMAGES_REGEXP);
    for (i$ = 0, len$ = images.length; i$ < len$; ++i$) {
      image = images[i$];
      image_path = image.substring(7, image.length - 1);
      base_name = image_path.split('/').pop();
      hash = file_hash(image_path);
      css = css.replace(image, "url(" + DESTINATION + "/" + base_name + "?" + hash + ")");
      fs.copyFileSync(image_path, DESTINATION + "/" + base_name);
    }
    fs.writeFileSync(DESTINATION + "/" + BUNDLED_CSS, css);
  }).task('bundle-html', function(callback){
    var command;
    command = "node_modules/.bin/polymer-bundler --strip-comments --rewrite-urls-in-templates --inline-css --inline-scripts --out-html " + DESTINATION + "/" + BUNDLED_HTML + " " + SOURCE_HTML;
    exec(command, function(error, stdout, stderr){
      var html, fonts, i$, len$, font, font_path, base_name, hash, js;
      if (stdout) {
        console.log(stdout);
      }
      if (stderr) {
        console.error(stderr);
      }
      html = fs.readFileSync(DESTINATION + "/" + BUNDLED_HTML, {
        encoding: 'utf8'
      });
      fonts = html.match(FONTS_REGEXP);
      for (i$ = 0, len$ = fonts.length; i$ < len$; ++i$) {
        font = fonts[i$];
        font_path = font.substring(8, font.length - 2).split('?')[0];
        base_name = font_path.split('/').pop();
        hash = file_hash(font_path);
        html = html.replace(font, "url(" + base_name + "?" + hash + ")");
        if (in$(base_name, BLACKLISTED_FONTS)) {
          continue;
        }
        fs.copyFileSync(font_path, DESTINATION + "/" + base_name);
      }
      js = html.match(SCRIPTS_REGEXP).map(function(string){
        string = string.trim();
        return string.substring(8, string.length - 9);
      }).join('');
      /**
       * Wrapper:
       * 1) provides simplified require/define implementation that replaces alameda and should be enough for bundled modules
       * 2) ensures that code is only running when HTML imports were loaded
       * 3) forces async stylesheet loading and actually apply it by setting `media` property to empty string
       */
      js = "let require, requirejs, define;\n(callback => {\n	let defined_modules = {}, current_module = {exports: null}, wait_for = {};\n	function get_defined_module (name, base_name) {\n		if (name == 'exports') {\n			return {};\n		} else if (name == 'module') {\n			return current_module;\n		} else {\n			if (name.startsWith('./')) {\n				name	= base_name.split('/').slice(0, -1).join('/') + '/' + name.substr(2);\n			}\n			return defined_modules[name];\n		}\n	}\n	function load_dependencies (dependencies, base_name, fail_callback) {\n		const loaded_dependencies = [];\n		return dependencies.every(dependency => {\n			const loaded_dependency = get_defined_module(dependency, base_name);\n			if (!loaded_dependency) {\n				if (fail_callback) {\n					fail_callback(dependency);\n				}\n				return false;\n			}\n			loaded_dependencies.push(loaded_dependency);\n			return true;\n		}) && loaded_dependencies;\n	}\n	function add_wait_for (name, callback) {\n		(wait_for[name] = wait_for[name] || []).push(callback);\n	}\n	require = requirejs = (dependencies, callback) => {\n		return new Promise(resolve => {\n			const loaded_dependencies = load_dependencies(\n				dependencies,\n				'',\n				dependency => add_wait_for(\n					dependency,\n					require.bind(null, dependencies, (...loaded_dependencies) => {\n						if (callback) {\n							callback(...loaded_dependencies);\n						}\n						resolve(loaded_dependencies);\n					})\n				)\n			);\n			if (loaded_dependencies) {\n				if (callback) {\n					callback(...loaded_dependencies);\n				}\n				resolve(loaded_dependencies);\n			}\n		});\n	};\n	define = (name, dependencies, wrapper) => {\n		if (!wrapper) {\n			wrapper			= dependencies;\n			dependencies	= [];\n		}\n		const loaded_dependencies = load_dependencies(\n			dependencies,\n			name,\n			dependency => add_wait_for(dependency, define.bind(null, name, dependencies, wrapper))\n		);\n		if (loaded_dependencies) {\n			defined_modules[name] = wrapper(...loaded_dependencies) || current_module.exports;\n			if (wait_for[name]) {\n				wait_for[name].forEach(resolve => resolve());\n				delete wait_for[name];\n			}\n		}\n	};\n	define.amd = {};\n	document.head.querySelector('[media=async]').removeAttribute('media');\n	if (window.WebComponents && window.WebComponents.ready) {\n		callback();\n	} else {\n		document.addEventListener('WebComponentsReady', callback, {once: true});\n	}\n})(() => {" + js + "})";
      html = html.replace(/assetpath=".+"/g, '').replace('<link rel="import" href="../node_modules/@polymer/shadycss/apply-shim.html">', '').replace('<link rel="import" href="../node_modules/@polymer/shadycss/custom-style-interface.html">', '').replace(SCRIPTS_REGEXP, '');
      fs.writeFileSync(DESTINATION + "/" + BUNDLED_HTML, html);
      fs.writeFileSync(DESTINATION + "/" + BUNDLED_JS, js);
      callback(error);
    });
  }).task('bundle-js', ['bundle-html'], function(){
    var config;
    config = Object.assign({
      name: DESTINATION + "/" + BUNDLED_JS,
      optimize: 'none'
    }, requirejs_config);
    return gulp.src(DESTINATION + "/" + BUNDLED_JS).pipe(gulpRequirejsOptimize(config)).pipe(gulp.dest(DESTINATION));
  }).task('clean', function(){
    return del(DESTINATION + "/*");
  }).task('copy-favicon', function(){
    fs.copyFileSync('favicon.ico', DESTINATION + "/favicon.ico");
  }).task('copy-js', function(){
    var webcomponents;
    webcomponents = fs.readFileSync('node_modules/@webcomponents/webcomponentsjs/webcomponents-hi-sd-ce.js', {
      encoding: 'utf8'
    });
    fs.writeFileSync(DESTINATION + "/webcomponents.min.js", minify_js(webcomponents));
  }).task('copy-manifest', function(){
    var manifest, i$, ref$, len$, icon, base_name, hash;
    manifest = JSON.parse(fs.readFileSync(SOURCE_MANIFEST + "", {
      encoding: 'utf8'
    }));
    manifest.start_url = '../' + manifest.start_url;
    for (i$ = 0, len$ = (ref$ = manifest.icons).length; i$ < len$; ++i$) {
      icon = ref$[i$];
      base_name = icon.src.split('/').pop();
      hash = file_hash(icon.src);
      fs.copyFileSync(icon.src, DESTINATION + "/" + base_name);
      icon.src = base_name + "?" + hash;
    }
    fs.writeFileSync(DESTINATION + "/" + BUNDLED_MANIFEST, JSON.stringify(manifest));
  }).task('copy-wasm', ['bundle-js'], function(){
    var js, i$, ref$, len$, ref1$, name, location, main, hash;
    js = fs.readFileSync(DESTINATION + "/" + BUNDLED_JS, {
      encoding: 'utf8'
    });
    for (i$ = 0, len$ = (ref$ = requirejs_config.packages).length; i$ < len$; ++i$) {
      ref1$ = ref$[i$], name = ref1$.name, location = ref1$.location, main = ref1$.main;
      if (name.endsWith('.wasm')) {
        hash = file_hash(location + "/src/" + name);
        js = js.replace("=\"" + name + "\"", "=\"" + name + "?" + hash + "\"");
        fs.copyFileSync(location + "/src/" + name, DESTINATION + "/" + name);
      }
    }
    fs.writeFileSync(DESTINATION + "/" + BUNDLED_JS, js);
  }).task('default', function(callback){
    runSequence('dist', 'dist:clean', callback);
  }).task('dist', function(callback){
    runSequence('clean', ['copy-favicon', 'copy-js', 'copy-manifest', 'copy-wasm', 'minify-css', 'minify-html', 'minify-js'], 'update-index', callback);
  }).task('dist:clean', function(){
    return del([DESTINATION + "/" + BUNDLED_CSS, DESTINATION + "/" + BUNDLED_HTML, DESTINATION + "/" + BUNDLED_JS]);
  }).task('minify-css', ['bundle-css'], function(){
    var css;
    css = fs.readFileSync(DESTINATION + "/" + BUNDLED_CSS, {
      encoding: 'utf8'
    });
    fs.writeFileSync(DESTINATION + "/" + MINIFIED_CSS, minify_css(css));
  }).task('minify-html', ['bundle-html'], function(){
    return gulp.src(DESTINATION + "/" + BUNDLED_HTML).pipe(gulpHtmlmin({
      decodeEntities: true,
      minifyCSS: minify_css,
      removeComments: true
    })).pipe(gulpRename(MINIFIED_HTML)).pipe(gulp.dest(DESTINATION));
  }).task('minify-js', ['bundle-js', 'copy-wasm'], function(){
    return gulp.src(DESTINATION + "/" + BUNDLED_JS).pipe(uglify()).pipe(gulpRename(MINIFIED_JS)).pipe(gulp.dest(DESTINATION));
  }).task('update-index', function(){
    var index, critical_css, files_for_hash_update, i$, len$, file, hash;
    index = fs.readFileSync('index.html', {
      encoding: 'utf8'
    });
    critical_css = fs.readFileSync('css/critical.css', {
      encoding: 'utf8'
    }).trim();
    index = index.replace(/<style>.*?<\/style>/g, "<style>" + critical_css + "</style>");
    files_for_hash_update = [DESTINATION + "/" + MINIFIED_CSS, DESTINATION + "/favicon.ico", DESTINATION + "/" + MINIFIED_HTML, DESTINATION + "/" + MINIFIED_JS, DESTINATION + "/" + BUNDLED_MANIFEST, DESTINATION + "/webcomponents.min.js"];
    for (i$ = 0, len$ = files_for_hash_update.length; i$ < len$; ++i$) {
      file = files_for_hash_update[i$];
      hash = file_hash(file);
      index = index.replace(new RegExp(file + "[^\"]*", 'g'), file + "?" + hash);
    }
    fs.writeFileSync('index.html', index);
  });
  function in$(x, xs){
    var i = -1, l = xs.length >>> 0;
    while (++i < l) if (x === xs[i]) return true;
    return false;
  }
}).call(this);
