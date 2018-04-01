// Generated by LiveScript 1.5.0
/**
 * @package Detox chat app
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
(function(){
  require(['js/behaviors']).then(function(arg$){
    var behaviors;
    behaviors = arg$[0];
    Polymer({
      is: 'detox-chat-app-sidebar-status',
      behaviors: [behaviors.state_instance],
      properties: {
        online: {
          type: Boolean,
          value: false
        },
        announced: {
          type: Boolean,
          value: false
        },
        connected_nodes_count: {
          type: Number,
          value: 0
        },
        aware_of_nodes_count: {
          type: Number,
          value: 0
        },
        routing_paths_count: {
          type: Number,
          value: 0
        },
        application_connections_count: {
          type: Number,
          value: 0
        }
      },
      ready: function(){
        var state, this$ = this;
        state = this._state_instance;
        state.on('online_changed', function(new_online){
          this$.online = new_online;
        }).on('announced_changed', function(new_announced){
          this$.announced = new_announced;
        }).on('connected_nodes_count_changed', function(connected_nodes_count){
          this$.connected_nodes_count = connected_nodes_count;
        }).on('aware_of_nodes_count_changed', function(aware_of_nodes_count){
          this$.aware_of_nodes_count = aware_of_nodes_count;
        }).on('routing_paths_count_changed', function(routing_paths_count){
          this$.routing_paths_count = routing_paths_count;
        }).on('application_connections_count_changed', function(application_connections_count){
          this$.application_connections_count = application_connections_count;
        });
      },
      _online: function(online, connected_nodes_count){
        if (online && connected_nodes_count) {
          return 'online';
        } else {
          return 'offline';
        }
      },
      _announced: function(announced){
        if (announced) {
          return 'announced';
        } else {
          return 'not announced';
        }
      }
    });
  });
}).call(this);
