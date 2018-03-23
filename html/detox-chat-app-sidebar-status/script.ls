/**
 * @package Detox chat app
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
Polymer(
	is			: 'detox-chat-app-sidebar-status'
	behaviors	: [
		detox-chat-app.behaviors.state
	]
	properties	:
		online							:
			type	: Boolean
			value	: false
		announced						:
			type	: Boolean
			value	: false
		connected_nodes_count			:
			type	: Number
			value	: 0
		aware_of_nodes_count			:
			type	: Number
			value	: 0
		routing_paths_count				:
			type	: Number
			value	: 0
		application_connections_count	:
			type	: Number
			value	: 0
	ready : !->
		<~! @_state_instance_ready.then
		state	= @_state_instance
		state
			.on('online_changed', (new_online) !~>
				@online	= new_online
			)
			.on('announced_changed', (new_announced) !~>
				@announced	= new_announced
			)
			.on('connected_nodes_count_changed', (@connected_nodes_count) !~>)
			.on('aware_of_nodes_count_changed', (@aware_of_nodes_count) !~>)
			.on('routing_paths_count_changed', (@routing_paths_count) !~>)
			.on('application_connections_count_changed', (@application_connections_count) !~>)
	_online : (online) ->
		if online
			'online'
		else
			'offline'
	_announced : (announced) ->
		if announced
			'announced'
		else
			'not announced'
)
