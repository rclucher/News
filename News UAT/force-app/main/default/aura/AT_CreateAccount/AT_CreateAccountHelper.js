({
    checkABN: function(component, helper) {
        var abn = component.get("v.abnInput");
        var exempt = component.get("v.abnExempt");
        
        if (!abn) {
            component.set("v.validABN", false);
            component.set("v.loading", false);
            component.set("v.companyName", "");
            component.set("v.abnStatus", "");
        }
        
        if (!exempt) {
            var validABN = helper.ABNValidation(abn);
            
            component.set("v.validABN", validABN);

            if (validABN) {
                component.set("v.loading", true);
                helper.abnSearch(component, helper);
            } else {
                component.set("v.companyName", "");
                component.set("v.abnStatus", "");
                component.set("v.loading", false);
                
                //helper.duplicateCheck(component, helper);
            }
        } else {
            component.set("v.abnInput", "");
            component.set("v.loading", false);
            component.set("v.companyName", "");
            component.set("v.abnStatus", "");
            
           // helper.duplicateCheck(component, helper);
        }
        
        helper.validate(component, helper);
    },
    ABNValidation: function(val) {
        //val = val.replace(/[^0-9]/g, '');
        let weights = new Array(10, 1, 3, 5, 7, 9, 11, 13, 15, 17, 19);
        if (val.length === 11) { 
            let sum = 0;
            weights.forEach(function(weight, position) {
                let digit = val[position] - (position ? 0 : 1);
                sum += weight * digit;
            });
            return sum % 89 == 0;
        }
        return false;
    },
    abnSearch: function(component, helper) {
        var abn = component.get("v.abnInput");
        var recordType = component.get("v.recordTypeId");
        
        console.log(abn);
        
        var search = component.get("c.lookupABN");
        
        search.setParams({abn: abn});
        
        search.setCallback(this, function(response) {
            var state = response.getState();
            
            console.log('State: ' + state);
            
            if (state === "SUCCESS") {
                var data = response.getReturnValue();
                
                component.set("v.companyInfo", response.getReturnValue());
                
                console.log('Response data: ');
                console.log(response.getReturnValue());
                
                component.set("v.companyName", data.name);
                component.set("v.abnStatus", data.status);
                
                component.set("v.loading", false);
            } else if (state === "INCOMPLETE") {
                component.set("v.loading", false);
            } else if (state === "ERROR") {
                component.set("v.loading", false);
            }
            
            //helper.duplicateCheck(component, helper);
        });
        
        console.log('searching');
        $A.enqueueAction(search);
    },
    addressSearch: function(component, helper) {
        var address = component.get("v.address");
        var sourceOfTruth = component.get("v.selectedType");
        
        var search = component.get("c.lookupAddress");
        
        console.log('Checking address: ' + address);
        
        if (address != null) address = address.replace(/[^\w\d\s\/\.\(\),-]+/gi, '');
        
        console.log('Stripped address: ' + address);
        
        search.setParams({address: address, sourceOfTruth: sourceOfTruth});
        
        console.log('Params: ');
        console.log({address: address, sourceOfTruth: sourceOfTruth});
        
        search.setCallback(this, function(response) {
            var state = response.getState();
            
            console.log('Response:');
            console.log(response);
            
            console.log('State: ' + response.getState());
            console.log('Return: ');
            console.log(response.getReturnValue());
                        
            if (state === "SUCCESS") {
                var data = JSON.parse(response.getReturnValue());
                
                component.set("v.loadingAddress", false);
                
                if (data.status == 'ERROR') {
                    console.log('ERROR');
                    console.log(data);
                    
                    component.set("v.showAddresses", false);
                    
                    component.set("v.selectedAddress", null);
                } else {
                    var addresses = new Array();
                    
                    component.set("v.showAddresses", (data.payload.length > 0));
                    
                    component.set("v.selectedAddress", null);
                    
                    component.set("v.addresses", data.payload);
                }
            } else if (state === "INCOMPLETE") {
                component.set("v.loadingAddress", false);
            } else if (state === "ERROR") {
                component.set("v.loadingAddress", false);
            }
        });
        
        $A.enqueueAction(search);
    },
    validate: function(component, helper) {
        var accountName = component.get("v.accountName");
        var firstName = component.get("v.firstName");
        var lastName = component.get("v.lastName");
        var sourceOfTruth = component.get("v.selectedType");
        var validABN = component.get("v.validABN");
        var abnExempt = component.get("v.abnExempt");
        var showNames = component.get("v.showNames");
        var valid;
        var recordTypes = component.get("v.recordTypes");
        var recordTypeId = component.get("v.recordTypeId");
        //var showNames;
        console.log(recordTypes);
        console.log(recordTypeId);
        
                
                    valid = ((lastName) && (abnExempt || validABN));   

            
                        // Account name is always required
                	valid = ((accountName || (lastName && firstName)) && (abnExempt || validABN));
                        // Valid ABN is required if australian address
                        //(((sourceOfTruth == 'AUPAF') || (sourceOfTruth == 'GNAF')) && ((validABN == true) || )));
            
        
        console.log('Valid: ' + valid);
        
        component.set("v.valid", valid);
    },
    createAccount: function(component, helper) {
    	var createAccountEvent = $A.get("e.force:createRecord");
        
        var abn = component.get("v.abnInput");
        var exempt = component.get("v.abnExempt");
        var timestamp = ($A.localizationService.formatDate(new Date(), "YYYY-MM-DD"));
        var firstName = component.get("v.firstName");
        var lastName = component.get("v.lastName");
        var accName = component.get("v.accountName");
        var name;
        console.log(component.get("v.firstName"));
        console.log(component.get("v.lastName"));
        console.log(component.get("v.accountName"));
        if(accName){
            name = accName;
        }else{
            name = firstName + lastName;
        }
        console.log(name);
        if (exempt) {
            timestamp = "";
            abn = "";
        }
        
        var exemptReason = null;
        
        switch (component.get("v.selectedExempt")) {
            case "PP":  exemptReason = "Private Party (less than $75k turnover)"; break;
            case "NFP": exemptReason = "Not for Profit"; break;
            case "OS":  exemptReason = "Overseas Client"; break;
        }
        
        var recordTypeID = component.get("v.recordTypeId");
        var accountName = component.get("v.accountName");
        var firstName = component.get("v.firstName");
        var lastName = component.get("v.lastName");
        /*
        16-10-2018: Mohsin Ali - Fixed the Commenting on Name. Removed the comment. Refer to Jira: NR-1671
        */
        
        createAccountEvent.setParams({
            "entityApiName": "Account",
            "defaultFieldValues": {
                'RecordTypeId': recordTypeID,
                'Name': accountName,
                'FirstName': firstName,
                'LastName': lastName,
                'ABN_Exempt__c': exempt,
                'ABN_Exempt_Reason__c': exemptReason,
                'AccountNumber': abn,
                'Registered_Name__c': component.get("v.companyName"),
                'ABN_Status__c': component.get("v.abnStatus"),
                'ABN_Validation__c': timestamp,
                'BillingStreet': component.get("v.street"),
                'BillingCity': component.get("v.city"),
                'BillingPostalCode': component.get("v.postcode"),
                'BillingState': component.get("v.state"),
                'BillingCountry': component.get("v.country"),
                'DPID_Primary_Address__c': component.get("v.dpid"),
                'datasan__Billing_Address_DPID__c': component.get("v.dpid")
            }
        });
        
        createAccountEvent.fire();
	}/*,
    duplicateCheck: function(component, helper) {
        var name = component.get("v.accountName");
        var firstName = component.get("v.firstName");
        var lastName = component.get("v.lastName");
        var abn = component.get("v.abnInput");
        var street = component.get("v.street");
        var city = component.get("v.city");
        var postcode = component.get("v.postcode");
        var state = component.get("v.state");
        var country = component.get("v.country");
        
        console.log('dupcheck');
        
        var check = component.get("c.duplicateCheck");
        
        check.setParams({name: name,
                          firstName: firstName,
                          lastName: lastName,
                          abn: abn,
                          street: street,
                          city: city,
                          postcode: postcode,
                          state: state,
                          country: country});
        
        check.setCallback(this, function(response) {
            var state = response.getState();
            
            console.log('State: ' + state);
            
            if (state === "SUCCESS") {
                var data = response.getReturnValue();
                
                component.set("v.companyInfo", response.getReturnValue());
                
                console.log('Response data: ');
                console.log(response.getReturnValue());
                
                component.set("v.duplicates", data.length > 0);
                component.set("v.duplicateData", data);
            } else if (state === "INCOMPLETE") {
                component.set("v.loading", false);
            } else if (state === "ERROR") {
                component.set("v.loading", false);
            }
        });
        
        console.log('checking'); 
        $A.enqueueAction(check);
    }*/
})