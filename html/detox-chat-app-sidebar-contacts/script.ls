/**
 * @package Detox chat app
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
([detox-chat, detox-crypto, detox-utils, behaviors]) <-! require(['@detox/chat', '@detox/crypto', '@detox/utils', 'js/behaviors']).then

Polymer(
	is			: 'detox-chat-app-sidebar-contacts'
	behaviors	: [
		behaviors.experience_level
		behaviors.help
		behaviors.state_instance
	]
	properties	:
		add_contact						:
			type	: Boolean
			value	: false
		contacts						:
			type	: Array
			value	: []
		contacts_requests				:
			type	: Array
			value	: []
		contacts_with_pending_messages	: Object
		contacts_with_unread_messages	: Object
		new_contact_id					:
			type	: String
			value	: ''
		new_contact_name				:
			type	: String
			value	: ''
		online_contacts					:
			type	: Object
		ui_active_contact				:
			type	: Object
	ready : !->
		ArraySet	= detox-utils.ArraySet

		state							= @state
		@contacts						= state.get_contacts()
		@online_contacts				= ArraySet(state.get_online_contacts())
		@contacts_requests				= state.get_contacts_requests()
		@contacts_with_pending_messages	= ArraySet(state.get_contacts_with_pending_messages())
		@contacts_with_unread_messages	= ArraySet(state.get_contacts_with_unread_messages())
		@ui_active_contact				= ArraySet([state.get_ui_active_contact() || new Uint8Array(0)])
		state
			.on('contacts_changed', !~>
				# TODO: Sort contacts
				@contacts	= state.get_contacts()
			)
			.on('online_contacts_changed', !~>
				@online_contacts	= ArraySet(state.get_online_contacts())
			)
			.on('contact_request_added', !~>
				detox_chat_app.notify_warning('Incoming contact request received', 3)
			)
			.on('contacts_requests_changed', !~>
				# TODO: Sort contacts
				contacts_requests	= state.get_contacts_requests()
				@contacts_requests	= contacts_requests
			)
			.on('contacts_with_pending_messages_changed', !~>
				@contacts_with_pending_messages	= ArraySet(state.get_contacts_with_pending_messages())
			)
			.on('contacts_with_unread_messages_changed', !~>
				@contacts_with_unread_messages	= ArraySet(state.get_contacts_with_unread_messages())
			)
			.on('ui_active_contact_changed', !~>
				@ui_active_contact	= ArraySet([state.get_ui_active_contact() || new Uint8Array(0)])
			)

		protocol	= 'web+detoxchat'
		# Not present on non-secure origins
		if navigator.registerProtocolHandler
			# Register protocol handler so that we can add contacts easier
			current_location	= location.href.split('?')[0]
			navigator.registerProtocolHandler(protocol, "#current_location?contact=%s", 'Detox Chat')
		if location.search
			url		= new URL(location.href)
			contact	= url.searchParams.get('contact')
			if contact && contact.startsWith("#protocol:")
				contact_splitted	= contact.substr(protocol.length + 1).split('+')
				@add_contact		= true
				@new_contact_id		= contact_splitted[0]
				@new_contact_name	= decodeURIComponent(contact_splitted.slice(1).join(' '))
				detox_chat_app.notify_success('Contact addition form is filled, confirm if you want to proceed', 5)

	_hide_header : (list, add_contact) ->
		!list.length || add_contact
	_add_contact : !->
		@add_contact	= true
	_add_contact_confirm : !->
		<~! detox-chat.ready

		try
			[public_key, remote_secret]	= detox-chat.id_decode(@new_contact_id)
			own_public_key				= detox-crypto.create_keypair(@state.get_seed()).ed25519.public
			if detox-utils.are_arrays_equal(public_key, own_public_key)
				detox_chat_app.notify_error('Adding yourself to contacts is not supported', 3)
				return
			existing_contact	= @state.get_contact(public_key)
			if existing_contact
				detox_chat_app.notify_warning("Not added: this contact is already in contacts list under nickname <i>#{existing_contact.nickname}</i>", 3)
				return
			@state.add_contact(public_key, @new_contact_name || @new_contact_id, remote_secret)
			detox_chat_app.notify_success("Contact added.<br>You can already send messages and they will be delivered when/if contact request is accepted.", 5)
			@add_contact		= false
			@new_contact_id		= ''
			@new_contact_name	= ''
		catch
			detox_chat_app.notify_error('Incorrect ID, check for typos and try again', 3)
	_add_contact_cancel : !->
		@add_contact	= false
	_help : !->
		if @advanced_user
			content	= """
				<p>You need to add contact using their ID in order to communicate.</p>
				<p>There are 2 kinds of IDs: without secrets and with secrets. Look at <i>Profile</i> tab for more details on those.</p>
				<p>Each contact in the list might have some of the corners highlighted, which indicates some information about its state.</p>
				<p>Top left corner is highlighted when there is an active connection to contact right now.<br>
				Bottom left corner is highlighted means that there was never an active connection, for instance you've added someone to contacts, but they didn't accept request (yet).<br>
				Top right corner is highlighted when there are unread messages from that contact.<br>
				Bottom right corner is highlighted when your last message to contact was not yet received (just received, there is no indication if it was read by contact).</p>
			"""
		else
			content	= """
				<p>You need to add contact using their ID in order to communicate.</p>
				<p>Your ID can be found in <i>Profile</i> tab.</p>
				<p>Each contact in the list might have some of the corners highlighted, which indicates some information about its state.</p>
				<p>Top left corner is highlighted when there is an active connection to contact right now.<br>
				Bottom left corner is highlighted means that there was never an active connection, for instance you've added someone to contacts, but they didn't accept request (yet).<br>
				Top right corner is highlighted when there are unread messages from that contact.<br>
				Bottom right corner is highlighted when your last message to contact was not yet received (just received, there is no indication if it was read by contact).</p>
			"""
		csw.functions.simple_modal(content)
	_set_active_contact : (e) !->
		@state
			..set_ui_active_contact(e.model.item.id)
			..set_ui_sidebar_shown(false)
	_rename_contact : (e) !->
		modal	= csw.functions.prompt("New nickname:", (new_nickname) !~>
			@state.set_contact_nickname(e.model.item.id, new_nickname)
			detox_chat_app.notify_success('Nickname updated', 3)
		)
		modal.input.value	= e.model.item.nickname
		e.stopPropagation()
	_del_contact : (e) !->
		csw.functions.confirm("<h3>Are you sure you want to delete contact <i>#{e.model.item.nickname}</i>?</h3>", !~>
			@state.del_contact(e.model.item.id)
		)
		e.stopPropagation()
	_accept_contact_request : (e) !->
		state	= @state

		item	= e.model.item
		if @advanced_user
			content	= """
				<h3>What do you want to do with contact request?</h3>
				<p>ID: <i>#{item.name}</i></p>
				<p>Secret used: <i>#{item.secret_name}</i></p>
				<csw-group>
					<csw-button primary><button id="accept">Accept</button></csw-button>
					<csw-button><button id="reject">Reject</button></csw-button>
					<csw-button><button id="cancel">Cancel</button></csw-button>
				</csw-group>
			"""
		else
			content	= """
				<h3>What do you want to do with contact request?</h3>
				<p>ID: <i>#{item.name}</i></p>
				<csw-group>
					<csw-button primary><button id="accept">Accept</button></csw-button>
					<csw-button><button id="reject">Reject</button></csw-button>
					<csw-button><button id="cancel">Cancel</button></csw-button>
				</csw-group>
			"""
		modal	= csw.functions.simple_modal(content)
		modal.querySelector('#accept').addEventListener('click', !->
			state.add_contact(item.id, item.name, new Uint8Array(0))
			state.del_contact_request(item.id)
			modal.close()
			detox_chat_app.notify_success('Contact added', 3)
		)
		modal.querySelector('#reject').addEventListener('click', !->
			state.del_contact_request(item.id)
			modal.close()
			detox_chat_app.notify_warning('Contact request rejected', 3)
		)
		modal.querySelector('#cancel').addEventListener('click', !->
			modal.close()
		)
	_online : (contact, online_contacts) ->
		online_contacts.has(contact.id)
	_selected : (contact, ui_active_contact) ->
		ui_active_contact.has(contact.id)
	_unconfirmed : (contact) ->
		!contact.local_secret
	_unread : (contact, contacts_with_unread_messages) ->
		contacts_with_unread_messages.has(contact.id)
	_pending : (contact, contacts_with_pending_messages) ->
		contacts_with_pending_messages.has(contact.id)
)
