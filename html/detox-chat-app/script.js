// Generated by LiveScript 1.5.0
/**
 * @package Detox chat app
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
(function(){
  require(['js/behaviors']).then(function(arg$){
    var behaviors;
    behaviors = arg$[0];
    Polymer({
      is: 'detox-chat-app',
      behaviors: [behaviors.state],
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
        var are_arrays_equal, timeoutSet, ArrayMap, secrets_exchange_statuses, sent_messages_map, reconnects_pending, state, core, chat, this$ = this;
        are_arrays_equal = detoxUtils.are_arrays_equal;
        timeoutSet = detoxUtils.timeoutSet;
        ArrayMap = detoxUtils.ArrayMap;
        secrets_exchange_statuses = ArrayMap();
        sent_messages_map = ArrayMap();
        reconnects_pending = ArrayMap();
        state = this._state_instance;
        core = detoxCore.Core(detoxCore.generate_seed(), state.get_settings_bootstrap_nodes(), state.get_settings_ice_servers(), state.get_settings_packets_per_second(), state.get_settings_bucket_size());
        chat = detoxChat.Chat(core, state.get_seed(), state.get_settings_number_of_introduction_nodes(), state.get_settings_number_of_intermediate_nodes());
        /**
         * @param {!Uint8Array} contact_id
         */
        function check_and_add_to_online(contact_id){
          var secrets_exchange_status, nickname, i$, ref$, len$, message;
          secrets_exchange_status = secrets_exchange_statuses.get(contact_id);
          if (secrets_exchange_status.received && secrets_exchange_status.sent) {
            state.add_online_contact(contact_id);
            nickname = state.get_nickname();
            if (nickname) {
              chat.nickname(contact_id, nickname);
            }
            for (i$ = 0, len$ = (ref$ = state.get_contact_messages_to_be_sent(contact_id)).length; i$ < len$; ++i$) {
              message = ref$[i$];
              send_message(contact_id, message);
            }
          }
        }
        /**
         * @param {!Uint8Array}	contact_id
         * @param {!Object}		message
         */
        function send_message(contact_id, message){
          var date_sent;
          date_sent = chat.text_message(contact_id, message.date_written, message.text);
          if (!sent_messages_map.has(contact_id)) {
            sent_messages_map.set(contact_id, new Map);
          }
          sent_messages_map.get(contact_id).set(date_sent, message.id);
        }
        /**
         * @param {!Uint8Array} contact_id
         */
        function do_reconnect_if_needed(contact_id){
          var contact, reconnect_pending, i$, ref$, len$, ref1$, reconnection_trial, time_before_next_attempt;
          contact = state.get_contact(contact_id);
          if (!contact) {
            return;
          }
          if (!(state.get_contact_messages_to_be_sent(contact_id).length && contact.local_secret)) {
            return;
          }
          if (!reconnects_pending.has(contact_id)) {
            reconnects_pending.set(contact_id, {
              trial: 0,
              timeout: null
            });
          }
          reconnect_pending = reconnects_pending.get(contact_id);
          if (reconnect_pending.timeout) {
            return;
          }
          ++reconnect_pending.trial;
          for (i$ = 0, len$ = (ref$ = state.get_settings_reconnects_intervals()).length; i$ < len$; ++i$) {
            ref1$ = ref$[i$], reconnection_trial = ref1$[0], time_before_next_attempt = ref1$[1];
            if (reconnect_pending.trial <= reconnection_trial) {
              reconnect_pending.timeout = timeoutSet(time_before_next_attempt, fn$);
              break;
            }
          }
          function fn$(){
            reconnect_pending.timeout = null;
            chat.connect_to(contact_id, contact.remote_secret);
          }
        }
        core.once('ready', function(){
          var i$, ref$, len$, contact;
          state.set_online(true);
          if (state.get_settings_announce()) {
            chat.announce();
          }
          for (i$ = 0, len$ = (ref$ = state.get_contacts()).length; i$ < len$; ++i$) {
            contact = ref$[i$];
            do_reconnect_if_needed(contact.id);
          }
        }).on('connected_nodes_count', function(count){
          state.set_connected_nodes_count(count);
        }).on('aware_of_nodes_count', function(count){
          state.set_aware_of_nodes_count(count);
        }).on('routing_paths_count', function(count){
          state.set_routing_paths_count(count);
        }).on('application_connections_count', function(count){
          state.set_application_connections_count(count);
        });
        chat.once('announced', function(){
          state.set_announced(true);
        }).on('introduction', function(contact_id, secret){
          var contact, secret_length, i$, ref$, len$, local_secret, x$, padded_secret;
          contact = state.get_contact(contact_id);
          if (!contact) {
            if (state.has_contact_request_blocked(contact_id)) {
              return;
            }
            secret_length = secret.length;
            for (i$ = 0, len$ = (ref$ = state.get_secrets()).length; i$ < len$; ++i$) {
              local_secret = ref$[i$];
              x$ = padded_secret = new Uint8Array(secret_length);
              x$.set(local_secret.secret);
              if (are_arrays_equal(secret, padded_secret) && !state.has_contact_request(contact_id)) {
                state.add_contact_request(contact_id, local_secret.secret);
                break;
              }
            }
            return false;
          } else if (!contact.local_secret || are_arrays_equal(secret, contact.local_secret) || (contact.old_local_contact && are_arrays_equal(secret, contact.old_local_secret))) {
            return true;
          } else {
            return false;
          }
        }).on('connected', function(contact_id){
          var reconnect_pending, local_secret;
          if (reconnects_pending.has(contact_id)) {
            reconnect_pending = reconnects_pending.get(contact_id);
            if (reconnect_pending.timeout) {
              clearTimeout(reconnect_pending.timeout);
            }
            reconnects_pending['delete'](contact_id);
          }
          if (!state.has_contact(contact_id)) {
            return;
          }
          secrets_exchange_statuses.set(contact_id, {
            received: false,
            sent: false
          });
          local_secret = detoxChat.generate_secret();
          state.set_contact_local_secret(contact_id, local_secret);
          chat.secret(contact_id, local_secret);
        }).on('connection_failed', function(contact_id){
          do_reconnect_if_needed(contact_id);
        }).on('secret', function(contact_id, remote_secret){
          var contact;
          contact = state.get_contact(contact_id);
          if (are_arrays_equal(remote_secret, contact.remote_secret)) {
            return false;
          }
          state.set_contact_remote_secret(contact_id, remote_secret);
          secrets_exchange_statuses.get(contact_id).received = true;
          check_and_add_to_online(contact_id);
          return true;
        }).on('secret_received', function(contact_id){
          state.del_contact_old_local_secret(contact_id);
          secrets_exchange_statuses.get(contact_id).sent = true;
          check_and_add_to_online(contact_id);
        }).on('nickname', function(contact_id, nickname){
          nickname = nickname.trimLeft();
          if (nickname) {
            state.set_contact_nickname(contact_id, nickname);
          }
        }).on('text_message', function(contact_id, date_written, date_sent, text_message){
          var i$, ref$, old_message, last_message_received;
          text_message = text_message.trim();
          if (!text_message) {
            return;
          }
          for (i$ = (ref$ = state.get_contact_messages(contact_id)).length - 1; i$ >= 0; --i$) {
            old_message = ref$[i$];
            if (old_message.from) {
              last_message_received = old_message;
              break;
            }
          }
          if (last_message_received && (last_message_received.date_sent > date_sent || last_message_received.date_written >= date_written)) {
            return;
          }
          state.add_contact_message(contact_id, true, date_written, date_sent, text_message);
        }).on('text_message_received', function(contact_id, date_sent){
          var id, ref$;
          id = (ref$ = sent_messages_map.get(contact_id)) != null ? ref$.get(date_sent) : void 8;
          if (id) {
            sent_messages_map.get(contact_id)['delete'](date_sent);
            state.set_contact_message_sent(contact_id, id, date_sent);
          }
        }).on('disconnected', function(contact_id){
          secrets_exchange_statuses['delete'](contact_id);
          sent_messages_map['delete'](contact_id);
          state.del_online_contact(contact_id);
          do_reconnect_if_needed(contact_id);
        });
        state.on('contact_added', function(new_contact){
          chat.connect_to(new_contact.id, new_contact.remote_secret);
        }).on('contact_message_added', function(contact_id, message){
          var contact;
          if (message.from || message.date_received || !state.has_online_contact(contact_id)) {
            contact = state.get_contact(contact_id);
            chat.connect_to(contact_id, contact.remote_secret);
            return;
          }
          send_message(contact_id, message);
        }).on('nickname_changed', function(new_nickname){
          var i$, ref$, len$, contact;
          new_nickname = new_nickname.trim();
          if (!new_nickname) {
            return;
          }
          for (i$ = 0, len$ = (ref$ = state.get_online_contacts()).length; i$ < len$; ++i$) {
            contact = ref$[i$];
            chat.nickname(contact, new_nickname);
          }
        });
        this._core_instance = core;
        this._chat_instance = chat;
      }
    });
  });
}).call(this);
