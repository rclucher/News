({
	
    doInit : function(component, event, helper) {
        var action = component.get("c.getIconName");
        action.setParams({ "sObjectName" : component.get("v.sObjectName") });
        action.setCallback(this, function(response) {
           component.set("v.iconName", response.getReturnValue() );
           helper.getAllAccessibleAccount(component, event, helper);
        });
        $A.enqueueAction(action);     
        
    },
    refreshView : function(component, event, helper){
      
       var contactId = event.getParam("ParentRecordId");
       console.log(contactId);
       component.set("v.contactId",contactId);
       helper.fetchMyAccounts(component, event, helper); 
    },
    searchAccounts: function (component, event, helper) {
        var isEnterKey = event.keyCode === 13;
        var queryTerm = component.find('enter-search').get('v.value');
        if (isEnterKey) {
            var searchKeyword = component.find('enter-search').get('v.value');
        var modalBody;
        $A.createComponent("c:NXX2_ContactListPage", 
        {searchKeyword : searchKeyword,refreshParentPage: component.getReference("c.refreshView")},
           function(content, status) {
               if (status === "SUCCESS") {
                   modalBody = content;
                   component.find('overlayLib').showCustomModal({
                       header: "Contacts",
                       body: modalBody, 
                       showCloseButton: true,
                       cssClass: "custom-modal-for-social-ad",
                       closeCallback: function() {
                          // alert('You closed the alert!');
                       }
                   })
               }                               
           });
       }
    }
})