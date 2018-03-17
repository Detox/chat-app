/**
 * @package Detox chat app
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
Polymer(
	is			: 'detox-chat-app-sidebar'
	behaviors	: [
		detox-chat-app.behaviors.state
	]
	properties	:
		id_base58			: String
		name				:
			observer	: '_nickname_changed'
			type		: String
		settings_announce	:
			observer	: '_settings_announce_changed'
			type		: Number
	ready : !->
		Promise.all([
			require(['@detox/chat', '@detox/crypto'])
			@_state_instance_ready
		]).then ([[detox-chat, detox-crypto]]) !~>
			<~! detox-crypto.ready
			<~! detox-chat.ready
			state				= @_state_instance
			# TODO: Secrets and multiple textarea elements with different IDs
			@id_base58			= detox-chat.id_encode(
				detox-crypto.create_keypair(state.get_seed()).ed25519.public
				new Uint8Array(0)
			)
			@name				= state.get_nickname()
			@settings_announce	= @_bool_to_int(state.get_settings_announce())
			state
				.on('nickname_changed', (new_name) !~>
					if @name != new_name
						@name	= new_name
				)
				.on('settings_announce_changed', (new_settings_announce) !~>
					if @settings_announce !~= new_settings_announce
						@settings_announce	= @_bool_to_int(new_settings_announce)
				)
	_bool_to_int : (value) ->
		if value then 1 else 0
	_nickname_changed : !->
		if @name != @_state_instance.get_nickname()
			@_state_instance.set_nickname(@name)
	_settings_announce_changed : !->
		if @settings_announce !~= @_state_instance.get_settings_announce()
			@_state_instance.set_settings_announce(@settings_announce ~= 1)
)
