// Package WCom.Table.RowTrait.Active
WCom.Table.RowTrait.Active = (function() {
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
// Package WCom.Table.RowTrait.HighlightRow
WCom.Table.RowTrait.HighlightRow = (function() {
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
