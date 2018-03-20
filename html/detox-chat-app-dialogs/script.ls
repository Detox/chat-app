/**
 * @package Detox chat app
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
Polymer(
	is			: 'detox-chat-app-dialogs'
	behaviors	: [
		detox-chat-app.behaviors.state
		Polymer.MutableDataBehavior
	]
	properties	:
		active_contact	:
			type	: Boolean
			value	: false
		contact			: Object
		messages		: Array
	ready : !->
		Promise.all([
			require(['@detox/utils'])
			@_state_instance_ready
		]).then ([[detox-utils]]) !~>
			are_arrays_equal	= detox-utils.are_arrays_equal

			state				= @_state_instance
			state
				.on('ui_active_contact_changed', (new_active_contact) !~>
					if !new_active_contact
						@active_contact	= false
						@contact		= {}
						@messages		= []
						return
					@active_contact	= true
					@contact		= state.get_contact(new_active_contact)
					@messages		= state.get_contact_messages(new_active_contact)
					@notifyPath('messages')
					@$['send-form']querySelector('textarea').value	= '' # TODO: Same on per-contact basis instead of erasing
				)
				.on('contact_messages_changed', (contact_id) !~>
					active_contact	= state.get_ui_active_contact()
					if active_contact && are_arrays_equal(contact_id, active_contact)
						@messages	= state.get_contact_messages(contact_id)
						@notifyPath('messages')
				)
				.on('contact_changed', (new_contact) !~>
					if @contact && are_arrays_equal(@contact.id, new_contact.id)
						@contact	= new_contact
				)
	_send : !->
		state			= @_state_instance
		textarea		= @$['send-form']querySelector('textarea')
		text_message	= textarea.value
		text_message	= text_message.trim()
		if !text_message
			return
		textarea.value	= ''
		contact_id		= state.get_ui_active_contact()
		# TODO: Sent date should be updated
		state.add_contact_message(contact_id, false, +(new Date), 0, text_message)
	_format_date : (date) ->
		if !date
			return 'Not yet'
		# If message older than 24 hours, we'll use full date and time, otherwise time only
		if date - (new Date) < 24 * 60 * 60 * 1000
			(new Date(date)).toLocaleTimeString()
		else
			(new Date(date)).toLocaleString()
)
