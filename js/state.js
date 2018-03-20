// Generated by LiveScript 1.5.0
/**
 * @package Detox chat app
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
(function(){
  function create_array_object(properties_list){
    /**
     * @constructor
     */
    var i$, len$;
    function ArrayObject(array){
      if (!(this instanceof ArrayObject)) {
        return new ArrayObject(array);
      }
      this['array'] = array;
    }
    ArrayObject.prototype['clone'] = function(){
      return ArrayObject(this['array'].slice());
    };
    for (i$ = 0, len$ = properties_list.length; i$ < len$; ++i$) {
      (fn$.call(this, i$, properties_list[i$]));
    }
    return ArrayObject;
    function fn$(array_index, property){
      Object.defineProperty(ArrayObject.prototype, property, {
        get: function(){
          return this['array'][array_index];
        },
        set: function(value){
          this['array'][array_index] = value;
        }
      });
    }
  }
  function Wrapper(detoxUtils, asyncEventer){
    var are_arrays_equal, ArrayMap, ArraySet, base58_encode, global_state, Contact, ContactRequest, Message, Secret;
    are_arrays_equal = detoxUtils['are_arrays_equal'];
    ArrayMap = detoxUtils['ArrayMap'];
    ArraySet = detoxUtils['ArraySet'];
    base58_encode = detoxUtils['base58_encode'];
    global_state = Object.create(null);
    /**
     * @constructor
     */
    function State(name, initial_state){
      var x$, contact, secret, i$, ref$, len$, contact_id, this$ = this;
      if (!(this instanceof State)) {
        return new State(name, initial_state);
      }
      asyncEventer.call(this);
      if (!initial_state) {
        initial_state = localStorage.getItem(name);
        initial_state = initial_state
          ? JSON.parse(initial_state)
          : Object.create(null);
      }
      this._state = initial_state;
      this._local_state = {
        online: false,
        announced: false,
        messages: ArrayMap(),
        ui: {
          active_contact: null
        },
        online_contacts: ArraySet(),
        contacts_with_pending_messages: ArraySet()
      };
      if (!('version' in this._state)) {
        x$ = this._state;
        x$['version'] = 0;
        x$['nickname'] = '';
        x$['seed'] = null;
        x$['settings'] = {
          'announce': true,
          'bootstrap_nodes': [{
            'node_id': '3b6a27bcceb6a42d62a3a8d02a6f0d73653215771de243a63ac048a18b59da29',
            'host': '127.0.0.1',
            'port': 16882
          }],
          'bucket_size': 5,
          'ice_servers': [
            {
              urls: 'stun:stun.l.google.com:19302'
            }, {
              urls: 'stun:global.stun.twilio.com:3478?transport=udp'
            }
          ],
          'max_pending_segments': 10,
          'number_of_intermediate_nodes': 3,
          'number_of_introduction_nodes': 3,
          'online': true,
          'packets_per_second': 5,
          'reconnects_intervals': [[5, 30], [10, 60], [15, 150], [100, 300], [Number.MAX_SAFE_INTEGER, 600]]
        };
        x$['contacts'] = [[[6, 148, 79, 1, 76, 156, 177, 211, 195, 184, 108, 220, 189, 121, 140, 15, 134, 174, 141, 222, 146, 77, 20, 115, 211, 253, 148, 149, 128, 147, 190, 125], 'Fake contact #1', 0, 0, null, null, null], [[6, 148, 79, 1, 76, 156, 177, 211, 195, 184, 108, 220, 189, 121, 140, 15, 134, 174, 141, 222, 146, 77, 20, 115, 211, 253, 148, 149, 128, 147, 190, 126], 'Fake contact #2', 0, 0, null, null, null]];
        x$['contacts_requests'] = [];
        x$['secrets'] = [];
      }
      if (this._state['seed']) {
        this._state['seed'] = Uint8Array.from(this._state['seed']);
      }
      this._state['contacts'] = ArrayMap((function(){
        var i$, ref$, len$, results$ = [];
        for (i$ = 0, len$ = (ref$ = this._state['contacts']).length; i$ < len$; ++i$) {
          contact = ref$[i$];
          contact[0] = Uint8Array.from(contact[0]);
          contact = Contact(contact);
          results$.push([contact['id'], contact]);
        }
        return results$;
      }.call(this)));
      this._state['contacts_requests'] = ArrayMap((function(){
        var i$, ref$, len$, results$ = [];
        for (i$ = 0, len$ = (ref$ = this._state['contacts_requests']).length; i$ < len$; ++i$) {
          contact = ref$[i$];
          contact[0] = Uint8Array.from(contact[0]);
          contact = ContactRequest(contact);
          results$.push([contact['id'], contact]);
        }
        return results$;
      }.call(this)));
      this._state['secrets'] = ArrayMap((function(){
        var i$, ref$, len$, results$ = [];
        for (i$ = 0, len$ = (ref$ = this._state['secrets']).length; i$ < len$; ++i$) {
          secret = ref$[i$];
          secret[0] = Uint8Array.from(secret[0]);
          secret = Secret(secret);
          results$.push([secret['secret'], secret]);
        }
        return results$;
      }.call(this)));
      this._local_state.messages.set(Array.from(this._state['contacts'].keys())[0], [Message([0, true, +new Date, +new Date, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.']), Message([1, false, +new Date, +new Date, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.'])]);
      for (i$ = 0, len$ = (ref$ = Array.from(this._state['contacts'].keys())).length; i$ < len$; ++i$) {
        contact_id = ref$[i$];
        this._update_contact_with_pending_messages(contact_id);
      }
      this._ready = new Promise(function(resolve){
        if (this$._state['seed']) {
          resolve();
        } else {
          this$._ready_resolve = resolve;
        }
      });
    }
    State.prototype = {
      /**
       * @param {Function} callback Callback to be executed once state is ready
       *
       * @return {boolean} Whether state is ready
       */
      'ready': function(callback){
        if (callback) {
          this._ready.then(callback);
        }
        return Boolean(this._state['seed']);
      }
      /**
       * @return {Uint8Array} Seed if configured or `null` otherwise
       */,
      'get_seed': function(){
        return this._state['seed'];
      }
      /**
       * @param {!Uint8Array} seed
       */,
      'set_seed': function(new_seed){
        var old_seed;
        old_seed = this._state['seed'];
        this._state['seed'] = new_seed;
        if (this._ready_resolve) {
          this._ready_resolve();
          delete this._ready_resolve;
        }
        this['fire']('seed_changed', new_seed, old_seed);
      }
      /**
       * @return {Uint8Array} Seed if configured or `null` otherwise
       */,
      'get_nickname': function(){
        return this._state['nickname'];
      }
      /**
       * @param {string} nickname
       */,
      'set_nickname': function(nickname){
        var old_nickname, new_nickname;
        old_nickname = this._state['nickname'];
        new_nickname = String(nickname);
        this._state['nickname'] = new_nickname;
        this['fire']('nickname_changed', new_nickname, old_nickname);
      }
      /**
       * @return {boolean} `true` if connected to network
       */,
      'get_online': function(){
        return this._local_state.online;
      }
      /**
       * @param {boolean} online
       */,
      'set_online': function(online){
        var old_online, new_online;
        old_online = this._local_state.online;
        new_online = !!online;
        this._local_state.online = new_online;
        this['fire']('online_changed', new_online, old_online);
      }
      /**
       * @return {boolean}
       */,
      'get_announced': function(){
        return this._local_state.announced;
      }
      /**
       * @param {boolean} announced
       */,
      'set_announced': function(announced){
        var old_announced, new_announced;
        old_announced = this._local_state.announced;
        new_announced = !!announced;
        this._local_state.announced = new_announced;
        this['fire']('announced_changed', new_announced, old_announced);
      }
      /**
       * @return {Uint8Array}
       */,
      'get_ui_active_contact': function(){
        return this._local_state.ui.active_contact;
      }
      /**
       * @param {Uint8Array} contact_id
       */,
      'set_ui_active_contact': function(new_active_contact){
        var old_active_contact;
        old_active_contact = this._local_state.ui.active_contact;
        this._local_state.ui.active_contact = new_active_contact;
        this['fire']('ui_active_contact_changed', new_active_contact, old_active_contact);
      }
      /**
       * @return {boolean}
       */,
      'get_settings_announce': function(){
        return this._state['settings']['announce'];
      }
      /**
       * @param {boolean} announce
       */,
      'set_settings_announce': function(announce){
        var old_announce, new_announce;
        old_announce = this._state['settings']['announce'];
        new_announce = announce;
        this._state['settings']['announce'] = new_announce;
        this['fire']('settings_announce_changed', new_announce, old_announce);
      }
      /**
       * @return {!Array<!Object>}
       */,
      'get_settings_bootstrap_nodes': function(){
        return this._state['settings']['bootstrap_nodes'];
      }
      /**
       * @param {string}		node_id
       * @param {string}		host
       * @param {number}		port
       */,
      'add_settings_bootstrap_node': function(node_id, host, port){
        var bootstrap_node;
        bootstrap_node = {
          'node_id': node_id,
          'host': host,
          'port': port
        };
        this._state['settings']['bootstrap_nodes'].push(bootstrap_node);
        this['fire']('settings_bootstrap_node_added', bootstrap_node);
        this['fire']('settings_bootstrap_nodes_changed');
      }
      /**
       * @param {!Array<!Object>} bootstrap_nodes
       */,
      'set_settings_bootstrap_nodes': function(bootstrap_nodes){
        var old_bootstrap_nodes;
        old_bootstrap_nodes = this._state['settings']['bootstrap_nodes'];
        this._state['settings']['bootstrap_nodes'] = bootstrap_nodes;
        this['fire']('settings_bootstrap_nodes_changed', bootstrap_nodes, old_bootstrap_nodes);
      }
      /**
       * @return {number}
       */,
      'get_settings_bucket_size': function(){
        return this._state['settings']['bucket_size'];
      }
      /**
       * @param {number} bucket_size
       */,
      'set_settings_bucket_size': function(bucket_size){
        var old_bucket_size;
        old_bucket_size = this._state['bucket_size'];
        this._state['settings']['bucket_size'] = bucket_size;
        this['fire']('settings_bucket_size_changed', bucket_size, old_bucket_size);
      }
      /**
       * @return {!Array<!Object>}
       */,
      'get_settings_ice_servers': function(){
        return this._state['settings']['ice_servers'];
      }
      /**
       * @param {!Array<!Object>} ice_servers
       */,
      'set_settings_ice_servers': function(ice_servers){
        var old_ice_servers;
        old_ice_servers = this._state['settings']['ice_servers'];
        this._state['settings']['ice_servers'] = ice_servers;
        this['fire']('settings_ice_servers_changed', ice_servers, old_ice_servers);
      }
      /**
       * @return {number}
       */,
      'get_settings_max_pending_segments': function(){
        return this._state['settings']['max_pending_segments'];
      }
      /**
       * @param {number} max_pending_segments
       */,
      'set_settings_max_pending_segments': function(max_pending_segments){
        var old_max_pending_segments;
        old_max_pending_segments = this._state['max_pending_segments'];
        this._state['settings']['max_pending_segments'] = max_pending_segments;
        this['fire']('settings_max_pending_segments_changed', max_pending_segments, old_max_pending_segments);
      }
      /**
       * @return {number}
       */,
      'get_settings_number_of_intermediate_nodes': function(){
        return this._state['settings']['number_of_intermediate_nodes'];
      }
      /**
       * @param {number} number_of_intermediate_nodes
       */,
      'set_settings_number_of_intermediate_nodes': function(number_of_intermediate_nodes){
        var old_number_of_intermediate_nodes;
        old_number_of_intermediate_nodes = this._state['number_of_intermediate_nodes'];
        this._state['settings']['number_of_intermediate_nodes'] = number_of_intermediate_nodes;
        this['fire']('settings_number_of_intermediate_nodes_changed', number_of_intermediate_nodes, old_number_of_intermediate_nodes);
      }
      /**
       * @return {number}
       */,
      'get_settings_number_of_introduction_nodes': function(){
        return this._state['settings']['number_of_introduction_nodes'];
      }
      /**
       * @param {number} number_of_introduction_nodes
       */,
      'set_settings_number_of_introduction_nodes': function(number_of_introduction_nodes){
        var old_number_of_introduction_nodes;
        old_number_of_introduction_nodes = this._state['number_of_introduction_nodes'];
        this._state['settings']['number_of_introduction_nodes'] = number_of_introduction_nodes;
        this['fire']('settings_number_of_introduction_nodes_changed', number_of_introduction_nodes, old_number_of_introduction_nodes);
      }
      /**
       * @return {boolean} `false` if application works completely offline
       */,
      'get_settings_online': function(){
        return this._state['settings']['online'];
      }
      /**
       * @param {boolean} online
       */,
      'set_settings_online': function(online){
        var old_online;
        old_online = this._state['online'];
        this._state['settings']['online'] = online;
        this['fire']('settings_online_changed', online, old_online);
      }
      /**
       * @return {number}
       */,
      'get_settings_packets_per_second': function(){
        return this._state['settings']['packets_per_second'];
      }
      /**
       * @param {number} packets_per_second
       */,
      'set_settings_packets_per_second': function(packets_per_second){
        var old_packets_per_second;
        old_packets_per_second = this._state['packets_per_second'];
        this._state['settings']['packets_per_second'] = packets_per_second;
        this['fire']('settings_packets_per_second_changed', packets_per_second, old_packets_per_second);
      }
      /**
       * @return {!Array<!Array<number>>}
       */,
      'get_settings_reconnects_intervals': function(){
        return this._state['settings']['reconnects_intervals'];
      }
      /**
       * @param {!Array<!Array<number>>} reconnects_intervals
       */,
      'set_settings_reconnects_intervals': function(reconnects_intervals){
        var old_reconnects_intervals;
        old_reconnects_intervals = this._state['reconnects_intervals'];
        this._state['settings']['reconnects_intervals'] = reconnects_intervals;
        this['fire']('settings_reconnects_intervals_changed', reconnects_intervals, old_reconnects_intervals);
      }
      /**
       * @return {!Array<!Contact>}
       */,
      'get_contacts': function(){
        return Array.from(this._state['contacts'].values());
      }
      /**
       * @return {!Array<!Uint8Array>}
       */,
      'get_contacts_with_pending_messages': function(){
        return this._local_state.contacts_with_pending_messages;
      }
      /**
       * @param {!Uint8Array} contact_id
       */,
      'get_contact': function(contact_id){
        return this._state['contacts'].get(contact_id);
      }
      /**
       * @param {!Uint8Array}	contact_id
       * @param {string}		nickname
       * @param {Uint8Array}	remote_secret
       */,
      'add_contact': function(contact_id, nickname, remote_secret){
        var new_contact;
        if (this._state['contacts'].has(contact_id)) {
          return;
        }
        if (!nickname) {
          nickname = base58_encode(contact_id);
        }
        new_contact = Contact([contact_id, nickname, 0, 0, remote_secret, null, null]);
        this._state['contacts'].set(contact_id, new_contact);
        this['fire']('contact_added', new_contact);
        this['fire']('contacts_changed');
      }
      /**
       * @param {!Uint8Array} contact_id
       */,
      'has_contact': function(contact_id){
        return this._state['contacts'].has(contact_id);
      }
      /**
       * @param {!Uint8Array}	contact_id
       * @param {string}		nickname
       */,
      'set_contact_nickname': function(contact_id, nickname){
        var old_contact, new_contact;
        old_contact = this._state['contacts'].get(contact_id);
        if (!old_contact) {
          return;
        }
        if (!nickname) {
          nickname = base58_encode(contact_id);
        }
        new_contact = old_contact['clone']();
        new_contact['nickname'] = nickname;
        this._state['contacts'].set(contact_id, new_contact);
        this['fire']('contact_changed', new_contact, old_contact);
        this['fire']('contacts_changed');
      }
      /**
       * @param {!Uint8Array}	contact_id
       * @param {!Uint8Array}	remote_secret
       */,
      'set_contact_remote_secret': function(contact_id, remote_secret){
        var old_contact, new_contact;
        old_contact = this._state['contacts'].get(contact_id);
        if (!old_contact) {
          return;
        }
        new_contact = old_contact['clone']();
        new_contact['remote_secret'] = remote_secret;
        this._state['contacts'].set(contact_id, new_contact);
        this['fire']('contact_changed', new_contact, old_contact);
        this['fire']('contacts_changed');
      }
      /**
       * @param {!Uint8Array}	contact_id
       * @param {!Uint8Array}	local_secret
       */,
      'set_contact_local_secret': function(contact_id, local_secret){
        var old_contact, old_local_secret, new_contact;
        old_contact = this._state['contacts'].get(contact_id);
        if (!old_contact) {
          return;
        }
        old_local_secret = old_contact['old_local_secret'] || old_contact['local_secret'];
        new_contact = old_contact['clone']();
        new_contact['local_secret'] = local_secret;
        new_contact['old_local_secret'] = old_local_secret;
        this._state['contacts'].set(contact_id, new_contact);
        this['fire']('contact_changed', new_contact, old_contact);
        this['fire']('contacts_changed');
      }
      /**
       * @param {!Uint8Array}	contact_id
       */,
      'del_contact_old_local_secret': function(contact_id){
        var old_contact, new_contact;
        old_contact = this._state['contacts'].get(contact_id);
        if (!old_contact) {
          return;
        }
        new_contact = old_contact['clone']();
        new_contact['old_local_secret'] = null;
        this._state['contacts'].set(contact_id, new_contact);
        this['fire']('contact_changed', new_contact, old_contact);
        this['fire']('contacts_changed');
      }
      /**
       * @param {!Uint8Array} contact_id
       */,
      'del_contact': function(contact_id){
        var old_contact;
        old_contact = this._state['contacts'].get(contact_id);
        if (!old_contact) {
          return;
        }
        if (are_arrays_equal(this['get_ui_active_contact']() || new Uint8Array(0), contact_id)) {
          this['set_ui_active_contact'](null);
        }
        this._local_state.messages['delete'](contact_id);
        this['fire']('contact_messages_changed', contact_id);
        this._state['contacts']['delete'](contact_id);
        this['fire']('contact_deleted', old_contact);
        this['fire']('contacts_changed');
      }
      /**
       * @return {!Array<!ContactRequest>}
       */,
      'get_contacts_requests': function(){
        return Array.from(this._state['contacts_requests'].values());
      }
      /**
       * @param {!Uint8Array}	contact_id
       * @param {string}		secret_name
       */,
      'add_contact_request': function(contact_id, secret_name){
        var new_contact_request;
        if (this._state['contacts_requests'].has(contact_id)) {
          return;
        }
        new_contact_request = ContactRequest([contact_id, base58_encode(contact_id), secret_name]);
        this._state['contacts_requests'].set(contact_id, new_contact_request);
        this['fire']('contact_request_added', new_contact_request);
        this['fire']('contacts_requests_changed');
      }
      /**
       * @param {!Uint8Array} contact_id
       */,
      'del_contact_request': function(contact_id){
        var old_contact_request;
        old_contact_request = this._state['contacts_requests'].get(contact_id);
        if (!old_contact_request) {
          return;
        }
        this._state['contacts_requests']['delete'](contact_id);
        this['fire']('contact_request_deleted', old_contact_request);
        this['fire']('contacts_requests_changed');
      }
      /**
       * @return {!Array<!Uint8Array>}
       */,
      'get_online_contacts': function(){
        return Array.from(this._local_state.online_contacts);
      }
      /**
       * @param {!Uint8Array} contact_id
       */,
      'add_online_contact': function(contact_id){
        this._local_state.online_contacts.add(contact_id);
        this['fire']('contact_online', contact_id);
        this['fire']('online_contacts_changed');
        this._contact_update_last_active(contact_id);
      }
      /**
       * @param {!Uint8Array} contact_id
       */,
      'has_online_contact': function(contact_id){
        return this._local_state.online_contacts.has(contact_id);
      }
      /**
       * @param {!Uint8Array} contact_id
       */,
      'del_online_contact': function(contact_id){
        this._local_state.online_contacts['delete'](contact_id);
        this['fire']('contact_offline', contact_id);
        this['fire']('online_contacts_changed');
        this._contact_update_last_active(contact_id);
        this._update_contact_with_pending_messages(contact_id);
      }
      /**
       * @param {!Uint8Array} contact_id
       */,
      _update_contact_with_pending_messages: function(contact_id){
        var i$, ref$, len$, message;
        for (i$ = 0, len$ = (ref$ = this['get_contact_messages'](contact_id)).length; i$ < len$; ++i$) {
          message = ref$[i$];
          if (!message['from'] && !message['date_sent']) {
            this._local_state.contacts_with_pending_messages.add(contact_id);
            return;
          }
        }
        this._local_state.contacts_with_pending_messages['delete'](contact_id);
      }
      /**
       * @param {!Uint8Array} contact_id
       */,
      _contact_update_last_active: function(contact_id){
        var old_contact, new_contact;
        old_contact = this._state['contacts'].get(contact_id);
        new_contact = old_contact['clone']();
        new_contact['last_time_active'] = +new Date;
        this._state['contacts'].set(contact_id, new_contact);
        this['fire']('contact_changed', new_contact, old_contact);
        this['fire']('contacts_changed');
      }
      /**
       * @param {!Uint8Array} contact_id
       *
       * @return {!Array<!Message>}
       */,
      'get_contact_messages': function(contact_id){
        return this._local_state.messages.get(contact_id) || [];
      }
      /**
       * @param {!Uint8Array} contact_id
       *
       * @return {!Array<!Message>}
       */,
      'get_contact_messages_to_be_sent': function(contact_id){
        return this['get_contact_messages'](contact_id).filter(function(message){
          return !message['date_sent'];
        });
      }
      /**
       * @param {!Uint8Array}	contact_id
       * @param {boolean}		from			`true` if message was received and `false` if sent to a friend
       * @param {number}		date_written	When message was written
       * @param {number}		date_sent		When message was sent
       * @param {string} 		text
       *
       * @return {number} Message ID
       */,
      'add_contact_message': function(contact_id, from, date_written, date_sent, text){
        var messages, id, message;
        if (!this._local_state.messages.has(contact_id)) {
          this._local_state.messages.set(contact_id, []);
        }
        messages = this._local_state.messages.get(contact_id);
        id = messages.length ? messages[messages.length - 1]['id'] + 1 : 0;
        message = Message([id, from, date_written, date_sent, text]);
        messages.push(message);
        if (from) {
          this._contact_update_last_active(contact_id);
        } else {
          if (!this['has_online_contact'](contact_id)) {
            this._update_contact_with_pending_messages(contact_id);
          }
        }
        this['fire']('contact_message_added', contact_id, message);
        this['fire']('contact_messages_changed', contact_id);
        id;
      }
      /**
       * @param {!Uint8Array}	contact_id
       * @param {number}		message_id	Message ID
       * @param {number}		date		Date when message was sent
       */,
      'set_contact_message_sent': function(contact_id, message_id, date){
        var messages, i$, message;
        messages = this._local_state.messages.get(contact_id);
        for (i$ = messages.length - 1; i$ >= 0; --i$) {
          message = messages[i$];
          if (message['id'] === message_id) {
            message['date_sent'] = date;
            this._update_contact_with_pending_messages(contact_id);
            break;
          }
        }
      }
      /**
       * @return {!Array<!Object>}
       */,
      'get_secrets': function(){
        return Array.from(this._state['secrets'].values());
      }
      /**
       * @param {!Uint8Array}	secret
       * @param {string}		name
       */,
      'add_secret': function(secret, name){
        var new_secret;
        new_secret = Secret([secret, name]);
        this._state['secrets'].set(new_secret['secret'], new_secret);
        this['fire']('secret_added', new_secret);
        this['fire']('secrets_changed');
      }
      /**
       * @param {!Array<!Secret>} secrets
       */,
      'set_secrets': function(secrets){
        this._state['secrets'] = secrets;
        this['fire']('secrets_changed');
      }
      /**
       * @param {!Uint8Array}	secret
       */,
      'del_secret': function(secret){
        var old_secret;
        old_secret = this._state['secrets'].get(secret);
        if (!old_secret) {
          return;
        }
        this._state['secrets']['delete'](secret);
        this['fire']('secret_deleted', old_secret);
        this['fire']('secrets_changed');
      }
    };
    State.prototype = Object.assign(Object.create(asyncEventer.prototype), State.prototype);
    Object.defineProperty(State.prototype, 'constructor', {
      value: State
    });
    /**
     * Remote secret is used by us to connect to remote friend.
     * Local secret is used by remote friend to connect to us.
     * Old local secret is kept in addition to local secret until it is proven that remote friend updated its remote secret.
     */
    Contact = create_array_object(['id', 'nickname', 'last_time_active', 'last_read_message', 'remote_secret', 'local_secret', 'old_local_secret']);
    ContactRequest = create_array_object(['id', 'name', 'secret_name']);
    Message = create_array_object(['id', 'from', 'date_written', 'date_sent', 'text']);
    Secret = create_array_object(['secret', 'name']);
    return {
      'Contact': Contact,
      'ContactRequest': ContactRequest,
      'Message': Message,
      'Secret': Secret,
      'State': State
      /**
       * @param {string}	name
       * @param {!Object}	initial_state
       *
       * @return {!detoxState}
       */,
      'get_instance': function(name, initial_state){
        if (!(name in global_state)) {
          global_state[name] = State(initial_state);
        }
        return global_state[name];
      }
    };
  }
  define(['@detox/utils', 'async-eventer'], Wrapper);
}).call(this);
