// Generated by LiveScript 1.5.0
/**
 * @package Detox chat app
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
(function(){
  Polymer({
    is: 'detox-chat-app-sidebar-status',
    behaviors: [detoxChatApp.behaviors.state],
    properties: {
      online: {
        type: Boolean,
        value: false
      },
      announced: {
        type: Boolean,
        value: false
      }
    },
    ready: function(){
      var this$ = this;
      this._state_instance_ready.then(function(){
        var state;
        state = this$._state_instance;
        state.on('online_changed', function(){
          this$.online = state.get_online();
        }).on('announced_changed', function(){
          this$.announced = state.get_announced();
        });
      });
    },
    _online: function(online){
      if (online) {
        return 'Online';
      } else {
        return 'Offline';
      }
    },
    _announced: function(announced){
      if (announced) {
        return 'Yes';
      } else {
        return 'No';
      }
    }
  });
}).call(this);
