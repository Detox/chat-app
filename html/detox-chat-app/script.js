// Generated by LiveScript 1.5.0
/**
 * @package Detox chat app
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
(function(){
  var bootstrap_node_id, bootstrap_ip, bootstrap_port, bootstrap_node_info, ice_servers, packets_per_second;
  bootstrap_node_id = '3b6a27bcceb6a42d62a3a8d02a6f0d73653215771de243a63ac048a18b59da29';
  bootstrap_ip = '127.0.0.1';
  bootstrap_port = 16882;
  bootstrap_node_info = {
    node_id: bootstrap_node_id,
    host: bootstrap_ip,
    port: bootstrap_port
  };
  ice_servers = [
    {
      urls: 'stun:stun.l.google.com:19302'
    }, {
      urls: 'stun:global.stun.twilio.com:3478?transport=udp'
    }
  ];
  packets_per_second = 5;
  Polymer({
    is: 'detox-chat-app',
    behaviors: [detoxChatApp.behaviors.state],
    created: function(){
      var this$ = this;
      Promise.all([require(['@detox/chat', '@detox/core', '@detox/utils']), this._state_instance_ready]).then(function(arg$){
        var ref$, detoxChat, detoxCore, detoxUtils;
        ref$ = arg$[0], detoxChat = ref$[0], detoxCore = ref$[1], detoxUtils = ref$[2];
        detoxChat.ready(function(){
          detoxCore.ready(function(){
            this$._connect_to_the_network(detoxChat, detoxCore, detoxUtils);
          });
        });
      });
    },
    _connect_to_the_network: function(detoxChat, detoxCore, detoxUtils){
      var ArrayMap, secrets_exchange_statuses, state, core, chat, this$ = this;
      ArrayMap = detoxUtils.ArrayMap;
      secrets_exchange_statuses = ArrayMap();
      function check_and_add_to_online(friend_id){
        var secrets_exchange_status, nickname;
        secrets_exchange_status = secrets_exchange_statuses.get(friend_id);
        if (secrets_exchange_status.received && secrets_exchange_status.sent) {
          state.add_online_contact(friend_id);
          nickname = state.get_nickname();
          if (nickname) {
            chat.nickname(friend_id, nickname);
          }
        }
      }
      state = this._state_instance;
      core = detoxCore.Core(detoxCore.generate_seed(), [bootstrap_node_info], ice_servers, packets_per_second).once('ready', function(){
        state.set_online(true);
        if (state.get_settings_announce()) {
          chat.announce();
        }
      });
      chat = detoxChat.Chat(core, state.get_seed()).once('announced', function(){
        state.set_announced(true);
      }).on('introduction', function(friend_id, secret){}).on('connected', function(friend_id){
        if (!state.has_contact(friend_id)) {
          state.add_contact(friend_id, detoxUtils.base58_encode(friend_id));
        }
        secrets_exchange_statuses.set(friend_id, {
          received: false,
          sent: false
        });
        chat.secret(friend_id, detoxChat.generate_secret());
      }).on('secret', function(friend_id, secret){
        secrets_exchange_statuses.get(friend_id).received = true;
        check_and_add_to_online(friend_id);
      }).on('secret_received', function(friend_id){
        secrets_exchange_statuses.get(friend_id).sent = true;
        check_and_add_to_online(friend_id);
      }).on('nickname', function(friend_id, nickname){
        state.set_contact_nickname(friend_id, nickname);
      }).on('text_message', function(friend_id, date_written, date_sent, text_message){
        state.add_contact_message(friend_id, true, date_written, date_sent, text_message);
      }).on('text_message_received', function(friend_id, date){}).on('disconnected', function(friend_id){
        secrets_exchange_statuses['delete'](friend_id);
        state.del_online_contact(friend_id);
      });
      state.on('contact_added', function(new_contact){
        chat.connect_to(new_contact.id, new Uint8Array(0));
      }).on('contact_message_added', function(friend_id, message){
        if (message.from || message.date_received || !state.has_online_contact(friend_id)) {
          return;
        }
        chat.text_message(friend_id, message.text);
      });
      this._core_instance = core;
      this._chat_instance = chat;
    }
  });
}).call(this);
