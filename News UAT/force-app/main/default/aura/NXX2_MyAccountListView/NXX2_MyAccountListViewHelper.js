({
    getAllAccessibleAccount:function(component, event, helper){
        
        var accountAction = component.get("c.getAccountsListAccessibleToCustomer"); 
        accountAction.setCallback(this, function(accountListResult) {
                var state = accountListResult.getState();
                if(state == 'SUCCESS') {
                    var rawData = accountListResult.getReturnValue();
                    component.set("v.accountList", rawData.accountList);
                    component.set("v.isUserHasSearchAccessToContact", rawData.isUserHasSearchAccessToContact);
                }else{
                    var errors = accountListResult.getError(); 
                    if (errors) {
                       
                    }
                }
            });
            $A.enqueueAction(accountAction); 
    },
    fetchContactDetail : function(component, event, helper){
            var userDetailsAction = component.get("c.getLoggedInUserContact"); 
            userDetailsAction.setCallback(this, function(userDetailResult) {
                var state = userDetailResult.getState();
                if(state == 'SUCCESS') {
                    var rawData = userDetailResult.getReturnValue();
                    component.set("v.contactId", userDetailResult.getReturnValue());
                    helper.fetchMyAccounts(component, event, helper); 
                }else{
                    var errors = userDetailResult.getError();
                    if (errors) {
                       
                    }
                }
            });
            $A.enqueueAction(userDetailsAction); 
      
    },
    fetchMyAccounts : function(component, event, helper) {
        var action = component.get("c.getAllAccessibleAccount"); 
        action.setParams({
            contactId : component.get("v.contactId")
         });
        action.setCallback(this, function(accountListResult) {
            var state = accountListResult.getState();
            if(state == 'SUCCESS') {
                //component.set("v.accountList", accountListResult.getReturnValue());
                var rawData = accountListResult.getReturnValue();
                    component.set("v.accountList", rawData.accountList);
                    component.set("v.isUserHasSearchAccessToContact", rawData.isUserHasSearchAccessToContact);
                
                var loadCustomerTaskRelatedToSObject = $A.get("e.c:NXX2_LoadCustomerTaskRelatedToSObjectEvent");
                loadCustomerTaskRelatedToSObject.setParams({ 
                "parentRecordId" : component.get("v.contactId")
                });
                loadCustomerTaskRelatedToSObject.fire();

                console.log('accountList' + component.get("v.accountList"));
            }else{
                var errors = accountListResult.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                    }
                }
            }
            });
          $A.enqueueAction(action); 
    },
    openContactListPage : function(component, event, helper){
        
    }
})