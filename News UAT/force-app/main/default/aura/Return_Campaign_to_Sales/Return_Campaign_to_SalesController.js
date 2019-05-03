({
   doInit: function(component, event, helper){
      helper.initClass(component , event);
      
   },

   openModel: function(component, event, helper) {
      component.set("v.isOpen", true);
   },
 
   closeModel: function(component, event, helper) {
       component.set("v.isOpen", false);
       var close = $A.get("e.force:closeQuickAction"); 
       close.fire(); 

   },
 
   doUpdate: function(component, event, helper) {
      
      //NXRIII-347 Begins
      
      //getting the Order information
      var strFailureNotes = component.get('v.objClassController');
      //Validation
      if($A.util.isEmpty(strFailureNotes) || $A.util.isUndefined(strFailureNotes)){
         var a = component.get('c.closeModel');
        $A.enqueueAction(a);
         alert('Notes are mandatory when returning a campaign to sales. Please enter reason for return in Notes for Failure field - this will be visible to the opportunity owner');
         return;
      }
      //NXRIII-347 Ends
      component.set("v.isOpen", false);
       helper.updateStatus(component , event);
      
   }
    
})