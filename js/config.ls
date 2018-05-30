/**
 * @package Detox chat app
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
requirejs_config	=
	'baseUrl'	: '.'
	'paths'		:
		'@detox/base-x'				: 'node_modules/@detox/base-x/index'
		'@detox/chat'				: 'node_modules/@detox/chat/src/index'
		'@detox/core'				: 'node_modules/@detox/core/src/index'
		'@detox/crypto'				: 'node_modules/@detox/crypto/src/index'
		'@detox/dht'				: 'node_modules/@detox/dht/src/index'
		'@detox/routing'			: 'node_modules/@detox/routing/src/index'
		'@detox/simple-peer'		: 'node_modules/@detox/simple-peer/simplepeer.min'
		'@detox/transport'			: 'node_modules/@detox/transport/src/index'
		'@detox/utils'				: 'node_modules/@detox/utils/src/index'
		'array-map-set'				: 'node_modules/array-map-set/src/index'
		'async-eventer'				: 'node_modules/async-eventer/src/index'
		'es-dht'					: 'node_modules/es-dht/src/index'
		'autosize'					: 'node_modules/autosize/dist/autosize'
		'fixed-size-multiplexer'	: 'node_modules/fixed-size-multiplexer/src/index'
		'k-bucket-sync'				: 'node_modules/k-bucket-sync/src/index'
		'merkle-tree-binary'		: 'node_modules/merkle-tree-binary/src/index'
		'hotkeys-js'				: 'node_modules/hotkeys-js/dist/hotkeys'
		'marked'					: 'node_modules/marked/marked.min'
		'pako'						: 'node_modules/pako/dist/pako'
		'random-bytes-numbers'		: 'node_modules/random-bytes-numbers/src/index'
		'ronion'					: 'node_modules/ronion/src/index'
		'swipe-listener'			: 'node_modules/swipe-listener/dist/swipe-listener'
	'packages'	: [
		{
			'name'		: 'aez.wasm'
			'location'	: 'node_modules/aez.wasm'
			'main'		: 'src/index'
		}
		{
			'name'		: 'blake2.wasm',
			'location'	: 'node_modules/blake2.wasm',
			'main'		: 'src/index'
		}
		{
			'name'		: 'ed25519-to-x25519.wasm'
			'location'	: 'node_modules/ed25519-to-x25519.wasm'
			'main'		: 'src/index'
		}
		{
			'name'		: 'noise-c.wasm'
			'location'	: 'node_modules/noise-c.wasm'
			'main'		: 'src/index'
		}
		{
			'name'		: 'supercop.wasm'
			'location'	: 'node_modules/supercop.wasm'
			'main'		: 'src/index'
		}
	]
requirejs['config'](requirejs_config)
