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
	created : !->
		Promise.all([
			require(['@detox/chat', '@detox/core', '@detox/utils'])
			@_state_instance_ready
		]).then ([[detox-chat, detox-core, detox-utils]]) !~>
			<~! detox-chat.ready
			<~! detox-core.ready
			@_connect_to_the_network(detox-chat, detox-core, detox-utils)
	_connect_to_the_network : (detox-chat, detox-core, detox-utils) !->
		# TODO: For now we are using defaults and hardcoded constants for Chat and Core instances, but in future this will be configurable
		state	= @_state_instance
		core	= detox-core.Core(detox-core.generate_seed(), [bootstrap_node_info], ice_servers, packets_per_second)
			.once('ready', !->
				state.set_online(true)

				if state.get_settings_announce()
					chat.announce()
			)
		chat	= detox-chat.Chat(core, state.get_seed())
			.once('announced', !->
				state.set_announced(true)
			)
			.on('secret', (friend_id, secret) !->
				# TODO
			)
			.on('secret_received', (friend_id) !->
				# TODO
			)
			.on('connected', (friend_id) !~>
				# TODO: Update connection and current online statuses
				state.add_online_contact(friend_id)
			)
			.on('disconnected', (friend_id) !~>
				state.del_online_contact(friend_id)
			)
		state
			.on('contact_added', (new_contact) !~>
				# TODO: Secrets support
				chat.connect_to(new_contact[0], new Uint8Array(0))
			)
		@_core_instance	= core
		@_chat_instance	= chat
)
