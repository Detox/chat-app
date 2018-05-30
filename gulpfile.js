// Generated by LiveScript 1.5.0
/**
 * @package Detox chat app
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
(function(){
  var cleanCss, crypto, del, exec, fs, gulp, gulpHtmlmin, gulpRename, gulpRequirejsOptimize, runSequence, uglifyEs, uglify, workboxBuild, minify_css, instance, minify_js, file_hash, AUDIO_REGEXP, FONTS_REGEXP, IMAGES_REGEXP, SCRIPTS_REGEXP, BLACKLISTED_FONTS, FA_FONT, BUNDLED_CSS, BUNDLED_HTML, BUNDLED_JS, BUNDLED_MANIFEST, BUNDLED_SW, DESTINATION, MINIFIED_CSS, MINIFIED_HTML, MINIFIED_JS, MINIFIED_SW, SOURCE_CSS, SOURCE_HTML, SOURCE_MANIFEST, requirejs_config;
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
  workboxBuild = require('workbox-build');
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
  AUDIO_REGEXP = /'audio\/[^']+\.mp3'/g;
  FONTS_REGEXP = /url\(.+?\.woff2.+?\)/g;
  IMAGES_REGEXP = /url\(\.\.\/img\/.+?\)/g;
  SCRIPTS_REGEXP = /<script>[^]+?<\/script>\n*/g;
  BLACKLISTED_FONTS = ['fa-regular-400.woff2', 'fa-brands-400.woff2'];
  FA_FONT = 'fa-solid-900.woff2';
  BUNDLED_CSS = 'style.css';
  BUNDLED_HTML = 'index.html';
  BUNDLED_JS = 'script.js';
  BUNDLED_MANIFEST = 'manifest.json';
  BUNDLED_SW = 'sw.js';
  DESTINATION = 'dist';
  MINIFIED_CSS = 'style.min.css';
  MINIFIED_HTML = 'index.min.html';
  MINIFIED_JS = 'script.min.js';
  MINIFIED_SW = 'sw.min.js';
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
      '@detox/dht': 'node_modules/@detox/dht/src/index.min',
      '@detox/routing': 'node_modules/@detox/routing/src/index.min',
      '@detox/simple-peer': 'node_modules/@detox/simple-peer/simplepeer.min',
      '@detox/transport': 'node_modules/@detox/transport/src/index.min',
      '@detox/utils': 'node_modules/@detox/utils/src/index.min',
      'array-map-set': 'node_modules/array-map-set/src/index.min',
      'async-eventer': 'node_modules/async-eventer/src/index.min',
      'es-dht': 'node_modules/es-dht/src/index.min',
      'autosize': 'node_modules/autosize/dist/autosize.min',
      'fixed-size-multiplexer': 'node_modules/fixed-size-multiplexer/src/index.min',
      'k-bucket-sync': 'node_modules/k-bucket-sync/src/index.min',
      'merkle-tree-binary': 'node_modules/merkle-tree-binary/src/index.min',
      'hotkeys-js': 'node_modules/hotkeys-js/dist/hotkeys.min',
      'marked': 'node_modules/marked/marked.min',
      'pako': 'node_modules/pako/dist/pako.min',
      'ronion': 'node_modules/ronion/src/index.min',
      'random-bytes-numbers': 'node_modules/random-bytes-numbers/src/index.min',
      'swipe-listener': 'node_modules/swipe-listener/dist/swipe-listener.min'
    },
    'packages': [
      {
        'name': 'aez.wasm',
        'location': 'node_modules/aez.wasm',
        'main': 'src/index.min'
      }, {
        'name': 'blake2.wasm',
        'location': 'node_modules/blake2.wasm',
        'main': 'src/index.min'
      }, {
        'name': 'ed25519-to-x25519.wasm',
        'location': 'node_modules/ed25519-to-x25519.wasm',
        'main': 'src/index.min'
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
  gulp.task('bundle-clean', function(){
    return del([DESTINATION + "/" + BUNDLED_CSS, DESTINATION + "/" + BUNDLED_HTML, DESTINATION + "/" + BUNDLED_JS, BUNDLED_SW]);
  }).task('bundle-css', function(){
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
  }).task('bundle-html', ['generate-html'], function(){
    var html, fonts, i$, len$, font, font_path, base_name, hash, r, used_fa_icons, m, unused_fa_icons, definition, icon, glyph, js;
    html = fs.readFileSync(DESTINATION + "/" + BUNDLED_HTML, {
      encoding: 'utf8'
    });
    html = html.replace(new RegExp('@font-face[^}]+(' + BLACKLISTED_FONTS.join('|') + ')[^}]+}', 'g'), '');
    fonts = html.match(FONTS_REGEXP);
    for (i$ = 0, len$ = fonts.length; i$ < len$; ++i$) {
      font = fonts[i$];
      font_path = font.substring(8, font.length - 2).split('?')[0];
      base_name = font_path.split('/').pop();
      hash = file_hash(font_path);
      html = html.replace(font, "url(" + base_name + "?" + hash + ")");
      fs.copyFileSync(font_path, DESTINATION + "/" + base_name);
    }
    r = /icon="([^"]+)"/g;
    used_fa_icons = new Set;
    while (m = r.exec(html)) {
      used_fa_icons.add(m[1]);
    }
    unused_fa_icons = [];
    r = /\.fa-([^:]+):before{content:"([^"]+)"}/g;
    while (m = r.exec(html)) {
      definition = m[0], icon = m[1], glyph = m[2];
      if (!used_fa_icons.has(icon)) {
        unused_fa_icons.push(definition);
      }
    }
    for (i$ = 0, len$ = unused_fa_icons.length; i$ < len$; ++i$) {
      definition = unused_fa_icons[i$];
      html = html.replace(definition, '');
    }
    js = html.match(SCRIPTS_REGEXP).map(function(string){
      string = string.trim();
      return string.substring(8, string.length - 9);
    }).join('');
    html = html.replace(/assetpath=".+?"/g, '').replace('<link rel="import" href="../node_modules/@polymer/shadycss/apply-shim.html">', '').replace('<link rel="import" href="../node_modules/@polymer/shadycss/custom-style-interface.html">', '').replace(SCRIPTS_REGEXP, '');
    fs.writeFileSync(DESTINATION + "/" + BUNDLED_HTML, html);
    fs.writeFileSync(DESTINATION + "/" + BUNDLED_JS, js);
  }).task('bundle-js', ['bundle-html'], function(){
    var config;
    config = Object.assign({
      name: DESTINATION + "/" + BUNDLED_JS,
      optimize: 'none',
      onBuildRead: function(arg$, arg1$, contents){
        return contents.replace(/define\("([^"]+)".split\(" "\)/, function(arg$, dependencies){
          return 'define(' + JSON.stringify(dependencies.split(' '));
        });
      },
      wrap: {
        startFile: ['js/a.require.js', 'js/b.webcomponentsready-wrap-before.js'],
        endFile: 'js/b.webcomponentsready-wrap-after.js'
      }
    }, requirejs_config);
    return gulp.src(DESTINATION + "/" + BUNDLED_JS).pipe(gulpRequirejsOptimize(config)).pipe(gulp.dest(DESTINATION));
  }).task('bundle-service-worker', ['generate-service-worker'], function(){
    var sw;
    fs.renameSync(DESTINATION + "/" + BUNDLED_SW, BUNDLED_SW);
    sw = fs.readFileSync(BUNDLED_SW, {
      encoding: 'utf8'
    });
    sw = sw.replace(/importScripts\("/, "$&" + DESTINATION + "/").replace(/modulePathPrefix:\s*?"/, "$&" + DESTINATION + "/");
    fs.writeFileSync(BUNDLED_SW, sw);
  }).task('clean', function(){
    return del(DESTINATION + "/*");
  }).task('copy-audio', ['bundle-js'], function(){
    var js, audios, i$, len$, audio, audio_path, base_name, hash;
    js = fs.readFileSync(DESTINATION + "/" + BUNDLED_JS, {
      encoding: 'utf8'
    });
    audios = js.match(AUDIO_REGEXP);
    for (i$ = 0, len$ = audios.length; i$ < len$; ++i$) {
      audio = audios[i$];
      audio_path = audio.substring(1, audio.length - 1);
      base_name = audio_path.split('/').pop();
      hash = file_hash(audio_path);
      js = js.replace(audio, "\"" + DESTINATION + "/" + base_name + "?" + hash + "\"");
      fs.copyFileSync(audio_path, DESTINATION + "/" + base_name);
    }
    fs.writeFileSync(DESTINATION + "/" + BUNDLED_JS, js);
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
    runSequence('clean', 'main-build', 'bundle-clean', 'minify-service-worker', 'bundle-clean', 'update-index', callback);
  }).task('generate-html', function(callback){
    var command;
    command = "node_modules/.bin/polymer-bundler --strip-comments --rewrite-urls-in-templates --inline-css --inline-scripts --out-html " + DESTINATION + "/" + BUNDLED_HTML + " " + SOURCE_HTML;
    exec(command, function(error, stdout, stderr){
      if (stdout) {
        console.log(stdout);
      }
      if (stderr) {
        console.error(stderr);
      }
      callback(error);
    });
  }).task('generate-service-worker', function(){
    return workboxBuild.generateSW({
      cacheId: 'detox-chat-app',
      clientsClaim: true,
      globDirectory: '.',
      globPatterns: [DESTINATION + "/*", 'index.html'],
      ignoreUrlParametersMatching: [/./],
      importWorkboxFrom: 'local',
      skipWaiting: true,
      swDest: DESTINATION + "/sw.js",
      manifestTransforms: [function(entries){
        var i$, len$, entry;
        for (i$ = 0, len$ = entries.length; i$ < len$; ++i$) {
          entry = entries[i$];
          entry.revision = entry.revision.substr(0, 5);
          if (entry.url !== 'index.html') {
            entry.url += '?' + entry.revision;
          }
        }
        return {
          manifest: entries
        };
      }]
    });
  }).task('main-build', ['copy-audio', 'copy-favicon', 'copy-js', 'copy-manifest', 'copy-wasm', 'minify-css', 'minify-html', 'minify-font', 'minify-js']).task('minify-css', ['bundle-css'], function(){
    var css;
    css = fs.readFileSync(DESTINATION + "/" + BUNDLED_CSS, {
      encoding: 'utf8'
    });
    fs.writeFileSync(DESTINATION + "/" + MINIFIED_CSS, minify_css(css));
  }).task('minify-font', ['bundle-html'], function(callback){
    var font, css, command;
    font = __dirname + ("/" + DESTINATION + "/" + FA_FONT);
    css = __dirname + ("/" + DESTINATION + "/" + BUNDLED_HTML);
    command = "docker run --rm -v " + font + ":/font.woff2 -v " + css + ":/style.css nazarpc/subset-font";
    exec(command, function(error, stdout, stderr){
      var html, r, hash;
      html = fs.readFileSync(DESTINATION + "/" + BUNDLED_HTML, {
        encoding: 'utf8'
      });
      r = new RegExp(FA_FONT + "\\?\\w+");
      hash = file_hash(font);
      html = html.replace(r, FA_FONT + "?" + hash);
      fs.writeFileSync(DESTINATION + "/" + BUNDLED_HTML, html);
      stdout = stdout.replace("[INFO] Subsetting font '/tmp/font.ttf' with ebook '/tmp/characters' into new font '/tmp/font.ttf', containing the following glyphs:\n", '').replace('Processing /tmp/font.ttf => /tmp/font.woff2\n', '').trim();
      stderr = stderr.replace(/^The glyph named .+ is mapped to.+\n/gm, '').replace(/^But its name indicates it should be mapped to.+\n/gm, '').replace('Traceback (most recent call last):\n  File "/usr/bin/glyphIgo", line 1353, in <module>\n    main()\n  File "/usr/bin/glyphIgo", line 1344, in main\n    returnCode = GlyphIgo(args).execute()\n  File "/usr/bin/glyphIgo", line 1333, in execute\n    returnCode = self.__do_subset()\n  File "/usr/bin/glyphIgo", line 1307, in __do_subset\n    self.__print_char_list(found_char_list)\n  File "/usr/bin/glyphIgo", line 992, in __print_char_list\n    print "\'%s\'\\t%s\\t%s\\t%s" % (escape(c[0]), decCodePoint, hexCodePoint, name)\nUnicodeEncodeError: \'ascii\' codec can\'t encode character u\'\\uf00c\' in position 1: ordinal not in range(128)', '').replace(/^Compressed \d+ to \d+\.\n/gm, '').trim();
      if (stdout) {
        console.log(stdout);
      }
      if (stderr) {
        console.error(stderr);
      }
      callback();
    });
  }).task('minify-html', ['bundle-html', 'minify-font'], function(){
    return gulp.src(DESTINATION + "/" + BUNDLED_HTML).pipe(gulpHtmlmin({
      decodeEntities: true,
      minifyCSS: minify_css,
      removeComments: true
    })).pipe(gulpRename(MINIFIED_HTML)).pipe(gulp.dest(DESTINATION));
  }).task('minify-js', ['bundle-js', 'copy-wasm'], function(){
    var js;
    js = fs.readFileSync(DESTINATION + "/" + BUNDLED_JS, {
      encoding: 'utf8'
    });
    js = js.replace("typeof requirejs === 'function'", 'false').replace(/"function"===?typeof define&&define.amd/g, 'true');
    fs.writeFileSync(DESTINATION + "/" + BUNDLED_JS, js);
    return gulp.src(DESTINATION + "/" + BUNDLED_JS).pipe(uglify()).pipe(gulpRename(MINIFIED_JS)).pipe(gulp.dest(DESTINATION));
  }).task('minify-service-worker', ['bundle-service-worker'], function(){
    return gulp.src(BUNDLED_SW).pipe(uglify()).pipe(gulpRename(MINIFIED_SW)).pipe(gulp.dest('.'));
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
}).call(this);
