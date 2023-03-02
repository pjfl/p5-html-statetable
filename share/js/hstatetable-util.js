// Package HStateTable.Util
if (!window.HStateTable) window.HStateTable = {};
if (!HStateTable.Util) HStateTable.Util = {};
HStateTable.Util = (function() {
   const _typeof = function(x) {
      if (!x) return;
      if (typeof x == 'object' && Array.isArray(x)) return 'array';
      if (typeof x == 'number') return 'number';
      if (typeof x == 'object') return 'object';
      if (typeof x == 'string') return 'string';
      return;
   };
   class HtmlTiny {
      _tag(tag, attr, content) {
         const el = document.createElement(tag);
         if (_typeof(attr) == 'object') {
            for (const prop of Object.keys(attr)) {
               if (['onchange', 'onclick', 'onsubmit'].includes(prop)) {
                  el.addEventListener(prop.replace(/^on/, ''), attr[prop]);
               }
               else { el[prop] = attr[prop]; }
            }
         }
         else if (_typeof(attr) == 'array') { content = attr; }
         else if (_typeof(attr) == 'string') { content = [attr]; }
         if (content) {
            if (_typeof(content) != 'array') content = [content];
            for (const child of content) {
               if (_typeof(child) == 'number' || _typeof(child) == 'string') {
                  el.append(document.createTextNode(child));
               }
               else { el.append(child); }
            }
         }
         return el;
      }
      a(attr, content)        { return this._tag('a', attr, content); }
      button(attr, content)   { return this._tag('button', attr, content); }
      div(attr, content)      { return this._tag('div', attr, content); }
      form(attr, content)     { return this._tag('form', attr, content); }
      input(attr, content)    { return this._tag('input', attr, content); }
      label(attr, content)    { return this._tag('label', attr, content); };
      li(attr, content)       { return this._tag('li', attr, content); }
      option(attr, content)   { return this._tag('option', attr, content); }
      select(attr, content)   { return this._tag('select', attr, content); }
      span(attr, content)     { return this._tag('span', attr, content); }
      strong(attr, content)   { return this._tag('stong', attr, content); }
      table(attr, content)    { return this._tag('table', attr, content); }
      tbody(attr, content)    { return this._tag('tbody', attr, content); }
      td(attr, content)       { return this._tag('td', attr, content); }
      th(attr, content)       { return this._tag('th', attr, content); }
      tr(attr, content)       { return this._tag('tr', attr, content); }
      thead(attr, content)    { return this._tag('thead', attr, content); }
      ul(attr, content)       { return this._tag('ul', attr, content); }
   }
   const esc = encodeURIComponent;
   return {
      markup: { // A role
         appendValue: function(key, newValue) {
            let existingValue = this[key] || '';
            if (existingValue) existingValue += ' ';
            return existingValue + newValue;
         },
         h: new HtmlTiny(),
         createQueryString: function(obj) {
            if (!obj) return '';
            return Object.entries(obj)
               .filter(([key, val]) => val)
               .reduce((acc, [k, v]) => {
                  return acc.concat(`${esc(k)}=${esc(v)}`);
               }, [])
               .join('&');
         },
         ucfirst: function(s) {
            return s && s[0].toUpperCase() + s.slice(1) || '';
         }
      },
      modifiers: { // Another role
         applyTraits: function(obj, namespace, traits) {
            for (const trait of traits) {
               const initialiser = namespace[trait]['initialise'];
               if (initialiser) initialiser.bind(obj)();
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
            this[method] = function(args) { return around(original, args) };
         }
      }
   };
})();

