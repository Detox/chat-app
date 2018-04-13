/**
 * @package Detox chat app
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
([detox-chat, detox-crypto, behaviors]) <-! require(['@detox/chat', '@detox/crypto', 'js/behaviors']).then

Polymer(
	is			: 'detox-chat-app-sidebar-profile'
	behaviors	: [
		behaviors.experience_level
		behaviors.help
		behaviors.state_instance
	]
	properties	:
		add_secret			:
			type	: Boolean
			value	: false
		id_base58			: String
		id_default_secret	: String
		new_secret_name		: String
		new_secret_length	:
			type	: Number
			value	: 4
		nickname			: String
	ready : !->
		<~! detox-chat.ready

		id_encode	= detox-chat.id_encode

		state		= @state

		!~function update_secrets
			secrets				= state.get_secrets()
			@id_default_secret	= id_encode(public_key, secrets[0].secret)
			@secrets			= for secret in secrets
				{
					secret	: secret.secret
					id		: id_encode(public_key, secret.secret)
					name	: secret.name
				}

		public_key	= detox-crypto.create_keypair(state.get_seed()).ed25519.public
		@id_base58	= id_encode(public_key, new Uint8Array(0))
		@nickname	= state.get_nickname()
		update_secrets()

		state
			.on('nickname_changed', (new_nickname) !~>
				if @nickname != new_nickname
					@nickname	= new_nickname
			)
			.on('secrets_changed', update_secrets)
	_nickname_blur : !->
		if @nickname != @state.get_nickname()
			@state.set_nickname(@nickname)
			detox_chat_app.notify_success('Nickname updated', 3)
	_id_click : (e) !->
		e.target.select()
		document.execCommand('copy')
		detox_chat_app.notify_success('ID copied to clipboard', 3)
	_add_secret : !->
		@add_secret	= true
	_add_secret_confirm : !->
		new_secret_name	= @new_secret_name.trim()
		if !new_secret_name
			detox_chat_app.notify_error('Secret name is required', 3)
			return
		secret	= detox-chat.generate_secret().slice(0, @new_secret_length)
		@state.add_secret(secret, new_secret_name)
		detox_chat_app.notify_success('Secret added', 3)
		@add_secret			= false
		@new_secret_name	= ''
		@new_secret_length	= 4
	_add_secret_cancel : !->
		@add_secret	= false
	_help_id : !->
		content	= """
			<p>ID is an identifier that represents you in the network.<br>
			If you share this ID with someone, they'll be able to send contact request to you.</p>
		"""
		csw.functions.simple_modal(content)
	_help_secrets : !->
		content	= """
			<p>Secrets are used as anti-spam system. You can create different secrets for different purposes.<br>
			Each time you have incoming contact request, you'll see which secret was used.<br>
			For instance, you can create a secret for conference and know who is connecting to you before you accept contact request.</p>

			<p>For contact requests you need to share ID with secret.<br>
			Plain ID without secret will not result in visible contact request, but if you and your interlocutor add each other to contacts list explicitly, you'll be connected and able to communicate.</p>
		"""
		csw.functions.simple_modal(content)
	_rename_secret : (e) !->
		modal	= csw.functions.prompt("New secret name:", (new_secret_name) !~>
			new_secret_name	= new_secret_name.trim()
			if !new_secret_name
				detox_chat_app.notify_error('Secret name is required', 3)
				return
			@state.set_secret_name(e.model.item.secret, new_secret_name)
			detox_chat_app.notify_success('Secret name updated', 3)
		)
		modal.input.value	= e.model.item.name
		e.preventDefault()
	_del_secret : (e) !->
		csw.functions.confirm("<h3>Are you sure you want to delete secret <i>#{e.model.item.name}</i>?</h3>", !~>
			@state.del_secret(e.model.item.secret)
		)
		e.preventDefault()
)
