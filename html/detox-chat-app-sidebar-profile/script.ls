/**
 * @package Detox chat app
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
Polymer(
	is			: 'detox-chat-app-sidebar-profile'
	behaviors	: [
		detox-chat-app.behaviors.state
	]
	properties	:
		id_base58			: String
		name				:
			observer	: '_nickname_changed'
			type		: String
	ready : !->
		Promise.all([
			require(['@detox/chat', '@detox/crypto'])
			@_state_instance_ready
		]).then ([[detox-chat, detox-crypto]]) !~>
			<~! detox-crypto.ready
			<~! detox-chat.ready
			state		= @_state_instance
			# TODO: Secrets and multiple textarea elements with different IDs
			@id_base58	= detox-chat.id_encode(
				detox-crypto.create_keypair(state.get_seed()).ed25519.public
				new Uint8Array(0)
			)
			@name		= state.get_nickname()
			state
				.on('nickname_changed', (new_name) !~>
					if @name != new_name
						@name	= new_name
				)
	_nickname_changed : !->
		if @name != @_state_instance.get_nickname()
			@_state_instance.set_nickname(@name)
	_id_click : (e) !->
		e.target.select()
)
