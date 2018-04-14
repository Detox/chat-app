/**
 * @package Detox chat app
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
// Generated by LiveScript 1.5.0
(function(){
  require(['@detox/utils', 'hotkeys-js', 'js/behaviors', 'js/markdown']).then(function(arg$){
    var detoxUtils, hotkeysJs, behaviors, markdown;
    detoxUtils = arg$[0], hotkeysJs = arg$[1], behaviors = arg$[2], markdown = arg$[3];
    function node_to_string(node){
      var nodes;
      nodes = node.childNodes;
      if (nodes.length) {
        return (function(){
          var i$, ref$, len$, results$ = [];
          for (i$ = 0, len$ = (ref$ = nodes).length; i$ < len$; ++i$) {
            node = ref$[i$];
            results$.push(node_to_string(node));
          }
          return results$;
        }()).map(function(node){
          return node.trim();
        }).filter(Boolean).join(' ');
      } else {
        return node.textContent.trim();
      }
    }
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
        send_ctrl_enter: Boolean,
        text_message: {
          type: String,
          value: ''
        },
        unread_messages: Boolean
      },
      created: function(){
        this._ctrl_enter_handler = this._ctrl_enter_handler.bind(this);
        this._enter_handler = this._enter_handler.bind(this);
      },
      ready: function(){
        var are_arrays_equal, ArrayMap, text_messages, state, this$ = this;
        are_arrays_equal = detoxUtils.are_arrays_equal;
        ArrayMap = detoxUtils.ArrayMap;
        text_messages = ArrayMap();
        state = this.state;
        this.active_contact = !!state.get_ui_active_contact();
        this.send_ctrl_enter = state.get_settings_send_ctrl_enter();
        this._update_unread_messages();
        state.on('contact_message_added', function(contact_id, message){
          var active_contact, contact, x$, tmp_node, text;
          active_contact = state.get_ui_active_contact();
          if (message.origin === state.MESSAGE_ORIGIN_RECEIVED && !(document.hasFocus() && active_contact && are_arrays_equal(contact_id, active_contact))) {
            contact = state.get_contact(contact_id);
            x$ = tmp_node = document.createElement('div');
            x$.innerHTML = message.text;
            text = node_to_string(tmp_node);
            detox_chat_app.notify(contact.nickname, text.length > 60 ? text.substr(0, 60) + '...' : text, 3);
          }
        }).on('contact_messages_changed', function(contact_id){
          var active_contact, messages_list, need_to_update_scroll;
          active_contact = state.get_ui_active_contact();
          if (active_contact && are_arrays_equal(contact_id, active_contact)) {
            messages_list = this$.$['messages-list'];
            need_to_update_scroll = messages_list.scrollHeight - messages_list.offsetHeight === messages_list.scrollTop;
            state.get_contact_messages(contact_id).then(function(messages){
              this$.messages = messages;
              this$.notifyPath('messages');
              if (need_to_update_scroll) {
                this$.$['messages-list-template'].render();
                messages_list.scrollTop = messages_list.scrollHeight - messages_list.offsetHeight;
              }
            });
          }
        }).on('contact_changed', function(new_contact){
          var ref$;
          if (((ref$ = this$.contact) != null && ref$.id) && are_arrays_equal(this$.contact.id, new_contact.id)) {
            this$.contact = new_contact;
          }
        }).on('contact_deleted', function(old_contact){
          text_messages['delete'](old_contact.id);
        }).on('contacts_with_unread_messages_changed', function(){
          this$._update_unread_messages();
        }).on('ui_active_contact_changed', function(new_active_contact, old_active_contact){
          var text_message;
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
          state.get_contact_messages(new_active_contact).then(function(messages){
            var messages_list;
            this$.messages = messages;
            this$.notifyPath('messages');
            this$.$['messages-list-template'].render();
            messages_list = this$.$['messages-list'];
            messages_list.scrollTop = messages_list.scrollHeight - messages_list.offsetHeight;
            this$._update_unread_messages();
          });
        }).on('settings_send_ctrl_enter_changed', function(send_ctrl_enter){
          this$.send_ctrl_enter = send_ctrl_enter;
        });
      },
      attached: function(){
        hotkeysJs('Ctrl+Enter', this._ctrl_enter_handler);
        hotkeysJs('Enter', this._enter_handler);
      },
      detached: function(){
        hotkeysJs.unbind('Ctrl+Enter', this._ctrl_enter_handler);
        hotkeysJs.unbind('Enter', this._enter_handler);
      },
      _ctrl_enter_handler: function(e){
        if (e.composedPath()[0] === this.$.textarea) {
          this._send();
          e.preventDefault();
        }
      },
      _enter_handler: function(e){
        if (e.composedPath()[0] === this.$.textarea && !this.send_ctrl_enter) {
          this._send();
          e.preventDefault();
        }
      },
      _update_unread_messages: function(){
        var state;
        state = this.state;
        this.unread_messages = !!state.get_contacts_with_unread_messages().filter(function(contact){
          return contact !== state.get_ui_active_contact();
        }).length;
      },
      _show_sidebar: function(){
        this.state.set_ui_sidebar_shown(true);
      },
      _send_placeholder: function(send_ctrl_enter){
        return 'Type you message here, Markdown (GFM) supported!\n' + (send_ctrl_enter ? 'Enter for new line, Ctrl+Enter for sending' : 'Shift+Enter for new line, Enter for sending');
      },
      _send: function(){
        var text_message, state, contact_id;
        text_message = this.text_message.trim();
        if (!text_message) {
          return;
        }
        this.text_message = '';
        state = this.state;
        contact_id = state.get_ui_active_contact();
        state.add_contact_message(contact_id, state.MESSAGE_ORIGIN_SENT, +new Date, 0, text_message);
      },
      _markdown_renderer: function(markdown_text){
        return markdown(markdown_text);
      },
      _format_date: function(date){
        if (!date) {
          return 'Not yet';
        } else if (date - new Date < 24 * 60 * 60 * 1000) {
          return new Date(date).toLocaleTimeString();
        } else {
          return new Date(date).toLocaleString();
        }
      },
      _message_origin: function(message){
        switch (message.origin) {
        case this.state.MESSAGE_ORIGIN_SENT:
          return 'sent';
        case this.state.MESSAGE_ORIGIN_RECEIVED:
          return 'received';
        case this.state.MESSAGE_ORIGIN_SERVICE:
          return 'service';
        }
      },
      _help_insecure: function(){
        var content;
        content = "<p>Don't get this message wrong, Detox Chat in particular and Detox network in general are built with security and anonymity in mind from the beginning.</p>\n<p>However, until independent security audit is conducted and proves that the application is indeed secure, you shouldn't trust it critical data.</p>";
        csw.functions.simple_modal(content);
      }
    });
  });
}).call(this);
