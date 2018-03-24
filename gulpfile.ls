/**
 * @package Detox chat app
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
clean-css	= require('clean-css')
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

const SOURCE_FILE	= 'html/index.html'
const MINIFIED_FILE	= 'html/index.min.html'
const MINIFIED_DIR	= 'html'

# TODO: Place everything into `dist`
gulp
	.task('dist', ['dist-css', 'dist-html', 'dist-js', 'dist-index'])
	.task('dist-css', !->
		# TODO: Minify css/* files
	)
	.task('dist-html', ['bundle-webcomponents'], ->
		gulp.src('html/index.min.html')
			.pipe(htmlmin(
				decodeEntities				: true
				minifyCSS					: minify-css
				minifyJS					: minify-js
				removeComments				: true
			))
			.pipe(gulp.dest('html'))
	)
	.task('bundle-webcomponents', (callback) !->
		command		= "node_modules/.bin/polymer-bundler --strip-comments --rewrite-urls-in-templates --inline-css --inline-scripts --out-html #MINIFIED_FILE #SOURCE_FILE"
		exec(command, (error, stdout, stderr) !->
			if stdout
				console.log(stdout)
			if stderr
				console.error(stderr)
			code	= fs.readFileSync(MINIFIED_FILE, {encoding: 'utf8'})
			code	= code
				# Useless (in our case) arguments
				.replace(/assetpath=".+"/g, '')
				# These 2 files are referenced, but do not actually exist (because Polymer uses crappy practices for its packages)
				.replace('<link rel="import" href="../node_modules/@polymer/shadycss/apply-shim.html">', '')
				.replace('<link rel="import" href="../node_modules/@polymer/shadycss/custom-style-interface.html">', '')
				# There is no need to have multiple <script> tags one after another, let's merge them into one
				.replace(/<\/script>\n+<script>/g, '')
			fs.writeFileSync(MINIFIED_FILE, code)
			callback(error)
		)
	)
	.task('dist-js', !->
		# TODO: Minify js/* files and potentially RequireJS modules in future
	)
	.task('dist-index', !->
		# TODO: Build production index.html that will consume minified versions of everything
	)
