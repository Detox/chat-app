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
					@messages		= state.get_contact_messages(new_active_contact)
				)
				.on('contact_messages_changed', (public_key) !~>
					if detox-utils.are_arrays_equal(public_key, state.get_ui_active_contact())
						@messages		= state.get_contact_messages(public_key)
				)
)
