/**
 * @package Detox chat app
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
clean-css				= require('clean-css')
crypto					= require('crypto')
del						= require('del')
exec					= require('child_process').exec
fs						= require('fs')
gulp					= require('gulp')
gulp-htmlmin			= require('gulp-htmlmin')
gulp-rename				= require('gulp-rename')
gulp-requirejs-optimize	= require('gulp-requirejs-optimize')
run-sequence			= require('run-sequence')
uglify-es				= require('uglify-es')
uglify					= require('gulp-uglify/composer')(uglify-es, console)

minify_css	= do
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
minify_js	= (text) ->
	result	= uglify-es.minify(text)
	if result.error
		console.log(result.error)
	result.code
file_hash	= (file) ->
	file_contents	= fs.readFileSync(file)
	crypto.createHash('md5').update(file_contents).digest('hex').substr(0, 5)

const SCRIPTS_REGEXP	= /<script>[^]+?<\/script>\n*/g
const FONTS_REGEXP		= /url\(.+?\.woff2.+?\)/g
const IMAGES_REGEXP		= /url\(\.\.\/img\/.+?\)/g
const SOURCE_CSS		= 'css/style.css'
const SOURCE_HTML		= 'html/index.html'
const DESTINATION		= 'dist'
const BUNDLED_CSS		= 'style.css'
const MINIFIED_CSS		= 'style.min.css'
const BUNDLED_HTML		= 'index.html'
const MINIFIED_HTML		= 'index.min.html'
const BUNDLED_JS		= 'script.js'
const MINIFIED_JS		= 'script.min.js'

requirejs_config	=
	'baseUrl'	: '.'
	'paths'		:
		'@detox/base-x'				: 'node_modules/@detox/base-x/index.min'
		'@detox/chat'				: 'node_modules/@detox/chat/src/index.min'
		'@detox/core'				: 'node_modules/@detox/core/src/index.min'
		'@detox/crypto'				: 'node_modules/@detox/crypto/src/index.min'
		'@detox/dht'				: 'node_modules/@detox/dht/dist/detox-dht.browser.min'
		# TODO: Closure Compiler replaces array of dependencies with '...'.split(' ') and causes build to fail when using minified version of @detox/transport
		'@detox/transport'			: 'node_modules/@detox/transport/src/index'
		'@detox/utils'				: 'node_modules/@detox/utils/src/index.min'
		'async-eventer'				: 'node_modules/async-eventer/src/index.min'
		'autosize'					: 'node_modules/autosize/dist/autosize.min'
		'fixed-size-multiplexer'	: 'node_modules/fixed-size-multiplexer/src/index.min'
		'ronion'					: 'node_modules/ronion/dist/ronion.browser.min'
		'pako'						: 'node_modules/pako/dist/pako.min'
		'state'						: 'js/state'
	'packages'	: [
		{
			'name'		: 'aez.wasm',
			'location'	: 'node_modules/aez.wasm',
			'main'		: 'src/index.min'
		}
		{
			'name'		: 'ed25519-to-x25519.wasm',
			'location'	: 'node_modules/ed25519-to-x25519.wasm',
			'main'		: 'src/index.min'
		}
		{
			'name'		: 'jssha',
			'location'	: 'node_modules/jssha',
			'main'		: 'src/sha'
		}
		{
			'name'		: 'noise-c.wasm',
			'location'	: 'node_modules/noise-c.wasm',
			'main'		: 'src/index.min'
		}
		{
			'name'		: 'supercop.wasm',
			'location'	: 'node_modules/supercop.wasm',
			'main'		: 'src/index.min'
		}
	]

gulp
	.task('bundle-css', !->
		css		= fs.readFileSync("#SOURCE_CSS", {encoding: 'utf8'})
		images	= css.match(IMAGES_REGEXP)
		for image in images
			image_path		= image.substring(7, image.length - 1)
			image_source	= fs.readFileSync(image_path, {encoding: 'utf8'})
			image_data_uri	= 'url(data:image/svg+xml;utf8,' + image_source.replace(/#/g, '%23') + ')'
			css				= css.replace(image, image_data_uri)
		fs.writeFileSync("#DESTINATION/#BUNDLED_CSS", css)
	)
	.task('bundle-html', (callback) !->
		command		= "node_modules/.bin/polymer-bundler --strip-comments --rewrite-urls-in-templates --inline-css --inline-scripts --out-html #DESTINATION/#BUNDLED_HTML #SOURCE_HTML"
		exec(command, (error, stdout, stderr) !->
			if stdout
				console.log(stdout)
			if stderr
				console.error(stderr)
			html	= fs.readFileSync("#DESTINATION/#BUNDLED_HTML", {encoding: 'utf8'})
			fonts	= html.match(FONTS_REGEXP)
			for font in fonts
				font_path	= font.substring(8, font.length - 2).split('?')[0]
				base_name	= font_path.split('/').pop()
				hash		= file_hash(font_path)
				html		= html.replace(font, "url(#base_name?#hash)")
				fs.copyFileSync(font_path, "#DESTINATION/#base_name")
			js		= html.match(SCRIPTS_REGEXP)
				.map (string) ->
					string	= string.trim()
					string.substring(8, string.length - 9) # Remove script tag
				.join('')
			# Wrapper ensures that code is only running when HTML imports were loaded
			# We also force async stylesheet loading and actually apply it by setting `media` property to empty string
			js		= """
(function (callback) {
	document.head.querySelector('[media=async]').removeAttribute('media');
	if (window.WebComponents && window.WebComponents.ready) {
		callback();
	} else {
		function ready () {
			callback();
			document.removeEventListener('WebComponentsReady', ready);
		}
		document.addEventListener('WebComponentsReady', ready);
	}
})(function () {#js})
			"""
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
	.task('bundle-js', ['bundle-html'], ->
		config	= Object.assign({
			name		: "#DESTINATION/#BUNDLED_JS"
			optimize	: 'none'
		}, requirejs_config)
		gulp.src("#DESTINATION/#BUNDLED_JS")
			.pipe(gulp-requirejs-optimize(config))
			.pipe(gulp.dest(DESTINATION))
	)
	.task('clean', ->
		del("#DESTINATION/*")
	)
	.task('copy-js', !->
		alameda			= fs.readFileSync('node_modules/alameda/alameda.js', {encoding: 'utf8'})
		webcomponents	= fs.readFileSync('node_modules/@webcomponents/webcomponentsjs/webcomponents-hi-sd-ce.js', {encoding: 'utf8'})
		fs.writeFileSync("#DESTINATION/alameda.min.js", minify_js(alameda))
		fs.writeFileSync("#DESTINATION/webcomponents.min.js", minify_js(webcomponents))
	)
	.task('copy-wasm', ['bundle-js'], !->
		js	= fs.readFileSync("#DESTINATION/#BUNDLED_JS", {encoding: 'utf8'})
		for {name, location, main} in requirejs_config.packages
			if name.endsWith('.wasm')
				hash	= file_hash("#location/src/#name")
				# This is a hack, but it works for now
				js		= js.replace("=\"#name\"", "=\"#name?#hash\"")
				fs.copyFileSync("#location/src/#name", "#DESTINATION/#name")
		fs.writeFileSync("#DESTINATION/#BUNDLED_JS", js)
	)
	.task('default', (callback) !->
		run-sequence('dist', 'dist:clean', callback)
	)
	.task('dist', (callback) !->
		run-sequence('clean', ['copy-js', 'copy-wasm', 'minify-css', 'minify-html', 'minify-js'], 'update-index', callback)
	)
	.task('dist:clean', ->
		del(["#DESTINATION/#BUNDLED_CSS", "#DESTINATION/#BUNDLED_HTML", "#DESTINATION/#BUNDLED_JS"])
	)
	.task('minify-css', ['bundle-css'], !->
		css	= fs.readFileSync("#DESTINATION/#BUNDLED_CSS", {encoding: 'utf8'})
		fs.writeFileSync("#DESTINATION/#MINIFIED_CSS", minify_css(css))
	)
	.task('minify-html', ['bundle-html'], ->
		gulp.src("#DESTINATION/#BUNDLED_HTML")
			.pipe(gulp-htmlmin(
				decodeEntities	: true
				minifyCSS		: minify_css
				removeComments	: true
			))
			.pipe(gulp-rename(MINIFIED_HTML))
			.pipe(gulp.dest(DESTINATION))
	)
	.task('minify-js', ['bundle-js', 'copy-wasm'], ->
		gulp.src("#DESTINATION/#BUNDLED_JS")
			.pipe(uglify())
			.pipe(gulp-rename(MINIFIED_JS))
			.pipe(gulp.dest(DESTINATION))
	)
	.task('update-index', !->
		alameda_hash		= file_hash("#DESTINATION/alameda.min.js")
		index_hash			= file_hash("#DESTINATION/index.min.html")
		script_hash			= file_hash("#DESTINATION/script.min.js")
		style_hash			= file_hash("#DESTINATION/style.min.css")
		webcomponents_hash	= file_hash("#DESTINATION/webcomponents.min.js")
		index				= fs.readFileSync('index.html', {encoding: 'utf8'})
		critical_css		= fs.readFileSync('css/critical.css', {encoding: 'utf8'}).trim()
		index				= index
			.replace(/dist\/alameda\.min\.js[^"]*/g, "dist/alameda.min.js?#alameda_hash")
			.replace(/dist\/index\.min\.html[^"]*/g, "dist/index.min.html?#index_hash")
			.replace(/dist\/script\.min\.js[^"]*/g, "dist/script.min.js?#script_hash")
			.replace(/dist\/style\.min\.css[^"]*/g, "dist/style.min.css?#style_hash")
			.replace(/dist\/webcomponents\.min\.js[^"]*/g, "dist/webcomponents.min.js?#webcomponents_hash")
			.replace(/<style>.*?<\/style>/g, "<style>#critical_css</style>")
		fs.writeFileSync('index.html', index)
	)
