/** -*- coding: utf-8; -*-
    @file HTML StateTable - Row Traits
    @classdesc Traits applied to the row object
    @author pjfl@cpan.org (Peter Flanigan)
    @version 0.2.35
*/
WCom.Table.RowTrait.Active = (function() {
   /** @mixin TableRowTrait/Active
       @desc Active row trait
   */
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
   /** @mixin TableRowTrait/HighlightRow
       @desc Highlight row trait
   */
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
