// Package HStateTable.Util
if (!window.HStateTable) window.HStateTable = {};
if (!HStateTable.Util) HStateTable.Util = {};
HStateTable.Util = (function() {
   const _typeof = function(x) {
      if (!x) return;
      const type = typeof x;
      if ((type == 'object') && (x.nodeType == 1)
          && (typeof x.style == 'object')
          && (typeof x.ownerDocument == 'object')) return 'element';
      if (type == 'object' && Array.isArray(x)) return 'array';
      return type;
   };
   const _events = [
      'onchange', 'onclick', 'ondragenter', 'ondragleave',
      'ondragover', 'ondragstart', 'ondrop', 'onsubmit'
   ];
   class Bitch {
      _newHeaders() {
         const headers = new Headers();
         headers.set('X-Requested-With', 'XMLHttpRequest');
         return headers;
      }
      _setHeaders(options) {
         if (!options.headers) options.headers = this._newHeaders();
         if (!(options.headers instanceof Headers)) {
            const headers = options.headers;
            options.headers = this._newHeaders();
            for (const [k, v] of Object.entries(headers))
               options.headers.set(k, v);
         }
      }
      async blows(url, options) {
         options ||= {};
         let want = options.response || 'text'; delete options.response;
         this._setHeaders(options);
         if (options.form) {
            options.headers.set(
               'Content-Type', 'application/x-www-form-urlencoded'
            );
            const form = options.form; delete options.form;
            const params = new URLSearchParams(new FormData(form));
            options.body = params.toString();
         }
         if (options.json) {
            options.headers.set('Content-Type', 'application/json');
            options.body = options.json; delete options.json;
            want = 'object';
         }
         options.method ||= 'POST';
         if (options.method == 'POST') {
            options.cache ||= 'no-store';
            options.credentials ||= 'same-origin';
         }
         const response = await fetch(url, options);
         if (!response.ok) {
            throw new Error(`HTTP error! Status: ${response.statusText}`);
         }
         if (response.headers.get('location')) return {
            location: response.headers.get('location'), status: 302
         };
         if (want == 'object') return {
            object: await response.json(), status: response.status
         };
         if (want == 'text') return {
            status: response.status, text: await response.text()
         };
         return { response: response };
      }
      async sucks(url, options) {
         options ||= {};
         const want = options.response || 'object'; delete options.response;
         this._setHeaders(options);
         options.method ||= 'GET';
         const response = await fetch(url, options);
         if (!response.ok) {
            if (want == 'object') {
               console.warn(`HTTP error! Status: ${response.statusText}`);
               return { object: false, status: response.status };
            }
            throw new Error(`HTTP error! Status: ${response.statusText}`);
         }
         const headers = response.headers;
         if (headers.get('location')) return {
            location: headers.get('location'), status: 302
         };
         if (want == 'blob') {
            const key = 'content-disposition';
            const filename = headers.get(key).split('filename=')[1];
            const blob = await response.blob();
            return { blob: blob, filename: filename, status: response.status };
         }
         if (want == 'object') return {
            object: await response.json(), status: response.status
         };
         if (want == 'text') return {
            status: response.status,
            text: await new Response(await response.blob()).text()
         };
         return { response: response };
      }
   }
   class HtmlTiny {
      _tag(tag, attr, content) {
         const el = document.createElement(tag);
         const type = _typeof(attr);
         if (type == 'object') {
            for (const prop of Object.keys(attr)) {
               if (_events.includes(prop)) {
                  el.addEventListener(prop.replace(/^on/, ''), attr[prop]);
               }
               else { el[prop] = attr[prop]; }
            }
         }
         else if (type == 'array')   { content = attr; }
         else if (type == 'element') { content = [attr]; }
         else if (type == 'string')  { content = [attr]; }
         if (!content) return el;
         if (_typeof(content) != 'array') content = [content];
         for (const child of content) {
            const childType = _typeof(child);
            if (!childType) continue;
            if (childType == 'number' || childType == 'string') {
               el.append(document.createTextNode(child));
            }
            else { el.append(child); }
         }
         return el;
      }
      a(attr, content)        { return this._tag('a', attr, content) }
      div(attr, content)      { return this._tag('div', attr, content) }
      figure(attr, content)   { return this._tag('figure', attr, content) }
      form(attr, content)     { return this._tag('form', attr, content) }
      img(attr)               { return this._tag('img', attr) }
      input(attr, content)    { return this._tag('input', attr, content) }
      label(attr, content)    { return this._tag('label', attr, content) }
      li(attr, content)       { return this._tag('li', attr, content) }
      option(attr, content)   { return this._tag('option', attr, content) }
      select(attr, content)   { return this._tag('select', attr, content) }
      span(attr, content)     { return this._tag('span', attr, content) }
      strong(attr, content)   { return this._tag('strong', attr, content) }
      table(attr, content)    { return this._tag('table', attr, content) }
      tbody(attr, content)    { return this._tag('tbody', attr, content) }
      td(attr, content)       { return this._tag('td', attr, content) }
      th(attr, content)       { return this._tag('th', attr, content) }
      tr(attr, content)       { return this._tag('tr', attr, content) }
      thead(attr, content)    { return this._tag('thead', attr, content) }
      ul(attr, content)       { return this._tag('ul', attr, content) }
      button(attr, content) {
         if (_typeof(attr) == 'object') attr['type'] ||= 'submit';
         else {
            content = attr;
            attr = { type: 'submit' };
         }
         return this._tag('button', attr, content);
      }
      checkbox(attr) {
         attr['type'] = 'checkbox';
         return this._tag('input', attr);
      }
      hidden(attr) {
         attr['type'] = 'hidden';
         return this._tag('input', attr);
      }
      text(attr) {
         attr['type'] = 'text';
         return this._tag('input', attr);
      }
   }
   const esc = encodeURIComponent;
   const ucfirst = function(s) {
      return s && s[0].toUpperCase() + s.slice(1) || '';
   };
   return {
      Markup: { // A role
         appendValue: function(obj, key, newValue) {
            let existingValue = obj[key] || '';
            if (existingValue) existingValue += ' ';
            obj[key] = existingValue + newValue;
         },
         bitch: new Bitch(),
         capitalise: function(s) {
            const words = [];
            for (const word of s.split(' ')) words.push(ucfirst(word));
            return words.join(' ');
         },
         display: function(container, attribute, obj) {
            if (this[attribute] && container.contains(this[attribute])) {
               container.replaceChild(obj, this[attribute]);
            }
            else { container.append(obj) }
            return obj;
         },
         h: new HtmlTiny(),
         ucfirst: ucfirst
      },
      Modifiers: { // Another role
         applyTraits: function(obj, namespace, traits, args) {
            for (const trait of traits) {
               if (!namespace[trait]) {
                  throw new Error(namespace + `: Unknown trait ${trait}`);
               }
               const initialiser = namespace[trait]['initialise'];
               if (initialiser) initialiser.bind(obj)(args);
               for (const method of Object.keys(namespace[trait].around)) {
                  obj.around(method, namespace[trait].around[method]);
               }
            }
         },
         around: function(method, modifier) {
            if (!this[method]) {
               throw new Error(`Around no method: ${method}`);
            }
            const orig = this[method].bind(this);
            const around = modifier.bind(this);
            this[method] = function(args1, args2, args3, args4, args5) {
               return around(orig, args1, args2, args3, args4, args5);
            };
         },
         resetModifiers: function(methods) {
            for (const method of Object.keys(methods)) delete methods[method];
         }
      }
   };
})();

