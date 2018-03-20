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
      new_contact_id: String,
      new_contact_name: String,
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
        this$.ui_active_contact = ArraySet([state.get_ui_active_contact() || new Uint8Array(0)]);
        state.on('contacts_changed', function(){
          this$.contacts = state.get_contacts();
        }).on('online_contacts_changed', function(){
          this$.online_contacts = ArraySet(state.get_online_contacts());
        }).on('contacts_requests_changed', function(){
          var contacts_requests;
          contacts_requests = state.get_contacts_requests();
          this$.contacts_requests = contacts_requests;
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
    _set_active_contact: function(e){
      this._state_instance.set_ui_active_contact(e.model.item.id);
    },
    _rename_contact: function(e){
      var modal, this$ = this;
      modal = csw.functions.prompt("New nickname:", function(new_nickname){
        this$._state_instance.set_contact_nickname(e.model.item.id, new_nickname);
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
      content = "<h3>What do you want to do with contact request from <i>" + item.name + "</i> that used secret <i>" + item.secret_name + "</i>?</h3>\n<csw-button primary><button id=\"accept\">Accept</button></csw-button>\n<csw-button><button id=\"reject\">Reject</button></csw-button>\n<csw-button><button id=\"cancel\">Cancel</button></csw-button>";
      modal = csw.functions.simple_modal(content);
      modal.querySelector('#accept').addEventListener('click', function(){
        state.add_contact(item.id, '', new Uint8Array(0));
        state.del_contact_request(item.id);
        modal.close();
      });
      modal.querySelector('#reject').addEventListener('click', function(){
        state.del_contact_request(item.id);
        modal.close();
      });
      modal.querySelector('#cancel').addEventListener('click', function(){
        modal.close();
      });
    },
    _online: function(contact_id, online_contacts){
      return online_contacts.has(contact_id);
    },
    _selected: function(contact_id, ui_active_contact){
      return ui_active_contact.has(contact_id);
    }
  });
}).call(this);
