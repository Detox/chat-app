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
		are_arrays_equal			= detox-utils.are_arrays_equal
		timeoutSet					= detox-utils.timeoutSet
		ArrayMap					= detox-utils.ArrayMap

		secrets_exchange_statuses	= ArrayMap()
		sent_messages_map			= ArrayMap()
		reconnects_pending			= ArrayMap()
		/**
		 * @param {!Uint8Array} friend_id
		 */
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
		/**
		 * @param {!Uint8Array}	friend_id
		 * @param {!Object}		message
		 */
		!function send_message (friend_id, message)
			date_sent	= chat.text_message(friend_id, message.date_written, message.text)
			if !sent_messages_map.has(friend_id)
				sent_messages_map.set(friend_id, new Map)
			sent_messages_map.get(friend_id).set(date_sent, message.id)
		/**
		 * @param {!Uint8Array} friend_id
		 */
		!function do_reconnect_if_needed (friend_id)
			if !state.get_contact_messages_to_be_sent(friend_id).length # TODO: Or secrets were not exchanged (never connected)
				return
			if !reconnects_pending.has(friend_id)
				reconnects_pending.set(friend_id, {trial: 0, timeout: null})
			reconnect_pending	= reconnects_pending.get(friend_id)
			if reconnect_pending.timeout
				return
			++reconnect_pending.trial
			for [reconnection_trial, time_before_next_attempt] in state.get_settings_reconnects_intervals()
				if reconnect_pending.trial <= reconnection_trial
					reconnect_pending.timeout	= timeoutSet(time_before_next_attempt, !->
						reconnect_pending.timeout	= null
						# TODO: Secrets support
						chat.connect_to(friend_id, new Uint8Array(0))
					)
					break

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
			.on('introduction', (friend_id, secret) ->
				contact	= state.get_contact(friend_id)
				if !contact
					# TODO: Check global secrets and show friendship request if it is the same as some of them, also don't connect immediately (return `false` instead of `true`)
					true
				else if (
					# We've added contact, but never connected to it, blindly accept connection this time
					!contact.local_secret ||
					# Known contact, check if secret is correct
					are_arrays_equal(secret, contact.local_secret) ||
					# There is a chance that old secret was used if updated secret didn't reach a friend
					(contact.old_local_contact && are_arrays_equal(secret, contact.old_local_secret))
				)
					true
				else
					# TODO: Notify user that friend might have been compromised, since wrong secret was used!
					false
			)
			.on('connected', (friend_id) !~>
				if reconnects_pending.has(friend_id)
					reconnect_pending	= reconnects_pending.get(friend_id)
					if reconnect_pending.timeout
						clearTimeout(reconnect_pending.timeout)
					reconnects_pending.delete(friend_id)
				if !state.has_contact(friend_id)
					return
				secrets_exchange_statuses.set(friend_id, {received: false, sent: false})
				local_secret	= detox-chat.generate_secret()
				state.set_contact_local_secret(friend_id, local_secret)
				chat.secret(friend_id, local_secret)
			)
			.on('connection_failed', (friend_id) !~>
				do_reconnect_if_needed(friend_id)
			)
			.on('secret', (friend_id, remote_secret) ->
				contact	= state.get_contact(friend_id)
				# TODO: Check secret if it was used previously (in which case also reject new secret)
				if are_arrays_equal(remote_secret, contact.remote_secret)
					return false
				state.set_contact_remote_secret(friend_id, remote_secret)
				secrets_exchange_statuses.get(friend_id).received	= true
				check_and_add_to_online(friend_id)
				true
			)
			.on('secret_received', (friend_id) !->
				state.del_contact_old_local_secret(friend_id)
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

				do_reconnect_if_needed(friend_id)
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
					do_reconnect_if_needed(friend_id)
					return
				send_message(friend_id, message)
			)
		@_core_instance	= core
		@_chat_instance	= chat
)
