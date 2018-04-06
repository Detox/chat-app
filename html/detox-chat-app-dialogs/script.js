// Generated by LiveScript 1.5.0
/**
 * @package Detox chat app
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
(function(){
  require(['@detox/utils', 'hotkeys-js', 'js/behaviors']).then(function(arg$){
    var detoxUtils, hotkeysJs, behaviors;
    detoxUtils = arg$[0], hotkeysJs = arg$[1], behaviors = arg$[2];
    Polymer({
      is: 'detox-chat-app-dialogs',
      behaviors: [behaviors.state_instance, Polymer.MutableDataBehavior],
      properties: {
        active_contact: {
          type: Boolean,
          value: false
        },
        contact: Object,
        messages: Array,
        text_message: {
          type: String,
          value: ''
        }
      },
      ready: function(){
        var are_arrays_equal, ArrayMap, text_messages, state, this$ = this;
        are_arrays_equal = detoxUtils.are_arrays_equal;
        ArrayMap = detoxUtils.ArrayMap;
        text_messages = ArrayMap();
        state = this._state_instance;
        this.active_contact = !!state.get_ui_active_contact();
        state.on('contact_messages_changed', function(contact_id){
          var active_contact, messages_list, need_to_update_scroll;
          active_contact = state.get_ui_active_contact();
          if (active_contact && are_arrays_equal(contact_id, active_contact)) {
            messages_list = this$.$['messages-list'];
            need_to_update_scroll = messages_list.scrollHeight - messages_list.offsetHeight === messages_list.scrollTop;
            this$.messages = state.get_contact_messages(contact_id);
            this$.notifyPath('messages');
            if (need_to_update_scroll) {
              this$.$['messages-list-template'].render();
              messages_list.scrollTop = messages_list.scrollHeight - messages_list.offsetHeight;
            }
          }
        }).on('contact_changed', function(new_contact){
          var ref$;
          if (((ref$ = this$.contact) != null && ref$.id) && are_arrays_equal(this$.contact.id, new_contact.id)) {
            this$.contact = new_contact;
          }
        }).on('contact_deleted', function(old_contact){
          text_messages['delete'](old_contact.id);
        }).on('ui_active_contact_changed', function(new_active_contact, old_active_contact){
          var text_message, messages_list;
          text_message = this$.text_message.trim();
          if (text_message && old_active_contact) {
            text_messages.set(old_active_contact, text_message);
            this$.text_message = '';
          }
          if (new_active_contact && text_messages.has(new_active_contact)) {
            this$.text_message = text_messages.get(new_active_contact);
            text_messages['delete'](new_active_contact);
          }
          if (!new_active_contact) {
            this$.active_contact = false;
            this$.contact = {};
            this$.messages = [];
            return;
          }
          this$.active_contact = true;
          this$.contact = state.get_contact(new_active_contact);
          this$.messages = state.get_contact_messages(new_active_contact);
          this$.notifyPath('messages');
          this$.$['messages-list-template'].render();
          messages_list = this$.$['messages-list'];
          messages_list.scrollTop = messages_list.scrollHeight - messages_list.offsetHeight;
        });
      },
      connectedCallback: function(){
        var this$ = this;
        hotkeysJs('Ctrl+Enter', function(e){
          if (e.path[0] === this$.$.textarea) {
            this$._send();
          }
        });
      },
      _show_sidebar: function(){
        this._state_instance.set_ui_sidebar_shown(true);
      },
      _send: function(){
        var text_message, state, contact_id;
        text_message = this.text_message.trim();
        if (!text_message) {
          return;
        }
        this.text_message = '';
        state = this._state_instance;
        contact_id = state.get_ui_active_contact();
        state.add_contact_message(contact_id, false, +new Date, 0, text_message);
      },
      _format_date: function(date){
        if (!date) {
          return 'Not yet';
        }
        if (date - new Date < 24 * 60 * 60 * 1000) {
          return new Date(date).toLocaleTimeString();
        } else {
          return new Date(date).toLocaleString();
        }
      }
    });
  });
}).call(this);
