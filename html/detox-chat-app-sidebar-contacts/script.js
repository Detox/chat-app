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
    },
    _set_active_contact: function(e){
      this._state_instance.set_ui_active_contact(e.model.item.id);
    },
    _add_contact: function(){
      var modal, this$ = this;
      modal = csw.functions.confirm("<csw-form>\n	<form>\n		<label>\n			<csw-textarea>\n				<textarea id=\"id\" placeholder=\"ID\"></textarea>\n			</csw-textarea>\n		</label>\n		<label>\n			<csw-textarea>\n				<textarea id=\"name\" placeholder=\"Name (optional)\"></textarea>\n			</csw-textarea>\n		</label>\n	</form>\n</csw-form>", function(){
        var id_base58, name;
        id_base58 = modal.querySelector('#id').value;
        name = modal.querySelector('#name').value;
        require(['@detox/chat']).then(function(arg$){
          var detoxChat, ref$, public_key, secret;
          detoxChat = arg$[0];
          try {
            ref$ = detoxChat.id_decode(id_base58), public_key = ref$[0], secret = ref$[1];
            this$._state_instance.add_contact(public_key, name, secret);
          } catch (e$) {}
        });
      });
    }
  });
}).call(this);
