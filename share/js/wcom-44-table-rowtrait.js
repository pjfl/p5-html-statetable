/** -*- coding: utf-8; -*-
    @file HTML StateTable - Row Traits
    @classdesc Traits applied to the row object
    @author pjfl@cpan.org (Peter Flanigan)
    @version 0.2.25
*/
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
