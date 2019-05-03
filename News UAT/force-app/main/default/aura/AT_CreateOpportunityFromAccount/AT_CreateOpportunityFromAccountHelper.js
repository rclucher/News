({
	newOpportunity: function(component, helper) {
        var createEvent = $A.get("e.force:createRecord");
        
        createEvent.setParams({
            "entityApiName": component.get("v.objectName"),
            "defaultFieldValues": {
                RecordTypeId: component.get("v.recordTypeId"),
                AccountId: component.get("v.recordId"),
                Industry_Code__c: component.get("v.loadedAccount.Industry_Code__c"),
                Revenue_Group__c: component.get("v.loadedAccount.Revenue_Group__c"),
            }
        });
        
        createEvent.fire();
        
        $A.get("e.force:closeQuickAction").fire();
	}
})