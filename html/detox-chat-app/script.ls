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
		ArrayMap					= detox-utils.ArrayMap

		secrets_exchange_statuses	= ArrayMap()

		!function check_and_add_to_online (friend_id)
			secrets_exchange_status	= secrets_exchange_statuses.get(friend_id)
			if secrets_exchange_status.received && secrets_exchange_status.sent
				state.add_online_contact(friend_id)
				nickname	= state.get_nickname()
				if nickname
					chat.nickname(friend_id, nickname)

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
			.on('introduction', (friend_id, secret) !->
				# TODO: Check secret
			)
			.on('connected', (friend_id) !~>
				if !state.has_contact(friend_id)
					state.add_contact(friend_id, detox-utils.base58_encode(friend_id))
				secrets_exchange_statuses.set(friend_id, {received: false, sent: false})
				# TODO: Secret should be stored and expected next time
				chat.secret(friend_id, detox-chat.generate_secret())
			)
			.on('secret', (friend_id, secret) !->
				# TODO: Check secret
				secrets_exchange_statuses.get(friend_id).received	= true
				check_and_add_to_online(friend_id)
			)
			.on('secret_received', (friend_id) !->
				secrets_exchange_statuses.get(friend_id).sent		= true
				check_and_add_to_online(friend_id)
			)
			.on('nickname', (friend_id, nickname) !->
				state.set_contact_nickname(friend_id, nickname)
			)
			.on('text_message', (friend_id, date_written, date_sent, text_message) !->
				# TODO: Check date_written and date_sent
				state.add_contact_message(friend_id, true, date_written, date_sent, text_message)
			)
			.on('text_message_received', (friend_id, date) !->
				# TODO: Track messages that were actually received
			)
			.on('disconnected', (friend_id) !~>
				secrets_exchange_statuses.delete(friend_id)
				state.del_online_contact(friend_id)
			)
		state
			.on('contact_added', (new_contact) !~>
				# TODO: Secrets support
				# TODO: Handle failed connections
				chat.connect_to(new_contact.id, new Uint8Array(0))
			)
			.on('contact_message_added', (friend_id, message) !->
				if message[0] # Message was received
					return
				chat.text_message(friend_id, message[2])
			)
		@_core_instance	= core
		@_chat_instance	= chat
)
