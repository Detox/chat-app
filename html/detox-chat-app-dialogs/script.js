// Generated by LiveScript 1.5.0
/**
 * @package Detox chat app
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
(function(){
  Polymer({
    is: 'detox-chat-app-dialogs',
    behaviors: [detoxChatApp.behaviors.state],
    properties: {
      active_contact: {
        type: Boolean,
        value: false
      },
      contact: Object,
      messages: Array
    },
    ready: function(){
      var this$ = this;
      Promise.all([require(['@detox/utils']), this._state_instance_ready]).then(function(arg$){
        var detoxUtils, are_arrays_equal, state;
        detoxUtils = arg$[0][0];
        are_arrays_equal = detoxUtils.are_arrays_equal;
        state = this$._state_instance;
        state.on('ui_active_contact_changed', function(new_active_contact){
          this$.active_contact = true;
          this$.contact = state.get_contact(new_active_contact);
          this$.messages = state.get_contact_messages(new_active_contact).slice();
          this$.notifyPath('messages');
          this$.$['send-form'].querySelector('textarea').value = '';
        }).on('contact_messages_changed', function(contact_id){
          var active_contact;
          active_contact = state.get_ui_active_contact();
          if (active_contact && are_arrays_equal(contact_id, active_contact)) {
            this$.messages = state.get_contact_messages(contact_id).slice();
            this$.notifyPath('messages');
          }
        }).on('contact_changed', function(new_contact){
          if (are_arrays_equal(this$.contact.id, new_contact.id)) {
            this$.contact = new_contact;
          }
        });
      });
    },
    _send: function(){
      var state, textarea, text_message, contact_id;
      state = this._state_instance;
      textarea = this.$['send-form'].querySelector('textarea');
      text_message = textarea.value;
      textarea.value = '';
      contact_id = state.get_ui_active_contact();
      state.add_contact_message(contact_id, false, +new Date, 0, text_message);
    },
    _format_date: function(date){
      if (!date) {
        return 'Unknown';
      }
      if (date - new Date < 24 * 60 * 60 * 1000) {
        return new Date(date).toLocaleTimeString();
      } else {
        return new Date(date).toLocaleString();
      }
    }
  });
}).call(this);
