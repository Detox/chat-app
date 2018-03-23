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


		state	= @_state_instance
		core	= detox-core.Core(
			detox-core.generate_seed()
			state.get_settings_bootstrap_nodes()
			state.get_settings_ice_servers()
			state.get_settings_packets_per_second()
			state.get_settings_bucket_size()
		)
		chat	= detox-chat.Chat(
			core
			state.get_seed()
			state.get_settings_number_of_introduction_nodes()
			state.get_settings_number_of_intermediate_nodes()
		)
		/**
		 * @param {!Uint8Array} contact_id
		 */
		!function check_and_add_to_online (contact_id)
			secrets_exchange_status	= secrets_exchange_statuses.get(contact_id)
			if secrets_exchange_status.received && secrets_exchange_status.sent
				state.add_online_contact(contact_id)
				nickname	= state.get_nickname()
				if nickname
					chat.nickname(contact_id, nickname)
				for message in state.get_contact_messages_to_be_sent(contact_id)
					send_message(contact_id, message)
		/**
		 * @param {!Uint8Array}	contact_id
		 * @param {!Object}		message
		 */
		!function send_message (contact_id, message)
			date_sent	= chat.text_message(contact_id, message.date_written, message.text)
			if !sent_messages_map.has(contact_id)
				sent_messages_map.set(contact_id, new Map)
			sent_messages_map.get(contact_id).set(date_sent, message.id)
		/**
		 * @param {!Uint8Array} contact_id
		 */
		!function do_reconnect_if_needed (contact_id)
			contact	= state.get_contact(contact_id)
			if !contact
				return
			# Reconnect when there are messages to be sent or contact was never connected
			if !(
				state.get_contact_messages_to_be_sent(contact_id).length &&
				contact.local_secret
			)
				return
			if !reconnects_pending.has(contact_id)
				reconnects_pending.set(contact_id, {trial: 0, timeout: null})
			reconnect_pending	= reconnects_pending.get(contact_id)
			if reconnect_pending.timeout
				return
			++reconnect_pending.trial
			for [reconnection_trial, time_before_next_attempt] in state.get_settings_reconnects_intervals()
				if reconnect_pending.trial <= reconnection_trial
					reconnect_pending.timeout	= timeoutSet(time_before_next_attempt, !->
						reconnect_pending.timeout	= null
						chat.connect_to(contact_id, contact.remote_secret)
					)
					break

		core
			.once('ready', !->
				state.set_online(true)

				if state.get_settings_announce()
					chat.announce()
				for contact in state.get_contacts()
					do_reconnect_if_needed(contact.id)
			)
			.on('connected_nodes_count', (count) !->
				state.set_connected_nodes_count(count)
			)
			.on('aware_of_nodes_count', (count) !->
				state.set_aware_of_nodes_count(count)
			)
			.on('routing_paths_count', (count) !->
				state.set_routing_paths_count(count)
			)
			.on('application_connections_count', (count) !->
				state.set_application_connections_count(count)
			)
		chat
			.once('announced', !->
				state.set_announced(true)
			)
			.on('introduction', (contact_id, secret) ->
				contact	= state.get_contact(contact_id)
				if !contact
					if state.has_contact_request_blocked(contact_id)
						return
					secret_length	= secret.length
					for local_secret in state.get_secrets()
						padded_secret	= new Uint8Array(secret_length)
							..set(local_secret.secret)
						if are_arrays_equal(secret, padded_secret)
							state.add_contact_request(contact_id, local_secret.name)
							csw.functions.notify('Incoming contact request received', 'warning', 'right', 3)
							break
					false
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
			.on('connected', (contact_id) !~>
				if reconnects_pending.has(contact_id)
					reconnect_pending	= reconnects_pending.get(contact_id)
					if reconnect_pending.timeout
						clearTimeout(reconnect_pending.timeout)
					reconnects_pending.delete(contact_id)
				if !state.has_contact(contact_id)
					return
				secrets_exchange_statuses.set(contact_id, {received: false, sent: false})
				local_secret	= detox-chat.generate_secret()
				state.set_contact_local_secret(contact_id, local_secret)
				chat.secret(contact_id, local_secret)
			)
			.on('connection_failed', (contact_id) !~>
				do_reconnect_if_needed(contact_id)
			)
			.on('secret', (contact_id, remote_secret) ->
				contact	= state.get_contact(contact_id)
				# TODO: Check secret if it was used previously (in which case also reject new secret)
				if are_arrays_equal(remote_secret, contact.remote_secret)
					return false
				state.set_contact_remote_secret(contact_id, remote_secret)
				secrets_exchange_statuses.get(contact_id).received	= true
				check_and_add_to_online(contact_id)
				true
			)
			.on('secret_received', (contact_id) !->
				state.del_contact_old_local_secret(contact_id)
				secrets_exchange_statuses.get(contact_id).sent		= true
				check_and_add_to_online(contact_id)
			)
			.on('nickname', (contact_id, nickname) !->
				nickname	= nickname.trimLeft()
				if nickname
					state.set_contact_nickname(contact_id, nickname)
			)
			.on('text_message', (contact_id, date_written, date_sent, text_message) !->
				text_message	= text_message.trim()
				if !text_message
					return
				for old_message in state.get_contact_messages(contact_id) by -1
					if old_message.from
						last_message_received = old_message
						break
				# `date_sent` always increases, `date_written` never decreases
				if last_message_received && (last_message_received.date_sent <= date_sent || last_message_received.date_written < date_written)
					return
				state.add_contact_message(contact_id, true, date_written, date_sent, text_message)
			)
			.on('text_message_received', (contact_id, date_sent) !->
				id	= sent_messages_map.get(contact_id)?.get(date_sent)
				if id
					sent_messages_map.get(contact_id).delete(date_sent)
					state.set_contact_message_sent(contact_id, id, date_sent)
			)
			.on('disconnected', (contact_id) !~>
				secrets_exchange_statuses.delete(contact_id)
				sent_messages_map.delete(contact_id)
				state.del_online_contact(contact_id)

				do_reconnect_if_needed(contact_id)
			)
		state
			.on('contact_added', (new_contact) !~>
				chat.connect_to(new_contact.id, new_contact.remote_secret)
			)
			.on('contact_message_added', (contact_id, message) !->
				if (
					message.from || # Message was received from a friend
					message.date_received || # Message was received by a friend
					!state.has_online_contact(contact_id) # Friend is not currently connected
				)
					do_reconnect_if_needed(contact_id)
					return
				send_message(contact_id, message)
			)
		@_core_instance	= core
		@_chat_instance	= chat
)
