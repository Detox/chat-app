/**
 * @package Detox chat app
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
const bootstrap_node_id		= '3b6a27bcceb6a42d62a3a8d02a6f0d73653215771de243a63ac048a18b59da29'
const bootstrap_ip			= '127.0.0.1'
const bootstrap_port		= 16882
const bootstrap_node_info	=
	node_id	: bootstrap_node_id
	host	: bootstrap_ip
	port	: bootstrap_port
const ice_servers			= [
	{urls: 'stun:stun.l.google.com:19302'}
	{urls: 'stun:global.stun.twilio.com:3478?transport=udp'}
]
const packets_per_second	= 5
Polymer(
	is			: 'detox-chat-app'
	behaviors	: [
		detox-chat-app.behaviors.state
	]
	ready : !->
		Promise.all([
			require(['state', '@detox/chat', '@detox/core'])
			@_state_instance_ready
		]).then ([[detox-state, detox-chat, detox-core]]) !~>
			wait_for	= 2
			!~function ready
				--wait_for
				if !wait_for
					@_connect_to_the_network(detox-state, detox-chat, detox-core)
			detox-chat.ready(ready)
			detox-core.ready(ready)
	_connect_to_the_network : (detox-state, detox-chat, detox-core) !->
		# TODO: For now we are using defaults and hardcoded constants for Chat and Core instances, but in future this will be configurable
		state	= @_state_instance
		core	= detox-core.Core(detox-core.generate_seed(), [bootstrap_node_info], ice_servers, packets_per_second)
			.once('ready', !->
				state.set_network_state(detox-state.State.NETWORK_STATE_ONLINE)
				console.log('ready')

				if state.get_settings_announce_myself()
					chat.announce()
			)
		chat	= detox-chat.Chat(core, state.get_seed())
			.once('announced', !->
				state.set_announcement_state(detox-state.State.ANNOUNCEMENT_STATE_ANNOUNCED)

				console.log('announced')
			)
)
