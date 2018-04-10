/**
 * @package Detox chat app
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
function Wrapper (detox-chat, state)
	state_instance =
		properties	:
			chat-id	:
				type	: String
				value	: 'detox-chat-app'
			state	: Object
		created : !->
			@state	= state.get_instance(@chat-id)
			if !@state.ready()
				csw.functions.notify("Previous state was not found, new identity generated", 'warning', 'right', 60)
				@state.set_seed(detox-chat.generate_seed())
				@state.add_secret(detox-chat.generate_secret().slice(0, 4), 'Default secret')
	experience_level = [
		state_instance
		advanced_user	:
			type	: Boolean
			value	: false
		developer		:
			type	: Boolean
			value	: false
		ready : !->
			state			= @state
			@advanced_user	= state.get_settings_experience() >= state.EXPERIENCE_ADVANCED
			@developer		= state.get_settings_experience() == state.EXPERIENCE_DEVELOPER
			state
				.on('settings_experience_changed', (experience) !~>
					@advanced_user	= experience >= state.EXPERIENCE_ADVANCED
					@developer		= experience == state.EXPERIENCE_DEVELOPER
				)
	]
	# TODO: Instead of behavior and separate elements with callbacks, it would be nice to have a custom element for help buttons
	help = [
		state_instance
		properties	:
			help	: Boolean
		ready : !->
			@help	= @state.get_settings_help()
			@state.on('settings_help_changed', (@help) !~>)
	]
	{state_instance, experience_level, help}

define(['@detox/chat', 'js/state'], Wrapper)
