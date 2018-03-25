// Generated by LiveScript 1.5.0
/**
 * @package Detox chat app
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
(function(){
  var cleanCss, del, exec, fs, gulp, gulpHtmlmin, gulpRename, gulpRequirejsOptimize, runSequence, uglifyEs, uglify, minify_css, instance, minify_js, SCRIPTS_REGEXP, IMAGES_REGEXP, SOURCE_CSS, SOURCE_HTML, DESTINATION, BUNDLED_CSS, MINIFIED_CSS, BUNDLED_HTML, MINIFIED_HTML, BUNDLED_JS, MINIFIED_JS, requirejs_config;
  cleanCss = require('clean-css');
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
  SCRIPTS_REGEXP = /<script>[^]+?<\/script>\n*/g;
  IMAGES_REGEXP = /url\(\.\.\/img\/.+?\)/g;
  SOURCE_CSS = 'css/style.css';
  SOURCE_HTML = 'html/index.html';
  DESTINATION = 'dist';
  BUNDLED_CSS = 'style.css';
  MINIFIED_CSS = 'style.min.css';
  BUNDLED_HTML = 'index.html';
  MINIFIED_HTML = 'index.min.html';
  BUNDLED_JS = 'script.js';
  MINIFIED_JS = 'script.min.js';
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
      'state': 'js/state'
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
    var css, images, i$, len$, image, image_path, image_source, image_base_uri;
    css = fs.readFileSync(SOURCE_CSS + "", {
      encoding: 'utf8'
    });
    images = css.match(IMAGES_REGEXP);
    for (i$ = 0, len$ = images.length; i$ < len$; ++i$) {
      image = images[i$];
      image_path = image.substring(7, image.length - 1);
      image_source = fs.readFileSync(image_path, {
        encoding: 'utf8'
      });
      image_base_uri = 'url(data:image/svg+xml;utf8,' + image_source.replace(/#/g, '%23') + ')';
      css.replace(image, image_base_uri);
    }
    fs.writeFileSync(DESTINATION + "/" + BUNDLED_CSS, css);
  }).task('bundle-html', function(callback){
    var command;
    command = "node_modules/.bin/polymer-bundler --strip-comments --rewrite-urls-in-templates --inline-css --inline-scripts --out-html " + DESTINATION + "/" + BUNDLED_HTML + " " + SOURCE_HTML;
    exec(command, function(error, stdout, stderr){
      var html, js;
      if (stdout) {
        console.log(stdout);
      }
      if (stderr) {
        console.error(stderr);
      }
      html = fs.readFileSync(DESTINATION + "/" + BUNDLED_HTML, {
        encoding: 'utf8'
      });
      js = html.match(SCRIPTS_REGEXP).map(function(string){
        string = string.trim();
        return string.substring(8, string.length - 9);
      }).join('');
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
  }).task('copy-wasm', function(){
    var i$, ref$, len$, ref1$, name, location, main;
    for (i$ = 0, len$ = (ref$ = requirejs_config.packages).length; i$ < len$; ++i$) {
      ref1$ = ref$[i$], name = ref1$.name, location = ref1$.location, main = ref1$.main;
      if (name.endsWith('.wasm')) {
        fs.copyFileSync(location + "/src/" + name, DESTINATION + "/" + name);
      }
    }
  }).task('copy-js', function(){
    var alameda, webcomponents;
    alameda = fs.readFileSync('node_modules/alameda/alameda.js', {
      encoding: 'utf8'
    });
    webcomponents = fs.readFileSync('node_modules/@webcomponents/webcomponentsjs/webcomponents-hi-sd-ce.js', {
      encoding: 'utf8'
    });
    fs.writeFileSync(DESTINATION + "/alameda.min.js", minify_js(alameda));
    fs.writeFileSync(DESTINATION + "/webcomponents.min.js", minify_js(webcomponents));
  }).task('default', function(callback){
    runSequence('dist', 'dist:clean', callback);
  }).task('dist', function(callback){
    runSequence('clean', ['copy-js', 'copy-wasm', 'minify-css', 'minify-html', 'minify-js', 'update-index'], callback);
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
  }).task('minify-js', ['bundle-js'], function(){
    return gulp.src(DESTINATION + "/" + BUNDLED_JS).pipe(uglify()).pipe(gulpRename(MINIFIED_JS)).pipe(gulp.dest(DESTINATION));
  }).task('update-index', function(){});
}).call(this);
