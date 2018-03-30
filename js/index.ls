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
		'@detox/dht'				: 'node_modules/@detox/dht/dist/detox-dht.browser'
		'@detox/transport'			: 'node_modules/@detox/transport/src/index'
		'@detox/utils'				: 'node_modules/@detox/utils/src/index'
		'async-eventer'				: 'node_modules/async-eventer/src/index'
		'autosize'					: 'node_modules/autosize/dist/autosize'
		'fixed-size-multiplexer'	: 'node_modules/fixed-size-multiplexer/src/index'
		'ronion'					: 'node_modules/ronion/dist/ronion.browser'
		'pako'						: 'node_modules/pako/dist/pako'
		'simple-peer'				: 'node_modules/simple-peer/simplepeer.min'
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
requirejs['config'](requirejs_config)
