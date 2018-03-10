/**
 * @package Detox chat app
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
requirejs.config(
	baseUrl		: '/node_modules/'
	paths		:
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
	packages	: [
		{
			name		: 'aez.wasm',
			location	: 'aez.wasm',
			main		: 'src/index'
		}
		{
			name		: 'ed25519-to-x25519.wasm',
			location	: 'ed25519-to-x25519.wasm',
			main		: 'src/index'
		}
		{
			name		: 'noise-c.wasm',
			location	: 'noise-c.wasm',
			main		: 'src/index'
		}
		{
			name		: 'supercop.wasm',
			location	: 'supercop.wasm',
			main		: 'src/index'
		}
	]
)

ready = new Promise (resolve) !->
	if window.WebComponents
		resolve()
	else
		window.addEventListener('WebComponentsReady', resolve)
<-! ready.then

#TODO
