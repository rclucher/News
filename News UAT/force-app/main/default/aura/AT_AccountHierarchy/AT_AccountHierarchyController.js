({
	doInit: function(component, event, helper) {
		var recordId = component.get("v.recordId");
        
        var action = component.get("c.getAccountHierarchy");
            
        action.setParams({
            recordID: recordId
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            
            if (state == "SUCCESS"){
                var hierarchy = response.getReturnValue();
                
                helper.renameItemsToChildren(helper, hierarchy.records);
                console.log('Hierarchy:');
                console.log(hierarchy);
                
                var type = hierarchy.type;
                
                component.set("v.type", type);
                
                if (type == "consortium") {
                    component.set("v.accounts", hierarchy.records);
                    
                    var columns = [
                        {
                            type: 'url',
                            fieldName: 'href',
                            label: 'Relationship & Client',
                            actions: {},
                            typeAttributes: {
                                label: { fieldName: 'label' }
                            }
                        },
                        {
                            type: 'url',
                            fieldName: 'ownerHREF',
                            label: 'Owner',
                            actions: {},
                            typeAttributes: {
                                label: { fieldName: 'ownerName' }
                            }
                        }
                    ];
                    
                    component.set('v.columns', columns);
                } else if (type == "agency") {
                    console.log('Showing agency');
                    
                    component.set("v.consortium", {id: hierarchy.consortiumID, name: hierarchy.consortiumName});
                    
                    component.set("v.accounts", hierarchy.records);
                    
                    var columns = [
                        {
                            type: 'url',
                            fieldName: 'href',
                            label: 'Relationship & Client',
                            actions: {},
                            typeAttributes: {
                                label: { fieldName: 'label' }
                            }
                        },
                        {
                            type: 'url',
                            fieldName: 'ownerHREF',
                            label: 'Owner',
                            actions: {},
                            typeAttributes: {
                                label: { fieldName: 'ownerName' }
                            }
                        }
                    ];
                    
                    component.set('v.columns', columns);
                } else if (type == "client") {
                    component.set("v.accounts", hierarchy.records);
                    
                    var columns = [
                    {
                        type: 'url',
                        fieldName: 'href',
                        label: 'Agency',
                        actions: {},
                        typeAttributes: {
                            label: { fieldName: 'label' }
                        }
                    },
                    {
                        type: 'text',
                        fieldName: 'relationship',
                        label: 'Relationship',
                        actions: {}
                    },
                    {
                        type: 'currency',
                        fieldName: 'spend',
                        label: 'Current FY Spend',
                        actions: {}
                    },
                    {
                        type: 'url',
                        fieldName: 'ownerHREF',
                        label: 'Owner',
                        actions: {},
                        typeAttributes: {
                            label: { fieldName: 'ownerName' }
                        }
                    }
                ];
                
                component.set('v.columns', columns);
                }
                
                component.set("v.loading", false);
            } else if (state == "ERROR"){
                var errors = response.getError();
                
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
                
                component.set("v.loading", false);
            }
        });
        
        $A.enqueueAction(action);
	}
})