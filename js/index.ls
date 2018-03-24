/**
 * @package Detox chat app
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
const DEBUG	= 'debug' in location.search.substr(1).split('&') || sessionStorage['debug']

requirejs_config	=
	'baseUrl'	: '/node_modules/'
	'paths'		:
		'@detox/base-x'				: '@detox/base-x/index'
		'@detox/chat'				: '@detox/chat/src/index'
		'@detox/core'				: '@detox/core/src/index'
		'@detox/crypto'				: '@detox/crypto/src/index'
		'@detox/dht'				: '@detox/dht/dist/detox-dht.browser'
		'@detox/transport'			: '@detox/transport/src/index'
		'@detox/utils'				: '@detox/utils/src/index'
		'async-eventer'				: 'async-eventer/src/index'
		'fixed-size-multiplexer'	: 'fixed-size-multiplexer/src/index'
		'ronion'					: 'ronion/dist/ronion.browser'
		'pako'						: 'pako/dist/pako'
		'state'						: '/js/state'
	'packages'	: [
		{
			'name'		: 'aez.wasm',
			'location'	: 'aez.wasm',
			'main'		: 'src/index'
		}
		{
			'name'		: 'ed25519-to-x25519.wasm',
			'location'	: 'ed25519-to-x25519.wasm',
			'main'		: 'src/index'
		}
		{
			'name'		: 'noise-c.wasm',
			'location'	: 'noise-c.wasm',
			'main'		: 'src/index'
		}
		{
			'name'		: 'supercop.wasm',
			'location'	: 'supercop.wasm',
			'main'		: 'src/index'
		}
	]
if !DEBUG
	let paths = requirejs_config['paths']
		for pkg, main of paths
			if main.substr(0, 1) != '/'
				paths[pkg]	+= '.min'
	let packages = requirejs_config['packages']
		for pkg in packages
			pkg['main']	+= '.min'

requirejs['config'](requirejs_config)

ready = new Promise (resolve) !->
	if window['WebComponents']?['ready']
		resolve()
	else
		window.addEventListener('WebComponentsReady', resolve)
<-! ready.then

document.head.insertAdjacentHTML('beforeend', '<link rel="import" href="html/index.html">')
