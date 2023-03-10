// Package HStateTable.RowTrait.Active
HStateTable.RowTrait.Active = (function() {
   return {
      around: {
         render: function(orig, attr) {
            attr ||= {};
            if (this.result['_inactive']) {
               this.appendValue(attr, 'className', 'inactive');
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
               this.appendValue(attr, 'className', 'highlight');
            }
            return orig(attr);
         }
      }
   };
})();
