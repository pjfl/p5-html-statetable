// Package HStateTable.RowTrait.Active
HStateTable.RowTrait.Active = (function() {
   return {
      around: {
         render: function(orig, attr) {
            attr ||= {};
            if (this.result['_inactive']) {
               attr.className = attr.appendValue('className', 'inactive');
            }
            return orig(attr);
         }
      }
   };
})();
// Package HStateTable.RowTrait.HighlightRow
HStateTable.RowTrait.HighlightRow = (function() {
   return {
      around: {
         render: function(orig, attr) {
            attr ||= {};
            if (this.result['_highlight']) {
               attr.className = attr.appendValue('className', 'highlight');
            }
            return orig(attr);
         }
      }
   };
})();
