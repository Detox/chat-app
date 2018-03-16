/**
 * @package Detox chat app
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
Polymer(
	is			: 'detox-chat-app-dialogs'
	behaviors	: [
		detox-chat-app.behaviors.state
	]
	properties	:
		active_contact	:
			type	: Boolean
			value	: false
		messages		: Array
	ready : !->
		Promise.all([
			require(['@detox/utils'])
			@_state_instance_ready
		]).then ([[detox-utils]]) !~>
			state	= @_state_instance
			state
				.on('ui_active_contact_changed', (new_active_contact) !~>
					@active_contact	= true
					@messages		= state.get_contact_messages(new_active_contact).slice() # TODO: slice is a hack until https://github.com/Polymer/polymer/issues/5151 is fixed
					@notifyPath('messages')
				)
				.on('contact_messages_changed', (friend_id) !~>
					active_contact	= state.get_ui_active_contact()
					if active_contact && detox-utils.are_arrays_equal(friend_id, active_contact)
						@messages	= state.get_contact_messages(friend_id).slice() # TODO: slice is a hack until https://github.com/Polymer/polymer/issues/5151 is fixed
						@notifyPath('messages')
				)
				.on('ui_active_contact_changed', (friend_id) !~>
					@$['send-form']querySelector('textarea').value	= ''
				)
	_send : !->
		state			= @_state_instance
		textarea		= @$['send-form']querySelector('textarea')
		text_message	= textarea.value
		textarea.value	= ''
		friend_id		= state.get_ui_active_contact()
		# TODO: Sent date should be updated
		state.add_contact_message(friend_id, false, +(new Date), 0, text_message)
)
