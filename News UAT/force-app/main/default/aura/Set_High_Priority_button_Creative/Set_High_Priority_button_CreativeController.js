({
   openModel: function(component, event, helper) {
      component.set("v.isOpen", true);
   },
   
    closeModel: function(component, event, helper) {
       component.set("v.isOpen", false);
       var close = $A.get("e.force:closeQuickAction"); 
       close.fire(); 

   },
    
    doUpdate: function(component, event, helper) {
       
      component.set("v.isOpen", false);
       helper.showMsg(component , event);
      
   }
    
})