/**
 * @package Detox chat app
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
clean-css	= require('clean-css')
del			= require('del')
exec		= require('child_process').exec
fs			= require('fs')
gulp		= require('gulp')
htmlmin		= require('gulp-htmlmin')
uglify-es	= require('uglify-es')

minify-css	= do
	instance	= new clean-css(
		level	:
			1	:
				specialComments	: 0
	)
	(text) ->
		result	= instance.minify(text)
		if result.error
			console.log(result.error)
		result.styles
minify-js	= (text) ->
	result	= uglify-es.minify(text)
	if result.error
		console.log(result.error)
	result.code

const SCRIPTS_REGEXP	= /<script>[^]+?<\/script>\n*/g
const SOURCE_HTML		= 'html/index.html'
const DESTINATION		= 'dist'
const MINIFIED_HTML		= 'index.min.html'

gulp
	.task('dist', ['clean', 'dist-css', 'dist-html', 'dist-js', 'dist-index'])
	.task('clean', ->
		del("#DESTINATION/*")
	)
	.task('dist-css', !->
		# TODO: Minify css/* files
	)
	.task('dist-html', ['bundle-webcomponents'], ->
		gulp.src("#DESTINATION/#MINIFIED_HTML")
			.pipe(htmlmin(
				decodeEntities	: true
				minifyCSS		: minify-css
				minifyJS		: minify-js
				removeComments	: true
			))
			.pipe(gulp.dest(DESTINATION))
	)
	.task('bundle-webcomponents', (callback) !->
		command		= "node_modules/.bin/polymer-bundler --strip-comments --rewrite-urls-in-templates --inline-css --inline-scripts --out-html #DESTINATION/#MINIFIED_HTML #SOURCE_HTML"
		exec(command, (error, stdout, stderr) !->
			if stdout
				console.log(stdout)
			if stderr
				console.error(stderr)
			code	= fs.readFileSync("#DESTINATION/#MINIFIED_HTML", {encoding: 'utf8'})
			scripts	= code.match(SCRIPTS_REGEXP)
				.map (string) ->
					string	= string.trim()
					string.substring(8, string.length - 9) # Remove script tag
				.join('')
			code	= code
				# Useless (in our case) arguments
				.replace(/assetpath=".+"/g, '')
				# These 2 files are referenced, but do not actually exist (because Polymer uses crappy practices for its packages)
				.replace('<link rel="import" href="../node_modules/@polymer/shadycss/apply-shim.html">', '')
				.replace('<link rel="import" href="../node_modules/@polymer/shadycss/custom-style-interface.html">', '')
				# Remove all <script> tags, we'll add them in one place later
				.replace(SCRIPTS_REGEXP, '')
			code	+= "<script>#scripts</script>"
			fs.writeFileSync("#DESTINATION/#MINIFIED_HTML", code)
			callback(error)
		)
	)
	.task('dist-js', !->
		# TODO: Minify js/* files and potentially RequireJS modules in future
	)
	.task('dist-index', !->
		# TODO: Build production index.html that will consume minified versions of everything
	)
