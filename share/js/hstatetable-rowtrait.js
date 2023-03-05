// Package HStateTable.RowTrait.Active
HStateTable.RowTrait.Active = (function() {
   return {
      around: {
         render: function(orig, attr) {
            if (!attr) attr = {};
            if (this.result['_inactive']) {
               attr.className
                  = this.appendValue.bind(attr)('className', 'inactive');
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
            if (!attr) attr = {};
            if (this.result['_highlight']) {
               attr.className
                  = this.appendValue.bind(attr)('className', 'highlight');
            }
            return orig(attr);
         }
      }
   };
})();
