// Generated by LiveScript 1.5.0
/**
 * @package Detox chat app
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
(function(){
  Polymer({
    is: 'detox-chat-app',
    behaviors: [detoxChatApp.behaviors.state],
    created: function(){
      var this$ = this;
      Promise.all([require(['@detox/chat', '@detox/core', '@detox/utils']), this._state_instance_ready]).then(function(arg$){
        var ref$, detoxChat, detoxCore, detoxUtils;
        ref$ = arg$[0], detoxChat = ref$[0], detoxCore = ref$[1], detoxUtils = ref$[2];
        if (!this$._state_instance.get_settings_online()) {
          return;
        }
        detoxChat.ready(function(){
          detoxCore.ready(function(){
            this$._connect_to_the_network(detoxChat, detoxCore, detoxUtils);
          });
        });
      });
    },
    _connect_to_the_network: function(detoxChat, detoxCore, detoxUtils){
      var ArrayMap, secrets_exchange_statuses, sent_messages_map, state, core, chat, this$ = this;
      ArrayMap = detoxUtils.ArrayMap;
      secrets_exchange_statuses = ArrayMap();
      sent_messages_map = ArrayMap();
      function check_and_add_to_online(friend_id){
        var secrets_exchange_status, nickname, i$, ref$, len$, message;
        secrets_exchange_status = secrets_exchange_statuses.get(friend_id);
        if (secrets_exchange_status.received && secrets_exchange_status.sent) {
          state.add_online_contact(friend_id);
          nickname = state.get_nickname();
          if (nickname) {
            chat.nickname(friend_id, nickname);
          }
          for (i$ = 0, len$ = (ref$ = state.get_contact_messages_to_be_sent(friend_id)).length; i$ < len$; ++i$) {
            message = ref$[i$];
            send_message(friend_id, message);
          }
        }
      }
      function send_message(friend_id, message){
        var date_sent;
        date_sent = chat.text_message(friend_id, message.date_written, message.text);
        if (!sent_messages_map.has(friend_id)) {
          sent_messages_map.set(friend_id, new Map);
        }
        sent_messages_map.get(friend_id).set(date_sent, message.id);
      }
      state = this._state_instance;
      core = detoxCore.Core(detoxCore.generate_seed(), state.get_settings_bootstrap_nodes(), state.get_settings_ice_servers(), state.get_packets_per_second(), state.get_bucket_size()).once('ready', function(){
        state.set_online(true);
        if (state.get_settings_announce()) {
          chat.announce();
        }
      });
      chat = detoxChat.Chat(core, state.get_seed(), state.get_number_of_introduction_nodes(), state.get_number_of_intermediate_nodes()).once('announced', function(){
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
      }).on('connection_failed', function(friend_id){}).on('secret', function(friend_id, secret){
        secrets_exchange_statuses.get(friend_id).received = true;
        check_and_add_to_online(friend_id);
      }).on('secret_received', function(friend_id){
        secrets_exchange_statuses.get(friend_id).sent = true;
        check_and_add_to_online(friend_id);
      }).on('nickname', function(friend_id, nickname){
        state.set_contact_nickname(friend_id, nickname);
      }).on('text_message', function(friend_id, date_written, date_sent, text_message){
        state.add_contact_message(friend_id, true, date_written, date_sent, text_message);
      }).on('text_message_received', function(friend_id, date_sent){
        var id, ref$;
        id = (ref$ = sent_messages_map.get(friend_id)) != null ? ref$.get(date_sent) : void 8;
        if (id) {
          sent_messages_map.get(friend_id)['delete'](date_sent);
          state.set_contact_message_sent(friend_id, id, date_sent);
        }
      }).on('disconnected', function(friend_id){
        secrets_exchange_statuses['delete'](friend_id);
        sent_messages_map['delete'](friend_id);
        state.del_online_contact(friend_id);
      });
      state.on('contact_added', function(new_contact){
        chat.connect_to(new_contact.id, new Uint8Array(0));
      }).on('contact_message_added', function(friend_id, message){
        if (message.from || message.date_received || !state.has_online_contact(friend_id)) {
          return;
        }
        send_message(friend_id, message);
      });
      this._core_instance = core;
      this._chat_instance = chat;
    }
  });
}).call(this);
