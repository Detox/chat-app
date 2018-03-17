/**
 * @package Detox chat app
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
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
			if !@_state_instance.get_settings_online()
				# We're working offline
				return
			<~! detox-chat.ready
			<~! detox-core.ready
			@_connect_to_the_network(detox-chat, detox-core, detox-utils)
	_connect_to_the_network : (detox-chat, detox-core, detox-utils) !->
		ArrayMap					= detox-utils.ArrayMap

		secrets_exchange_statuses	= ArrayMap()
		sent_messages_map			= ArrayMap()

		!function check_and_add_to_online (friend_id)
			secrets_exchange_status	= secrets_exchange_statuses.get(friend_id)
			if secrets_exchange_status.received && secrets_exchange_status.sent
				state.add_online_contact(friend_id)
				nickname	= state.get_nickname()
				if nickname
					chat.nickname(friend_id, nickname)
				# TODO: In addition to this we need to scan for contacts with such messages and actively try to connect to them
				for message in state.get_contact_messages_to_be_sent(friend_id)
					send_message(friend_id, message)

		!function send_message (friend_id, message)
			date_sent	= chat.text_message(friend_id, message.date_written, message.text)
			if !sent_messages_map.has(friend_id)
				sent_messages_map.set(friend_id, new Map)
			sent_messages_map.get(friend_id).set(date_sent, message.id)

		# TODO: For now we are using defaults and hardcoded constants for Chat and Core instances, but in future this will be configurable
		state	= @_state_instance
		core	= detox-core.Core(
			detox-core.generate_seed()
			state.get_settings_bootstrap_nodes()
			state.get_settings_ice_servers()
			state.get_settings_packets_per_second()
			state.get_settings_bucket_size()
		)
			.once('ready', !->
				state.set_online(true)

				if state.get_settings_announce()
					chat.announce()
			)
		chat	= detox-chat.Chat(
			core
			state.get_seed()
			state.get_settings_number_of_introduction_nodes()
			state.get_settings_number_of_intermediate_nodes()
		)
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
			.on('connection_failed', (friend_id) !~>
				# TODO: Reconnect
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
			.on('text_message_received', (friend_id, date_sent) !->
				id	= sent_messages_map.get(friend_id)?.get(date_sent)
				if id
					sent_messages_map.get(friend_id).delete(date_sent)
					state.set_contact_message_sent(friend_id, id, date_sent)
			)
			.on('disconnected', (friend_id) !~>
				secrets_exchange_statuses.delete(friend_id)
				sent_messages_map.delete(friend_id)
				state.del_online_contact(friend_id)
			)
		state
			.on('contact_added', (new_contact) !~>
				# TODO: Secrets support
				# TODO: Handle failed connections
				chat.connect_to(new_contact.id, new Uint8Array(0))
			)
			.on('contact_message_added', (friend_id, message) !->
				if (
					message.from || # Message was received from a friend
					message.date_received || # Message was received by a friend
					!state.has_online_contact(friend_id) # Friend is not currently connected
				)
					return
				send_message(friend_id, message)
			)
		@_core_instance	= core
		@_chat_instance	= chat
)
