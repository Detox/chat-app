// Generated by LiveScript 1.5.0
/**
 * @package Detox chat app
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
(function(){
  var IN_APP, ref$, desktop_notification_permission_requested, x$, slice$ = [].slice, arrayFrom$ = Array.from || function(x){return slice$.call(x);};
  IN_APP = location.search === '?home';
  /**
   * Force passive listeners on in Polymer
   */
  Polymer.setPassiveTouchGestures(true);
  /**
   * Register service worker
   */
  if ('serviceWorker' in navigator && window.detox_sw_path) {
    require(['@detox/chat']).then(function(arg$){
      var detoxChat, this$ = this;
      detoxChat = arg$[0];
      detoxChat.ready(function(){
        navigator.serviceWorker.register(detox_sw_path).then(function(registration){
          registration.onupdatefound = function(){
            var installingWorker;
            installingWorker = registration.installing;
            installingWorker.onstatechange = function(){
              switch (installingWorker.state) {
              case 'installed':
                if (navigator.serviceWorker.controller) {
                  if (IN_APP) {
                    detox_chat_app.notify_success('Application was updated in background and new version ready to be used, restart to enjoy it', 10);
                  } else {
                    detox_chat_app.notify_success('Website was updated in background and new version ready to be used, refresh page to enjoy it', 10);
                  }
                } else {
                  if (IN_APP) {
                    detox_chat_app.notify_success('Application is ready to work offline', 10);
                  } else {
                    detox_chat_app.notify_success('Website is ready to work offline', 10);
                  }
                }
                break;
              case 'redundant':
                console.error('The installing service worker became redundant');
              }
            };
          };
          window.detox_service_worker_registration = registration;
        })['catch'](function(e){
          console.error('Error during service worker registration:', e);
        });
      });
    });
  }
  /**
   * Requesting persistent storage, so that data will not be lost unexpectedly under storage pressure
   */
  if ((ref$ = navigator.storage) != null && ref$.persist) {
    navigator.storage.persisted().then(function(persistent){
      if (!persistent) {
        console.info('Persistent storage is not yet granted, requesting...');
        navigator.storage.persist().then(function(granted){
          if (granted) {
            console.info('Persistent storage granted');
          } else {
            console.warn('Persistent storage denied, data may be lost under storage pressure');
          }
        });
      }
    });
  } else {
    console.warn('Persistent storage not supported, data may be lost under storage pressure');
  }
  desktop_notification_permission_requested = false;
  /**
   * @param {string}		status
   * @param {string}		title
   * @param {string=}		details
   * @param {number=}		timeout
   * @param {!Function}	onclick
   */
  function page_notification(status, title, details, timeout, onclick){
    var body, notification;
    body = document.createElement('div');
    if (details) {
      body.innerHTML = '<b></b><br>';
      body.querySelector('b').textContent = title;
      body.insertAdjacentText('beforeend', details);
    } else {
      body.insertAdjacentText('beforeend', title);
    }
    notification = csw.functions.notify(body, status, 'right', timeout);
    if (onclick) {
      notification.addEventListener('click', onclick);
    }
  }
  /**
   * @param {string}		title
   * @param {string=}		details
   * @param {number=}		timeout
   * @param {!Function}	onclick
   */
  function desktop_notification(title, details, timeout, onclick){
    var notification;
    notification = new Notification(title, {
      body: details
    });
    if (onclick) {
      notification.addEventListener('click', onclick);
    }
    if (timeout) {
      setTimeout(function(){
        notification.close();
      }, 1000 * timeout);
    }
  }
  /**
   * @param {string}	status
   * @param {string}	title
   * @param {string=}	details
   * @param {string=}	timeout
   *
   * @return {!Promise}
   */
  function notify(status, title, details, timeout){
    return new Promise(function(resolve){
      var desktop_notification_permission_requested, message, x$;
      if (typeof details === 'number') {
        timeout = details;
        details = '';
      }
      if (document.hasFocus() || !Notification || Notification.permission === 'denied') {
        page_notification(status, title, details, timeout, resolve);
      } else if (Notification.permission === 'default') {
        if (!desktop_notification_permission_requested) {
          desktop_notification_permission_requested = true;
          if (IN_APP) {
            message = "Application tried to show you a system notification while was inactive, but you have to grant permission for that first, do that after clicking on this notification";
          } else {
            message = "Website tried to show you a desktop notification while was inactive, but you have to grant permission for that first, do that after clicking on this notification";
          }
          x$ = csw.functions.notify(message, 'warning', 'right');
          x$.addEventListener('click', function(){
            Notification.requestPermission().then(function(permission){
              switch (permission) {
              case 'granted':
                csw.functions.notify('You will no longer miss important notifications 😉', 'success', 'right', 3);
                break;
              case 'denied':
                csw.functions.notify('In case you change your mind, desktop notifications can be re-enabled in browser settings 😉', 'success', 'right', 5);
              }
            });
          });
        }
        page_notification(status, title, details, timeout, resolve);
      } else {
        desktop_notification(title, details, timeout, resolve);
      }
    });
  }
  x$ = window.detox_chat_app || (window.detox_chat_app = {});
  x$.notify_error = function(){
    return notify.apply(null, ['error'].concat(arrayFrom$(arguments)));
  };
  x$.notify = function(){
    return notify.apply(null, [''].concat(arrayFrom$(arguments)));
  };
  x$.notify_success = function(){
    return notify.apply(null, ['success'].concat(arrayFrom$(arguments)));
  };
  x$.notify_warning = function(){
    return notify.apply(null, ['warning'].concat(arrayFrom$(arguments)));
  };
  x$.simple_modal = function(content){
    var current_time, x$, modal;
    current_time = +new Date;
    x$ = modal = csw.functions.simple_modal(content);
    x$.addEventListener('close', function(){
      if (deepEq$(history.state, current_time, '===')) {
        history.back();
      }
    });
    history.pushState(current_time, '', '#modal');
    window.addEventListener('popstate', function(){
      modal.close();
    }, {
      once: true
    });
    return modal;
  };
  function deepEq$(x, y, type){
    var toString = {}.toString, hasOwnProperty = {}.hasOwnProperty,
        has = function (obj, key) { return hasOwnProperty.call(obj, key); };
    var first = true;
    return eq(x, y, []);
    function eq(a, b, stack) {
      var className, length, size, result, alength, blength, r, key, ref, sizeB;
      if (a == null || b == null) { return a === b; }
      if (a.__placeholder__ || b.__placeholder__) { return true; }
      if (a === b) { return a !== 0 || 1 / a == 1 / b; }
      className = toString.call(a);
      if (toString.call(b) != className) { return false; }
      switch (className) {
        case '[object String]': return a == String(b);
        case '[object Number]':
          return a != +a ? b != +b : (a == 0 ? 1 / a == 1 / b : a == +b);
        case '[object Date]':
        case '[object Boolean]':
          return +a == +b;
        case '[object RegExp]':
          return a.source == b.source &&
                 a.global == b.global &&
                 a.multiline == b.multiline &&
                 a.ignoreCase == b.ignoreCase;
      }
      if (typeof a != 'object' || typeof b != 'object') { return false; }
      length = stack.length;
      while (length--) { if (stack[length] == a) { return true; } }
      stack.push(a);
      size = 0;
      result = true;
      if (className == '[object Array]') {
        alength = a.length;
        blength = b.length;
        if (first) {
          switch (type) {
          case '===': result = alength === blength; break;
          case '<==': result = alength <= blength; break;
          case '<<=': result = alength < blength; break;
          }
          size = alength;
          first = false;
        } else {
          result = alength === blength;
          size = alength;
        }
        if (result) {
          while (size--) {
            if (!(result = size in a == size in b && eq(a[size], b[size], stack))){ break; }
          }
        }
      } else {
        if ('constructor' in a != 'constructor' in b || a.constructor != b.constructor) {
          return false;
        }
        for (key in a) {
          if (has(a, key)) {
            size++;
            if (!(result = has(b, key) && eq(a[key], b[key], stack))) { break; }
          }
        }
        if (result) {
          sizeB = 0;
          for (key in b) {
            if (has(b, key)) { ++sizeB; }
          }
          if (first) {
            if (type === '<<=') {
              result = size < sizeB;
            } else if (type === '<==') {
              result = size <= sizeB
            } else {
              result = size === sizeB;
            }
          } else {
            first = false;
            result = size === sizeB;
          }
        }
      }
      stack.pop();
      return result;
    }
  }
}).call(this);
