// Package HStateTable.Util
if (!window.HStateTable) window.HStateTable = {};
if (!HStateTable.Util) HStateTable.Util = {};
HStateTable.Util = (function() {
   const _typeof = function(x) {
      if (!x) return;
      if ((typeof x == 'object') && (x.nodeType == 1)
          && (typeof x.style == 'object')
          && (typeof x.ownerDocument == 'object')) return 'element';
      if (typeof x == 'object' && Array.isArray(x)) return 'array';
      if (typeof x == 'number') return 'number';
      if (typeof x == 'object') return 'object';
      if (typeof x == 'string') return 'string';
      return;
   };
   const _events = [
      'onchange', 'onclick', 'ondragenter', 'ondragleave',
      'ondragover', 'ondragstart', 'ondrop', 'onsubmit'
   ];
   class HtmlTiny {
      _tag(tag, attr, content) {
         const el = document.createElement(tag);
         if (_typeof(attr) == 'object') {
            for (const prop of Object.keys(attr)) {
               if (_events.includes(prop)) {
                  el.addEventListener(prop.replace(/^on/, ''), attr[prop]);
               }
               else { el[prop] = attr[prop]; }
            }
         }
         else if (_typeof(attr) == 'array') { content = attr; }
         else if (_typeof(attr) == 'element') { content = [attr]; }
         else if (_typeof(attr) == 'string') { content = [attr]; }
         if (content) {
            if (_typeof(content) != 'array') content = [content];
            for (const child of content) {
               if (!_typeof(child)) continue;
               if (_typeof(child) == 'number' || _typeof(child) == 'string') {
                  el.append(document.createTextNode(child));
               }
               else { el.append(child); }
            }
         }
         return el;
      }
      a(attr, content)        { return this._tag('a', attr, content) }
      div(attr, content)      { return this._tag('div', attr, content) }
      figure(attr, content)   { return this._tag('figure', attr, content) }
      form(attr, content)     { return this._tag('form', attr, content) }
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
      text(attr) {
         attr['type'] = 'text';
         return this._tag('input', attr);
      }
   }
   const esc = encodeURIComponent;
   return {
      Markup: { // A role
         h: new HtmlTiny(),
         appendValue: function(obj, key, newValue) {
            let existingValue = obj[key] || '';
            if (existingValue) existingValue += ' ';
            obj[key] = existingValue + newValue;
         },
         createQueryString: function(obj) {
            if (!obj) return '';
            return Object.entries(obj)
               .filter(([key, val]) => val)
               .reduce((acc, [k, v]) => {
                  return acc.concat(`${esc(k)}=${esc(v)}`);
               }, [])
               .join('&');
         },
         reshow: function(container, attribute, obj) {
            if (this[attribute] && container.contains(this[attribute])) {
               container.replaceChild(obj, this[attribute]);
            }
            else { container.append(obj) }
            return obj;
         },
         ucfirst: function(s) {
            return s && s[0].toUpperCase() + s.slice(1) || '';
         }
      },
      Modifiers: { // Another role
         applyTraits: function(obj, namespace, traits, args) {
            for (const trait of traits) {
               if (!namespace[trait]) {
                  throw new Error(`Unknown trait ${namespace} ${trait}`);
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
            const original = this[method].bind(this);
            const around = modifier.bind(this);
            this[method] = function(args1, args2, args3, args4, args5) {
               return around(original, args1, args2, args3, args4, args5);
            };
         }
      }
   };
})();

