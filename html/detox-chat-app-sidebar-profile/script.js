// Generated by LiveScript 1.5.0
/**
 * @package Detox chat app
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
(function(){
  Polymer({
    is: 'detox-chat-app-sidebar-profile',
    behaviors: [detoxChatApp.behaviors.state],
    properties: {
      id_base58: String,
      name: {
        observer: '_nickname_changed',
        type: String
      }
    },
    ready: function(){
      var this$ = this;
      Promise.all([require(['@detox/chat', '@detox/crypto']), this._state_instance_ready]).then(function(arg$){
        var ref$, detoxChat, detoxCrypto;
        ref$ = arg$[0], detoxChat = ref$[0], detoxCrypto = ref$[1];
        detoxCrypto.ready(function(){
          detoxChat.ready(function(){
            var id_encode, state, public_key;
            id_encode = detoxChat.id_encode;
            state = this$._state_instance;
            function update_secrets(){
              var res$, i$, ref$, len$, secret;
              res$ = [];
              for (i$ = 0, len$ = (ref$ = state.get_secrets()).length; i$ < len$; ++i$) {
                secret = ref$[i$];
                res$.push({
                  id: id_encode(public_key, secret.secret),
                  name: secret.name
                });
              }
              this$.secrets = res$;
            }
            public_key = detoxCrypto.create_keypair(state.get_seed()).ed25519['public'];
            this$.id_base58 = id_encode(public_key, new Uint8Array(0));
            this$.name = state.get_nickname();
            update_secrets();
            state.on('nickname_changed', function(new_name){
              if (this$.name !== new_name) {
                this$.name = new_name;
              }
            }).on('secrets_changed', update_secrets);
          });
        });
      });
    },
    _nickname_changed: function(){
      if (this.name !== this._state_instance.get_nickname()) {
        this._state_instance.set_nickname(this.name);
      }
    },
    _id_click: function(e){
      e.target.select();
    },
    _add_secret: function(){
      var content, modal, this$ = this;
      content = "<csw-form>\n	<form>\n		<label>Secret name:</label>\n		<label>\n			<csw-input-text>\n				<input id=\"name\">\n			</csw-input-text>\n		</label>\n		<label>Secret length:</label>\n		<label>\n			<csw-input-text>\n				<input id=\"length\" min=\"1\" max=\"32\" value=\"4\">\n			</csw-input-text>\n		</label>\n	</form>\n</csw-form>";
      modal = csw.functions.confirm(form, function(){
        var name, length;
        name = modal.querySelector('#name').value;
        if (!name) {
          return;
        }
        length = modal.querySelector('#length').value;
        require(['@detox/chat']).then(function(arg$){
          var detoxChat, secret;
          detoxChat = arg$[0];
          secret = detoxChat.generate_secret().slice(0, length);
          this$._state_instance.add_secret(secret, name);
        });
      });
    }
  });
}).call(this);
