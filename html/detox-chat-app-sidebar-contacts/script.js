// Generated by LiveScript 1.5.0
/**
 * @package Detox chat app
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
(function(){
  Polymer({
    is: 'detox-chat-app-sidebar-contacts',
    behaviors: [detoxChatApp.behaviors.state, detoxChatApp.behaviors.help],
    properties: {
      add_contact: {
        type: Boolean,
        value: false
      },
      contacts: {
        type: Array,
        value: []
      },
      contacts_requests: {
        type: Array,
        value: []
      },
      contacts_with_pending_messages: Object,
      contacts_with_unread_messages: Object,
      new_contact_id: {
        type: String,
        value: ''
      },
      new_contact_name: {
        type: String,
        value: ''
      },
      online_contacts: {
        type: Object
      },
      ui_active_contact: {
        type: Object
      }
    },
    ready: function(){
      var this$ = this;
      Promise.all([require(['@detox/utils']), this._state_instance_ready]).then(function(arg$){
        var detoxUtils, ArraySet, state;
        detoxUtils = arg$[0][0];
        ArraySet = detoxUtils.ArraySet;
        state = this$._state_instance;
        this$.contacts = state.get_contacts();
        this$.online_contacts = ArraySet(state.get_online_contacts());
        this$.contacts_requests = state.get_contacts_requests();
        this$.contacts_with_pending_messages = ArraySet(state.get_contacts_with_pending_messages());
        this$.contacts_with_unread_messages = ArraySet(state.get_contacts_with_unread_messages());
        this$.ui_active_contact = ArraySet([state.get_ui_active_contact() || new Uint8Array(0)]);
        state.on('contacts_changed', function(){
          this$.contacts = state.get_contacts();
        }).on('online_contacts_changed', function(){
          this$.online_contacts = ArraySet(state.get_online_contacts());
        }).on('contacts_requests_changed', function(){
          var contacts_requests;
          contacts_requests = state.get_contacts_requests();
          this$.contacts_requests = contacts_requests;
        }).on('contacts_with_pending_messages_changed', function(){
          this$.contacts_with_pending_messages = ArraySet(state.get_contacts_with_pending_messages());
        }).on('contacts_with_unread_messages_changed', function(){
          this$.contacts_with_unread_messages = ArraySet(state.get_contacts_with_unread_messages());
        }).on('ui_active_contact_changed', function(){
          this$.ui_active_contact = ArraySet([state.get_ui_active_contact() || new Uint8Array(0)]);
        });
      });
    },
    _hide_header: function(list, add_contact){
      return !list.length || add_contact;
    },
    _add_contact: function(){
      this.add_contact = true;
    },
    _add_contact_confirm: function(){
      var this$ = this;
      require(['@detox/chat', '@detox/crypto', '@detox/utils']).then(function(arg$){
        var detoxChat, detoxCrypto, detoxUtils, ref$, public_key, remote_secret, own_public_key, existing_contact, e;
        detoxChat = arg$[0], detoxCrypto = arg$[1], detoxUtils = arg$[2];
        try {
          ref$ = detoxChat.id_decode(this$.new_contact_id), public_key = ref$[0], remote_secret = ref$[1];
          own_public_key = detoxCrypto.create_keypair(this$._state_instance.get_seed()).ed25519['public'];
          if (detoxUtils.are_arrays_equal(public_key, own_public_key)) {
            csw.functions.notify('Adding yourself to contacts is not supported', 'error', 'right', 3);
            return;
          }
          existing_contact = this$._state_instance.get_contact(public_key);
          if (existing_contact) {
            csw.functions.notify("Not added: this contact is already in contacts list under nickname <i>" + existing_contact.nickname + "</i>", 'warning', 'right', 3);
            return;
          }
          this$._state_instance.add_contact(public_key, this$.new_contact_name, remote_secret);
          csw.functions.notify('Contact added', 'success', 'right', 3);
          this$.add_contact = false;
          this$.new_contact_id = '';
          this$.new_contact_name = '';
        } catch (e$) {
          e = e$;
          csw.functions.notify('Incorrect ID, check for typos and try again', 'error', 'right', 3);
        }
      });
    },
    _add_contact_cancel: function(){
      this.add_contact = false;
    },
    _help: function(){
      var content;
      content = "<p>You need to add contact in order to communicate, addition is make using IDs.</p>\n<p>There are 2 kinds of IDs: without secrets and with secrets. Look at <i>Profile</i> tab for more details on those.</p>\n<p>Each contact in the list might have some of the corners highlighted, which indicates some information about its state.</p>\n<p>Top left corner is highlighted when there is an active connection to contact right now.<br>\nBottom left corner is highlighted means that there was never an active connection, for instance you've added someone to contacts, but they didn't accept request (yet).<br>\nTop right corner is highlighted when there are unread messages from that contact.<br>\nBottom right corner is highlighted when your last message to contact was not yet received (just received, there is no indication if it was read by contact).</p>";
      csw.functions.simple_modal(content);
    },
    _set_active_contact: function(e){
      this._state_instance.set_ui_active_contact(e.model.item.id);
    },
    _rename_contact: function(e){
      var modal, this$ = this;
      modal = csw.functions.prompt("New nickname:", function(new_nickname){
        this$._state_instance.set_contact_nickname(e.model.item.id, new_nickname);
        csw.functions.notify('Nickname updated', 'success', 'right', 3);
      });
      modal.input.value = e.model.item.nickname;
      e.stopPropagation();
    },
    _del_contact: function(e){
      var this$ = this;
      csw.functions.confirm("<h3>Are you sure you want to delete contact <i>" + e.model.item.nickname + "</i>?</h3>", function(){
        this$._state_instance.del_contact(e.model.item.id);
      });
      e.stopPropagation();
    },
    _accept_contact_request: function(e){
      var state, item, content, modal;
      state = this._state_instance;
      item = e.model.item;
      content = "<h3>What do you want to do with contact request?</h3>\n<p>ID: <i>" + item.name + "</i></p>\n<p>Secret used: <i>" + item.secret_name + "</i></p>\n<csw-group>\n	<csw-button primary><button id=\"accept\">Accept</button></csw-button>\n	<csw-button><button id=\"reject\">Reject</button></csw-button>\n	<csw-button><button id=\"cancel\">Cancel</button></csw-button>\n</csw-group>";
      modal = csw.functions.simple_modal(content);
      modal.querySelector('#accept').addEventListener('click', function(){
        state.add_contact(item.id, '', new Uint8Array(0));
        state.del_contact_request(item.id);
        modal.close();
        csw.functions.notify('Contact added', 'success', 'right', 3);
      });
      modal.querySelector('#reject').addEventListener('click', function(){
        state.del_contact_request(item.id);
        modal.close();
        csw.functions.notify('Contact request rejected', 'warning', 'right', 3);
      });
      modal.querySelector('#cancel').addEventListener('click', function(){
        modal.close();
      });
    },
    _online: function(contact, online_contacts){
      return online_contacts.has(contact.id);
    },
    _selected: function(contact, ui_active_contact){
      return ui_active_contact.has(contact.id);
    },
    _unconfirmed: function(contact){
      return !contact.local_secret;
    },
    _unread: function(contact, ui_active_contact, contacts_with_unread_messages){
      return !this._selected(contact, ui_active_contact) && contacts_with_unread_messages.has(contact.id);
    },
    _pending: function(contact, contacts_with_pending_messages){
      return contacts_with_pending_messages.has(contact.id);
    }
  });
}).call(this);
