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

const AUDIO_REGEXP		= /'audio\/[^']+\.mp3'/g
const FONTS_REGEXP		= /url\(.+?\.woff2.+?\)/g
const IMAGES_REGEXP		= /url\(\.\.\/img\/.+?\)/g
const SCRIPTS_REGEXP	= /<script>[^]+?<\/script>\n*/g

const BLACKLISTED_FONTS	= [
	'fa-regular-400.woff2'
	'fa-brands-400.woff2'
]

requirejs_config	=
	'baseUrl'	: '.'
	'paths'		:
		'@detox/base-x'				: 'node_modules/@detox/base-x/index.min'
		'@detox/chat'				: 'node_modules/@detox/chat/src/index.min'
		'@detox/core'				: 'node_modules/@detox/core/src/index.min'
		'@detox/crypto'				: 'node_modules/@detox/crypto/src/index.min'
		'@detox/dht'				: 'node_modules/@detox/dht/src/index.min'
		'@detox/routing'			: 'node_modules/@detox/routing/src/index.min'
		'@detox/simple-peer'		: 'node_modules/@detox/simple-peer/simplepeer.min'
		'@detox/transport'			: 'node_modules/@detox/transport/src/index.min'
		'@detox/utils'				: 'node_modules/@detox/utils/src/index.min'
		'array-map-set'				: 'node_modules/array-map-set/src/index.min'
		'async-eventer'				: 'node_modules/async-eventer/src/index.min'
		'es-dht'					: 'node_modules/es-dht/src/index.min'
		'autosize'					: 'node_modules/autosize/dist/autosize.min'
		'fixed-size-multiplexer'	: 'node_modules/fixed-size-multiplexer/src/index.min'
		'k-bucket-sync'				: 'node_modules/k-bucket-sync/src/index.min'
		'merkle-tree-binary'		: 'node_modules/merkle-tree-binary/src/index.min'
		'hotkeys-js'				: 'node_modules/hotkeys-js/dist/hotkeys.min'
		'marked'					: 'node_modules/marked/marked.min'
		'pako'						: 'node_modules/pako/dist/pako.min'
		'ronion'					: 'node_modules/ronion/src/index.min'
		'random-bytes-numbers'		: 'node_modules/random-bytes-numbers/src/index.min'
		'swipe-listener'			: 'node_modules/swipe-listener/dist/swipe-listener.min'
	'packages'	: [
		{
			'name'		: 'aez.wasm',
			'location'	: 'node_modules/aez.wasm',
			'main'		: 'src/index.min'
		}
		{
			'name'		: 'blake2.wasm',
			'location'	: 'node_modules/blake2.wasm',
			'main'		: 'src/index.min'
		}
		{
			'name'		: 'ed25519-to-x25519.wasm',
			'location'	: 'node_modules/ed25519-to-x25519.wasm',
			'main'		: 'src/index.min'
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
		del(['dist/style.css', 'dist/index.html', 'dist/script.js', 'sw.js'])
	)
	.task('bundle-css', !->
		css		= fs.readFileSync('css/style.css', {encoding: 'utf8'})
		images	= css.match(IMAGES_REGEXP)
		for image in images
			image_path	= image.substring(7, image.length - 1)
			base_name	= image_path.split('/').pop()
			hash		= file_hash(image_path)
			css			= css.replace(image, "url(dist/#base_name?#hash)")
			fs.copyFileSync(image_path, "dist/#base_name")
		fs.writeFileSync('dist/style.css', css)
	)
	.task('bundle-html', ['generate-html'], !->
		html	= fs.readFileSync('dist/index.html', {encoding: 'utf8'})
		# Hack: we know for sure that these files fonts will not be used, so lets remove unused fonts from stylesheet entirely
		html	= html.replace(new RegExp('@font-face[^}]+(' + BLACKLISTED_FONTS.join('|') + ')[^}]+}', 'g'), '')
		fonts	= html.match(FONTS_REGEXP)
		for font in fonts
			font_path	= font.substring(8, font.length - 2).split('?')[0]
			base_name	= font_path.split('/').pop()
			hash		= file_hash(font_path)
			html		= html.replace(font, "url(#base_name?#hash)")
			fs.copyFileSync(font_path, "dist/#base_name")
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
		js		= html.match(SCRIPTS_REGEXP)
			.map (string) ->
				string	= string.trim()
				string.substring(8, string.length - 9) # Remove script tag
			.join('')
		html	= html
			# Useless (in our case) arguments
			.replace(/assetpath=".+?"/g, '')
			# These 2 files are referenced, but do not actually exist (because Polymer uses crappy practices for its packages)
			.replace('<link rel="import" href="../node_modules/@polymer/shadycss/apply-shim.html">', '')
			.replace('<link rel="import" href="../node_modules/@polymer/shadycss/custom-style-interface.html">', '')
			# Remove all <script> tags, we'll have them included separately
			.replace(SCRIPTS_REGEXP, '')
		fs.writeFileSync('dist/index.html', html)
		fs.writeFileSync('dist/script.js', js)
	)
	.task('bundle-js', ['bundle-html'], ->
		config	= Object.assign({
			name					: 'dist/script.js'
			optimize				: 'none'
			onBuildRead				: (, , contents) ->
				# Hack: Workaround for https://github.com/google/closure-compiler/issues/2953
				contents.replace(/define\("([^"]+)".split\(" "\)/, (, dependencies) ->
					'define(' + JSON.stringify(dependencies.split(' '))
				)
			wrap					:
				startFile	: ['js/a.async-styles.js', 'js/a.require.js']
		}, requirejs_config)
		gulp.src('dist/script.js')
			.pipe(gulp-requirejs-optimize(config))
			.pipe(gulp.dest('dist'))
	)
	.task('bundle-service-worker', ['generate-service-worker'], !->
		fs.renameSync('dist/sw.js', 'sw.js')
		sw	= fs.readFileSync('sw.js', {encoding: 'utf8'})
		# TODO: Hack, should be possible to remove in future when https://github.com/GoogleChrome/workbox/pull/1403 lands in stable version
		sw	= sw
			.replace(/importScripts\("/, "$&dist/")
			.replace(/modulePathPrefix:\s*?"/, "$&dist/")
		fs.writeFileSync('sw.js', sw)
	)
	.task('clean', ->
		del('dist/*')
	)
	.task('copy-audio', ['bundle-js'], !->
		js		= fs.readFileSync('dist/script.js', {encoding: 'utf8'})
		audios	= js.match(AUDIO_REGEXP)
		for audio in audios
			audio_path	= audio.substring(1, audio.length - 1)
			base_name	= audio_path.split('/').pop()
			hash		= file_hash(audio_path)
			js			= js.replace(audio, "\"dist/#base_name?#hash\"")
			fs.copyFileSync(audio_path, "dist/#base_name")
		fs.writeFileSync('dist/script.js', js)
	)
	.task('copy-favicon', !->
		fs.copyFileSync('favicon.ico', "dist/favicon.ico")
	)
	.task('copy-js', !->
		webcomponents	= fs.readFileSync('node_modules/@webcomponents/webcomponentsjs/webcomponents-hi-sd-ce.js', {encoding: 'utf8'})
		fs.writeFileSync("dist/webcomponents.min.js", minify_js(webcomponents))
	)
	.task('copy-manifest', !->
		manifest			= JSON.parse(fs.readFileSync('manifest.json', {encoding: 'utf8'}))
		manifest.start_url	= '../' + manifest.start_url
		for icon in manifest.icons
			base_name	= icon.src.split('/').pop()
			hash		= file_hash(icon.src)
			fs.copyFileSync(icon.src, "dist/#base_name")
			icon.src	= "#base_name?#hash"
		fs.writeFileSync('dist/manifest.json', JSON.stringify(manifest))
	)
	.task('copy-wasm', ['bundle-js'], !->
		js	= fs.readFileSync('dist/script.js', {encoding: 'utf8'})
		for {name, location, main} in requirejs_config.packages
			if name.endsWith('.wasm')
				hash	= file_hash("#location/src/#name")
				# This is a hack, but it works for now
				js		= js.replace("=\"#name\"", "=\"#name?#hash\"")
				fs.copyFileSync("#location/src/#name", "dist/#name")
		fs.writeFileSync('dist/script.js', js)
	)
	.task('default', (callback) !->
		run-sequence('clean', 'main-build', 'bundle-clean', 'minify-service-worker', 'bundle-clean', 'update-index', callback)
	)
	.task('generate-html', (callback) !->
		command		= "node_modules/.bin/polymer-bundler --strip-comments --rewrite-urls-in-templates --inline-css --inline-scripts --out-html dist/index.html html/index.html"
		exec(command, (error, stdout, stderr) !->
			if stdout
				console.log(stdout)
			if stderr
				console.error(stderr)
			callback(error)
		)
	)
	.task('generate-service-worker', ->
		workbox-build.generateSW(
			cacheId						: 'detox-chat-app'
			clientsClaim				: true
			globDirectory				: '.'
			globPatterns				: [
				"dist/*"
				'index.html'
			]
			ignoreUrlParametersMatching	: [/./]
			importWorkboxFrom			: 'local'
			skipWaiting					: true
			swDest						: "dist/sw.js"
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
	.task('main-build', ['copy-audio', 'copy-favicon', 'copy-js', 'copy-manifest', 'copy-wasm', 'minify-css', 'minify-html', 'minify-font', 'minify-js'])
	.task('minify-css', ['bundle-css'], !->
		css	= fs.readFileSync('dist/style.css', {encoding: 'utf8'})
		fs.writeFileSync('dist/style.min.css', minify_css(css))
	)
	.task('minify-font', ['bundle-html'], (callback) !->
		font	= __dirname + '/dist/fa-solid-900.woff2'
		css		= __dirname + '/dist/index.html'
		command	= "docker run --rm -v #font:/font.woff2 -v #css:/style.css nazarpc/subset-font"
		exec(command, (error, stdout, stderr) !->
			# We need to update hash for this font, since file contents have changed
			html	= fs.readFileSync('dist/index.html', {encoding: 'utf8'})
			r		= new RegExp("fa-solid-900.woff2\\?\\w+")
			hash	= file_hash(font)
			html	= html
				.replace(r, "fa-solid-900.woff2?#hash")
			fs.writeFileSync('dist/index.html', html)
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
	.task('minify-html', ['bundle-html', 'minify-font'], ->
		gulp.src('dist/index.html')
			.pipe(gulp-htmlmin(
				decodeEntities	: true
				minifyCSS		: minify_css
				removeComments	: true
			))
			.pipe(gulp-rename('index.min.html'))
			.pipe(gulp.dest('dist'))
	)
	.task('minify-js', ['bundle-js', 'copy-wasm'], ->
		# First couple of manual optimizations
		js	= fs.readFileSync('dist/script.js', {encoding: 'utf8'})
		js	= js
			.replace("typeof requirejs === 'function'", 'false')
			.replace(/"function"===?typeof define&&define.amd/g, 'true')
		fs.writeFileSync('dist/script.js', js)
		gulp.src('dist/script.js')
			.pipe(uglify())
			.pipe(gulp-rename('script.min.js'))
			.pipe(gulp.dest('dist'))
	)
	.task('minify-service-worker', ['bundle-service-worker'], ->
		gulp.src('sw.js')
			.pipe(uglify())
			.pipe(gulp-rename('sw.min.js'))
			.pipe(gulp.dest('.'))
	)
	.task('update-index', !->
		index					= fs.readFileSync('index.html', {encoding: 'utf8'})
		critical_css			= fs.readFileSync('css/critical.css', {encoding: 'utf8'}).trim()
		index					= index.replace(/<style>.*?<\/style>/g, "<style>#critical_css</style>")
		files_for_hash_update	= [
			'dist/style.min.css'
			'dist/favicon.ico'
			'dist/index.min.html'
			'dist/script.min.js'
			'dist/manifest.json'
			'dist/webcomponents.min.js'
		]
		for file in files_for_hash_update
			hash	= file_hash(file)
			index	= index.replace(new RegExp("#file[^\"]*", 'g'), "#file?#hash")
		fs.writeFileSync('index.html', index)
	)
