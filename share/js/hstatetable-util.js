// Package HStateTable.Util
if (!window.HStateTable) window.HStateTable = {};
if (!HStateTable.Util) HStateTable.Util = {};
HStateTable.Util = (function() {
   class HtmlTiny {
      _tag(tag, attr, content) {
         const el = document.createElement(tag);
         if (attr && typeof attr == 'object') {
            for (const prop of Object.keys(attr)) {
               if (prop == 'onchange' || prop == 'onclick'
                   || prop == 'onsubmit') {
                  el.addEventListener(prop.replace(/^on/, ''), attr[prop]);
               }
               else { el[prop] = attr[prop]; }
            }
         }
         else if (attr && typeof attr == 'array') { content = attr; }
         else if (attr && typeof attr == 'string') { content = [attr]; }
         if (content) {
            if (typeof content != 'array') content = [content];
            for (const child of content) {
               if (typeof child == 'string') {
                  el.append(document.createTextNode(child));
               }
               else { el.append(child) }
            }
         }
         return el;
      }
      a(attr, content)      { return this._tag('a', attr, content); }
      button(attr, content) { return this._tag('button', attr, content); }
      div(attr, content)    { return this._tag('div', attr, content); }
      form(attr, content)   { return this._tag('form', attr, content); }
      input(attr, content)  { return this._tag('input', attr, content); }
      li(attr, content)     { return this._tag('li', attr, content); }
      option(attr, content) { return this._tag('option', attr, content); }
      select(attr, content) { return this._tag('select', attr, content); }
      span(attr, content)   { return this._tag('span', attr, content); }
      strong(attr, content) { return this._tag('stong', attr, content); }
      table(attr, content)  { return this._tag('table', attr, content); }
      tbody(attr, content)  { return this._tag('tbody', attr, content); }
      td(attr, content)     { return this._tag('td', attr, content); }
      th(attr, content)     { return this._tag('th', attr, content); }
      tr(attr, content)     { return this._tag('tr', attr, content); }
      thead(attr, content)  { return this._tag('thead', attr, content); }
      ul(attr, content)     { return this._tag('ul', attr, content); }
   }
   return {
      markup: { // A role
         appendValue: function(key, newValue) {
            let existingValue = this[key] || '';
            if (existingValue) existingValue += ' ';
            return existingValue + newValue;
         },
         h: new HtmlTiny()
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

