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
workbox-build			= require('workbox-build')

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

const FONTS_REGEXP		= /url\(.+?\.woff2.+?\)/g
const IMAGES_REGEXP		= /url\(\.\.\/img\/.+?\)/g
const SCRIPTS_REGEXP	= /<script>[^]+?<\/script>\n*/g

const BLACKLISTED_FONTS	= [
	'fa-regular-400.woff2'
	'fa-brands-400.woff2'
]
const FA_FONT			= 'fa-solid-900.woff2'

const BUNDLED_CSS		= 'style.css'
const BUNDLED_HTML		= 'index.html'
const BUNDLED_JS		= 'script.js'
const BUNDLED_MANIFEST	= 'manifest.json'
const BUNDLED_SW		= 'sw.js'
const DESTINATION		= 'dist'
const MINIFIED_CSS		= 'style.min.css'
const MINIFIED_HTML		= 'index.min.html'
const MINIFIED_JS		= 'script.min.js'
const MINIFIED_SW		= 'sw.min.js'
const SOURCE_CSS		= 'css/style.css'
const SOURCE_HTML		= 'html/index.html'
const SOURCE_MANIFEST	= 'manifest.json'

/**
 * Wrapper:
 * 1) provides simplified require/define implementation that replaces alameda and should be enough for bundled modules
 * 2) ensures that code is only running when HTML imports were loaded
 * 3) forces async stylesheet loading and actually apply it by setting `media` property to empty string
 */
function js_shell (js)
	"""
let require, requirejs, define;
(callback => {
	let defined_modules = {}, current_module = {exports: null}, wait_for = {};
	function get_defined_module (name, base_name) {
		if (name == 'exports') {
			return {};
		} else if (name == 'module') {
			return current_module;
		} else {
			if (name.startsWith('./')) {
				name	= base_name.split('/').slice(0, -1).join('/') + '/' + name.substr(2);
			}
			return defined_modules[name];
		}
	}
	function load_dependencies (dependencies, base_name, fail_callback) {
		const loaded_dependencies = [];
		return dependencies.every(dependency => {
			const loaded_dependency = get_defined_module(dependency, base_name);
			if (!loaded_dependency) {
				if (fail_callback) {
					fail_callback(dependency);
				}
				return false;
			}
			loaded_dependencies.push(loaded_dependency);
			return true;
		}) && loaded_dependencies;
	}
	function add_wait_for (name, callback) {
		(wait_for[name] = wait_for[name] || []).push(callback);
	}
	require = requirejs = (dependencies, callback) => {
		return new Promise(resolve => {
			const loaded_dependencies = load_dependencies(
				dependencies,
				'',
				dependency => add_wait_for(
					dependency,
					require.bind(null, dependencies, (...loaded_dependencies) => {
						if (callback) {
							callback(...loaded_dependencies);
						}
						resolve(loaded_dependencies);
					})
				)
			);
			if (loaded_dependencies) {
				if (callback) {
					callback(...loaded_dependencies);
				}
				resolve(loaded_dependencies);
			}
		});
	};
	define = (name, dependencies, wrapper) => {
		if (!wrapper) {
			wrapper			= dependencies;
			dependencies	= [];
		}
		const loaded_dependencies = load_dependencies(
			dependencies,
			name,
			dependency => add_wait_for(dependency, define.bind(null, name, dependencies, wrapper))
		);
		if (loaded_dependencies) {
			defined_modules[name] = wrapper(...loaded_dependencies) || current_module.exports;
			if (wait_for[name]) {
				wait_for[name].forEach(resolve => resolve());
				delete wait_for[name];
			}
		}
	};
	define.amd = {};
	document.head.querySelector('[media=async]').removeAttribute('media');
	if (window.WebComponents && window.WebComponents.ready) {
		callback();
	} else {
		document.addEventListener('WebComponentsReady', callback, {once: true});
	}
})(() => {#js})
"""

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
		'hotkeys-js'				: 'node_modules/hotkeys-js/dist/hotkeys.min'
		'marked'					: 'node_modules/marked/marked.min'
		'pako'						: 'node_modules/pako/dist/pako.min'
		'ronion'					: 'node_modules/ronion/src/index.min'
		'simple-peer'				: 'node_modules/simple-peer/simplepeer.min'
		'swipe-listener'			: 'node_modules/swipe-listener/dist/swipe-listener.min'
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
	.task('bundle-clean', ->
		del(["#DESTINATION/#BUNDLED_CSS", "#DESTINATION/#BUNDLED_HTML", "#DESTINATION/#BUNDLED_JS", BUNDLED_SW])
	)
	.task('bundle-css', !->
		css		= fs.readFileSync("#SOURCE_CSS", {encoding: 'utf8'})
		images	= css.match(IMAGES_REGEXP)
		for image in images
			image_path	= image.substring(7, image.length - 1)
			base_name	= image_path.split('/').pop()
			hash		= file_hash(image_path)
			css			= css.replace(image, "url(#DESTINATION/#base_name?#hash)")
			fs.copyFileSync(image_path, "#DESTINATION/#base_name")
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
			# Hack: we know for sure that these files fonts will not be used, so lets remove unused fonts from stylesheet entirely
			html	= html.replace(new RegExp('@font-face[^}]+(' + BLACKLISTED_FONTS.join('|') + ')[^}]+}', 'g'), '')
			fonts	= html.match(FONTS_REGEXP)
			for font in fonts
				font_path	= font.substring(8, font.length - 2).split('?')[0]
				base_name	= font_path.split('/').pop()
				hash		= file_hash(font_path)
				html		= html.replace(font, "url(#base_name?#hash)")
				fs.copyFileSync(font_path, "#DESTINATION/#base_name")
			r				= /icon="([^"]+)"/g
			used_fa_icons	= new Set
			while m = r.exec(html)
				used_fa_icons.add(m[1])
			unused_fa_icons	= []
			r				= /\.fa-([^:]+):before{content:"([^"]+)"}/g
			while m = r.exec(html)
				[definition, icon, glyph]	= m
				if !used_fa_icons.has(icon)
					unused_fa_icons.push(definition)
			# Remove unused icons definitions
			for definition in unused_fa_icons
				html	= html.replace(definition, '')
			js = html.match(SCRIPTS_REGEXP)
				.map (string) ->
					string	= string.trim()
					string.substring(8, string.length - 9) # Remove script tag
				.join('')
			js		= js_shell(js)
			html	= html
				# Useless (in our case) arguments
				.replace(/assetpath=".+?"/g, '')
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
	.task('bundle-service-worker', ['generate-service-worker'], !->
		fs.renameSync("#DESTINATION/#BUNDLED_SW", BUNDLED_SW)
		sw	= fs.readFileSync(BUNDLED_SW, {encoding: 'utf8'})
		# TODO: Hack, should be possible to remove in future when https://github.com/GoogleChrome/workbox/pull/1403 lands in stable version
		sw	= sw
			.replace(/importScripts\("/, "$&#DESTINATION/")
			.replace(/modulePathPrefix:\s*?"/, "$&#DESTINATION/")
		fs.writeFileSync(BUNDLED_SW, sw)
	)
	.task('clean', ->
		del("#DESTINATION/*")
	)
	.task('copy-favicon', !->
		fs.copyFileSync('favicon.ico', "#DESTINATION/favicon.ico")
	)
	.task('copy-js', !->
		webcomponents	= fs.readFileSync('node_modules/@webcomponents/webcomponentsjs/webcomponents-hi-sd-ce.js', {encoding: 'utf8'})
		fs.writeFileSync("#DESTINATION/webcomponents.min.js", minify_js(webcomponents))
	)
	.task('copy-manifest', !->
		manifest			= JSON.parse(fs.readFileSync("#SOURCE_MANIFEST", {encoding: 'utf8'}))
		manifest.start_url	= '../' + manifest.start_url
		for icon in manifest.icons
			base_name	= icon.src.split('/').pop()
			hash		= file_hash(icon.src)
			fs.copyFileSync(icon.src, "#DESTINATION/#base_name")
			icon.src	= "#base_name?#hash"
		fs.writeFileSync("#DESTINATION/#BUNDLED_MANIFEST", JSON.stringify(manifest))
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
		run-sequence('clean', 'main-build', 'bundle-clean', 'minify-service-worker', 'bundle-clean', 'update-index', callback)
	)
	.task('generate-service-worker', ->
		workbox-build.generateSW(
			cacheId						: 'detox-chat-app'
			clientsClaim				: true
			globDirectory				: '.'
			globPatterns				: [
				"#DESTINATION/*"
				'index.html'
			]
			ignoreUrlParametersMatching	: [/./]
			importWorkboxFrom			: 'local'
			skipWaiting					: true
			swDest						: "#DESTINATION/sw.js"
			manifestTransforms			: [
				(entries) ->
					for entry in entries
						entry.revision	= entry.revision.substr(0, 5)
						if entry.url != 'index.html'
							entry.url		+= '?' + entry.revision
					{manifest: entries}
			]
		)
	)
	.task('main-build', ['copy-favicon', 'copy-js', 'copy-manifest', 'copy-wasm', 'minify-css', 'minify-html', 'minify-font', 'minify-js'])
	.task('minify-css', ['bundle-css'], !->
		css	= fs.readFileSync("#DESTINATION/#BUNDLED_CSS", {encoding: 'utf8'})
		fs.writeFileSync("#DESTINATION/#MINIFIED_CSS", minify_css(css))
	)
	.task('minify-font', ['bundle-html'], (callback) !->
		font		= __dirname + "/#DESTINATION/#FA_FONT"
		html		= __dirname + "/#DESTINATION/#BUNDLED_HTML"
		command		= "docker run --rm -v #font:/font.woff2 -v #html:/style.css nazarpc/subset-font"
		exec(command, (error, stdout, stderr) !->
			# Remove some known harmless output
			stdout	= stdout
				.replace("[INFO] Subsetting font '/tmp/font.ttf' with ebook '/tmp/characters' into new font '/tmp/font.ttf', containing the following glyphs:\n", '')
				.replace('Processing /tmp/font.ttf => /tmp/font.woff2\n', '')
				.trim()
			# Remove some known harmless output
			stderr	= stderr
				.replace(/^The glyph named .+ is mapped to.+\n/gm, '')
				.replace(/^But its name indicates it should be mapped to.+\n/gm, '')
				.replace('Traceback (most recent call last):\n  File "/usr/bin/glyphIgo", line 1353, in <module>\n    main()\n  File "/usr/bin/glyphIgo", line 1344, in main\n    returnCode = GlyphIgo(args).execute()\n  File "/usr/bin/glyphIgo", line 1333, in execute\n    returnCode = self.__do_subset()\n  File "/usr/bin/glyphIgo", line 1307, in __do_subset\n    self.__print_char_list(found_char_list)\n  File "/usr/bin/glyphIgo", line 992, in __print_char_list\n    print "\'%s\'\\t%s\\t%s\\t%s" % (escape(c[0]), decCodePoint, hexCodePoint, name)\nUnicodeEncodeError: \'ascii\' codec can\'t encode character u\'\\uf00c\' in position 1: ordinal not in range(128)', '')
				.replace(/^Compressed \d+ to \d+\.\n/gm, '')
				.trim()
			if stdout
				console.log(stdout)
			if stderr
				console.error(stderr)
			# We print warnings and potential errors, but don't fail the whole build
			callback()
		)
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
	.task('minify-service-worker', ['bundle-service-worker'], ->
		gulp.src(BUNDLED_SW)
			.pipe(uglify())
			.pipe(gulp-rename(MINIFIED_SW))
			.pipe(gulp.dest('.'))
	)
	.task('update-index', !->
		index					= fs.readFileSync('index.html', {encoding: 'utf8'})
		critical_css			= fs.readFileSync('css/critical.css', {encoding: 'utf8'}).trim()
		index					= index.replace(/<style>.*?<\/style>/g, "<style>#critical_css</style>")
		files_for_hash_update	= [
			"#DESTINATION/#MINIFIED_CSS"
			"#DESTINATION/favicon.ico"
			"#DESTINATION/#MINIFIED_HTML"
			"#DESTINATION/#MINIFIED_JS"
			"#DESTINATION/#BUNDLED_MANIFEST"
			"#DESTINATION/webcomponents.min.js"
		]
		for file in files_for_hash_update
			hash	= file_hash(file)
			index	= index.replace(new RegExp("#file[^\"]*", 'g'), "#file?#hash")
		fs.writeFileSync('index.html', index)
	)
