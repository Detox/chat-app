/**
 * @package Detox chat app
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
clean-css				= require('clean-css')
del						= require('del')
exec					= require('child_process').exec
fs						= require('fs')
gulp					= require('gulp')
gulp-htmlmin			= require('gulp-htmlmin')
gulp-rename				= require('gulp-rename')
gulp-requirejs-optimize	= require('gulp-requirejs-optimize')
uglify-es				= require('uglify-es')
uglify					= require('gulp-uglify/composer')(uglify-es, console)

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
const BUNDLED_HTML		= 'index.html'
const MINIFIED_HTML		= 'index.min.html'
const BUNDLED_JS		= 'script.js'
const MINIFIED_JS		= 'script.min.js'

requirejs_config	=
	'baseUrl'	: '.'
	'paths'		:
		'@detox/base-x'				: 'node_modules/@detox/base-x/index'
		'@detox/chat'				: 'node_modules/@detox/chat/src/index'
		'@detox/core'				: 'node_modules/@detox/core/src/index'
		'@detox/crypto'				: 'node_modules/@detox/crypto/src/index'
		'@detox/dht'				: 'node_modules/@detox/dht/dist/detox-dht.browser'
		'@detox/transport'			: 'node_modules/@detox/transport/src/index'
		'@detox/utils'				: 'node_modules/@detox/utils/src/index'
		'async-eventer'				: 'node_modules/async-eventer/src/index'
		'autosize'					: 'node_modules/autosize/dist/autosize'
		'fixed-size-multiplexer'	: 'node_modules/fixed-size-multiplexer/src/index'
		'ronion'					: 'node_modules/ronion/dist/ronion.browser'
		'pako'						: 'node_modules/pako/dist/pako'
		'state'						: 'js/state'
	'packages'	: [
		{
			'name'		: 'aez.wasm',
			'location'	: 'node_modules/aez.wasm',
			'main'		: 'src/index'
		}
		{
			'name'		: 'ed25519-to-x25519.wasm',
			'location'	: 'node_modules/ed25519-to-x25519.wasm',
			'main'		: 'src/index'
		}
		{
			'name'		: 'jssha',
			'location'	: 'node_modules/jssha',
			'main'		: 'src/sha'
		}
		{
			'name'		: 'noise-c.wasm',
			'location'	: 'node_modules/noise-c.wasm',
			'main'		: 'src/index'
		}
		{
			'name'		: 'supercop.wasm',
			'location'	: 'node_modules/supercop.wasm',
			'main'		: 'src/index'
		}
	]

gulp
	.task('dist', [/*'dist-css', */'dist-html', 'dist-js', /* 'dist-index',*/ 'dist-wasm'])
	.task('dist-css', ['clean'], !->
		# TODO: Minify css/* files, copy background images to dist directory too
	)
	.task('dist-html', ['clean', 'minify-html'])
	.task('dist-js', ['clean', 'minify-js'])
	.task('dist-index', ['clean'], !->
		# TODO: Build production index.html that will consume minified versions of everything
	)
	.task('dist-wasm', ['clean'], !->
		for {name, location, main} in requirejs_config.packages
			if name.endsWith('.wasm')
				fs.copyFileSync("#location/src/#name", "#DESTINATION/#name")
	)
	.task('clean', ->
		del("#DESTINATION/*")
	)
	.task('minify-html', ['bundle-html'], ->
		gulp.src("#DESTINATION/#BUNDLED_HTML")
			.pipe(gulp-htmlmin(
				decodeEntities	: true
				minifyCSS		: minify-css
				removeComments	: true
			))
			.pipe(gulp-rename(MINIFIED_HTML))
			.pipe(gulp.dest(DESTINATION))
	)
	.task('bundle-html', (callback) !->
		command		= "node_modules/.bin/polymer-bundler --strip-comments --rewrite-urls-in-templates --inline-css --inline-scripts --out-html #DESTINATION/#BUNDLED_HTML #SOURCE_HTML"
		exec(command, (error, stdout, stderr) !->
			if stdout
				console.log(stdout)
			if stderr
				console.error(stderr)
			html	= fs.readFileSync("#DESTINATION/#BUNDLED_HTML", {encoding: 'utf8'})
			js		= html.match(SCRIPTS_REGEXP)
				.map (string) ->
					string	= string.trim()
					string.substring(8, string.length - 9) # Remove script tag
				.join('')
			html	= html
				# Useless (in our case) arguments
				.replace(/assetpath=".+"/g, '')
				# These 2 files are referenced, but do not actually exist (because Polymer uses crappy practices for its packages)
				.replace('<link rel="import" href="../node_modules/@polymer/shadycss/apply-shim.html">', '')
				.replace('<link rel="import" href="../node_modules/@polymer/shadycss/custom-style-interface.html">', '')
				# Remove all <script> tags, we'll have them included separately
				.replace(SCRIPTS_REGEXP, '')
			fs.writeFileSync("#DESTINATION/#BUNDLED_HTML", html)
			fs.writeFileSync("#DESTINATION/#BUNDLED_JS", js)
			callback(error)
		)
	)
	.task('minify-js', ['bundle-js'], ->
		gulp.src("#DESTINATION/#BUNDLED_JS")
			.pipe(uglify())
			.pipe(gulp-rename(MINIFIED_JS))
			.pipe(gulp.dest(DESTINATION))
	)
	.task('bundle-js', ['bundle-html'], ->
		config	= Object.assign({
			name		: "#DESTINATION/#BUNDLED_JS"
			optimize	: 'none'
		}, requirejs_config)
		gulp.src("#DESTINATION/#BUNDLED_JS")
			.pipe(gulp-requirejs-optimize(config))
			.pipe(gulp.dest(DESTINATION))
	)
