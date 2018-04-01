/**
 * @package Detox chat app
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
([behaviors]) <-! require(['js/behaviors']).then
Polymer(
	is			: 'detox-chat-app-dialogs'
	behaviors	: [
		behaviors.state
		Polymer.MutableDataBehavior
	]
	properties	:
		active_contact	:
			type	: Boolean
			value	: false
		contact			: Object
		messages		: Array
		text_message	:
			type	: String
			value	: ''
	ready : !->
		Promise.all([
			require(['@detox/utils'])
			@_state_instance_ready
		]).then ([[detox-utils]]) !~>
			are_arrays_equal	= detox-utils.are_arrays_equal
			ArrayMap			= detox-utils.ArrayMap

			text_messages		= ArrayMap()
			state				= @_state_instance
			state
				.on('ui_active_contact_changed', (new_active_contact, old_active_contact) !~>
					text_message	= @text_message.trim()
					if text_message && old_active_contact
						text_messages.set(old_active_contact, text_message)
						@text_message	= ''
					if new_active_contact && text_messages.has(new_active_contact)
						@text_message	= text_messages.get(new_active_contact)
						text_messages.delete(new_active_contact)
					if !new_active_contact
						@active_contact	= false
						@contact		= {}
						@messages		= []
						return
					@active_contact	= true
					@contact		= state.get_contact(new_active_contact)
					@messages		= state.get_contact_messages(new_active_contact)
					@notifyPath('messages')
					# Force synchronous messages render in order to be sure scrolling works properly
					@$['messages-list-template'].render()
					messages_list			= @$['messages-list']
					messages_list.scrollTop	= messages_list.scrollHeight - messages_list.offsetHeight
				)
				.on('contact_messages_changed', (contact_id) !~>
					active_contact	= state.get_ui_active_contact()
					if active_contact && are_arrays_equal(contact_id, active_contact)
						messages_list			= @$['messages-list']
						need_to_update_scroll	= messages_list.scrollHeight - messages_list.offsetHeight == messages_list.scrollTop
						@messages				= state.get_contact_messages(contact_id)
						@notifyPath('messages')
						if need_to_update_scroll
							# Force synchronous messages render in order to be sure scrolling works properly
							@$['messages-list-template'].render()
							messages_list.scrollTop	= messages_list.scrollHeight - messages_list.offsetHeight
				)
				.on('contact_changed', (new_contact) !~>
					if @contact?id && are_arrays_equal(@contact.id, new_contact.id)
						@contact	= new_contact
				)
				.on('contact_deleted', (old_contact) !~>
					text_messages.delete(old_contact.id)
				)
	_send : !->
		text_message	= @text_message.trim()
		if !text_message
			return
		@text_message	= ''
		state			= @_state_instance
		contact_id		= state.get_ui_active_contact()
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
