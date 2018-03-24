// Generated by LiveScript 1.5.0
/**
 * @package Detox chat app
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
(function(){
  var cleanCss, del, exec, fs, gulp, htmlmin, uglifyEs, minifyCss, instance, minifyJs, SOURCE_HTML, DESTINATION, MINIFIED_HTML;
  cleanCss = require('clean-css');
  del = require('del');
  exec = require('child_process').exec;
  fs = require('fs');
  gulp = require('gulp');
  htmlmin = require('gulp-htmlmin');
  uglifyEs = require('uglify-es');
  minifyCss = (instance = new cleanCss({
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
  minifyJs = function(text){
    var result;
    result = uglifyEs.minify(text);
    if (result.error) {
      console.log(result.error);
    }
    return result.code;
  };
  SOURCE_HTML = 'html/index.html';
  DESTINATION = 'dist';
  MINIFIED_HTML = 'index.min.html';
  gulp.task('dist', ['clean', 'dist-css', 'dist-html', 'dist-js', 'dist-index']).task('clean', function(){
    return del(DESTINATION + "/*");
  }).task('dist-css', function(){}).task('dist-html', ['bundle-webcomponents'], function(){
    return gulp.src(DESTINATION + "/" + MINIFIED_HTML).pipe(htmlmin({
      decodeEntities: true,
      minifyCSS: minifyCss,
      minifyJS: minifyJs,
      removeComments: true
    })).pipe(gulp.dest(DESTINATION));
  }).task('bundle-webcomponents', function(callback){
    var command;
    command = "node_modules/.bin/polymer-bundler --strip-comments --rewrite-urls-in-templates --inline-css --inline-scripts --out-html " + DESTINATION + "/" + MINIFIED_HTML + " " + SOURCE_HTML;
    exec(command, function(error, stdout, stderr){
      var code;
      if (stdout) {
        console.log(stdout);
      }
      if (stderr) {
        console.error(stderr);
      }
      code = fs.readFileSync(DESTINATION + "/" + MINIFIED_HTML, {
        encoding: 'utf8'
      });
      code = code.replace(/assetpath=".+"/g, '').replace('<link rel="import" href="../node_modules/@polymer/shadycss/apply-shim.html">', '').replace('<link rel="import" href="../node_modules/@polymer/shadycss/custom-style-interface.html">', '').replace(/<\/script>\n+<script>/g, '');
      fs.writeFileSync(DESTINATION + "/" + MINIFIED_HTML, code);
      callback(error);
    });
  }).task('dist-js', function(){}).task('dist-index', function(){});
}).call(this);
