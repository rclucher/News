({
	onInit: function(component, event, helper) {
		helper.getSpending(component);
        
        var spendingColumns = [
            {"label": "Account Name", "fieldName": "Link", "type": "url", "typeAttributes": {"label": {"fieldName": "Name"}}, "actions": {}},
            {"label": "Previous FY", "fieldName": "PreviousFY", "type": "currency", "actions": {}},
            {"label": "Current FY", "fieldName": "CurrentFY", "type": "currency", "actions": {}}
        ];
        
        component.set("v.spendingColumns", spendingColumns);
	}
})