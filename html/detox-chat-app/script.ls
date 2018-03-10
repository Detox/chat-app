/**
 * @package Detox chat app
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
Polymer(
	is			: 'detox-chat-app'
	# TODO: Decouple property and state instance creation and into its own behavior
	properties	:
		chat-id	:
			type	: String
			value	: 'detox-chat-app'
	ready : !->
		([detox-chat, state]) <~! require(['@detox/chat', 'state']).then
		@_state_instance	= state['get_instance'](@chat-id)
		if !@_state_instance['ready']()
			csw['functions']['notify']("Previous state was not found, new identity generated", 'warning')
			@_state_instance['set_seed'](detox-chat['generate_seed']())
)

