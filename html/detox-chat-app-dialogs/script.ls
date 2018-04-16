/**
 * @package Detox chat app
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
([detox-utils, hotkeys-js, behaviors, markdown]) <-! require(['@detox/utils', 'hotkeys-js', 'js/behaviors', 'js/markdown']).then

function node_to_string (node)
	nodes	= node.childNodes
	if nodes.length
		(
			for node in nodes
				node_to_string(node)
		)
			.map (node) ->
				node.trim()
			.filter(Boolean)
			.join(' ')
	else
		node.textContent.trim()

Polymer(
	is			: 'detox-chat-app-dialogs'
	behaviors	: [
		behaviors.state_instance
		Polymer.MutableDataBehavior
	]
	properties	:
		active_contact	:
			type	: Boolean
			value	: false
		contact			: Object
		messages		: Array
		send_ctrl_enter	: Boolean
		text_message	:
			type	: String
			value	: ''
		unread_messages	: Boolean
	created : !->
		@_ctrl_enter_handler	= @_ctrl_enter_handler.bind(@)
		@_enter_handler			= @_enter_handler.bind(@)
	ready : !->
		are_arrays_equal	= detox-utils.are_arrays_equal
		ArrayMap			= detox-utils.ArrayMap

		text_messages		= ArrayMap()
		state				= @state
		@active_contact		= !!state.get_ui_active_contact()
		@send_ctrl_enter	= state.get_settings_send_ctrl_enter()
		@_update_unread_messages()
		state
			.on('contact_message_added', (contact_id, message) !~>
				active_contact	= state.get_ui_active_contact()
				if (
					message.origin == state.MESSAGE_ORIGIN_RECEIVED &&
					!(
						document.hasFocus() &&
						active_contact &&
						are_arrays_equal(contact_id, active_contact)
					)
				)
					contact		= state.get_contact(contact_id)
					tmp_node	= document.createElement('div')
						..innerHTML	= message.text
					text		= node_to_string(tmp_node)
					detox_chat_app.notify(
						contact.nickname
						if text.length > 60 then text.substr(0, 60) + '...' else text
						7
					).then !->
						state.set_ui_active_contact(contact_id)
			)
			.on('contact_messages_changed', (contact_id) !~>
				active_contact	= state.get_ui_active_contact()
				if active_contact && are_arrays_equal(contact_id, active_contact)
					messages_list			= @$['messages-list']
					need_to_update_scroll	= messages_list.scrollHeight - messages_list.offsetHeight == messages_list.scrollTop
					(@messages)				<~! state.get_contact_messages(contact_id).then
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
			.on('contacts_with_unread_messages_changed', !~>
				@_update_unread_messages()
			)
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
				(@messages)		<~! state.get_contact_messages(new_active_contact).then
				@notifyPath('messages')
				# Force synchronous messages render in order to be sure scrolling works properly
				@$['messages-list-template'].render()
				messages_list			= @$['messages-list']
				messages_list.scrollTop	= messages_list.scrollHeight - messages_list.offsetHeight
				@_update_unread_messages()
			)
			.on('settings_send_ctrl_enter_changed', (@send_ctrl_enter) !~>)
	attached : !->
		hotkeys-js('Ctrl+Enter', @_ctrl_enter_handler)
		hotkeys-js('Enter', @_enter_handler)
	detached : !->
		hotkeys-js.unbind('Ctrl+Enter', @_ctrl_enter_handler)
		hotkeys-js.unbind('Enter', @_enter_handler)
	_ctrl_enter_handler : (e) !->
		if e.composedPath()[0] == @$.textarea
			@_send()
			e.preventDefault()
	_enter_handler : (e) !->
		if e.composedPath()[0] == @$.textarea && !@send_ctrl_enter
			@_send()
			e.preventDefault()
	_update_unread_messages : !->
		state				= @state
		@unread_messages	= !!(
			state.get_contacts_with_unread_messages()
				.filter (contact) ->
					contact != state.get_ui_active_contact()
				.length
		)
	_show_sidebar : !->
		@state.set_ui_sidebar_shown(true)
	_send_placeholder : (send_ctrl_enter) ->
		'Type you message here, Markdown (GFM) supported!\n' + (
			if send_ctrl_enter
				'Enter for new line, Ctrl+Enter for sending'
			else
				'Shift+Enter for new line, Enter for sending'
		)
	_send : !->
		text_message	= @text_message.trim()
		if !text_message
			return
		@text_message	= ''
		state			= @state
		contact_id		= state.get_ui_active_contact()
		state.add_contact_message(contact_id, state.MESSAGE_ORIGIN_SENT, +(new Date), 0, text_message)
	_markdown_renderer : (markdown_text) ->
		markdown(markdown_text)
	_format_date : (date) ->
		if !date
			'Not yet'
		# If message older than 24 hours, we'll use full date and time, otherwise time only
		else if date - (new Date) < 24 * 60 * 60 * 1000
			(new Date(date)).toLocaleTimeString()
		else
			(new Date(date)).toLocaleString()
	_message_origin : (message) ->
		switch message.origin
			case @state.MESSAGE_ORIGIN_SENT
				'sent'
			case @state.MESSAGE_ORIGIN_RECEIVED
				'received'
			case @state.MESSAGE_ORIGIN_SERVICE
				'service'
	_help_insecure : !->
		content	= """
			<p>Don't get this message wrong, Detox Chat in particular and Detox network in general are built with security and anonymity in mind from the beginning.</p>
			<p>However, until independent security audit is conducted and proved that the application is indeed secure, you shouldn't trust it critical data.</p>
		"""
		csw.functions.simple_modal(content)
	_not_implemented : !->
		csw.functions.alert("Yeah, I'd like to use this too, but it is not yet implemented, get back in future updates")
)
