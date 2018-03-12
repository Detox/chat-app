// Generated by LiveScript 1.5.0
/**
 * @package Detox chat app
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
(function(){
  Polymer({
    is: 'detox-chat-app-sidebar-contacts',
    behaviors: [detoxChatApp.behaviors.state],
    properties: {
      contacts: Array
    },
    ready: function(){
      var this$ = this;
      this._state_instance_ready.then(function(){
        var state;
        state = this$._state_instance;
        this$.contacts = state.get_contacts();
        state.on('contacts_changed', function(){
          this$.contacts = state.get_contacts();
        });
      });
    }
  });
}).call(this);
