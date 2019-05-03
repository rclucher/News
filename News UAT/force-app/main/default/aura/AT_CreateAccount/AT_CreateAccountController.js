({
    doInit: function(component, event, helper) {
        component.set("v.selectedAddress", null);
        
        var getRecordTypes = component.get("c.getRecordTypes");
        
        getRecordTypes.setCallback(this, function(response) {
            var state = response.getState();
            
            console.log('State: ' + state);
            
            if (state === "SUCCESS") {
                var data = response.getReturnValue();
                
                component.set("v.recordTypes", data);
                
                for (var i = 0; i < data.length; i++) {
                    if (data[i].isDefault) {
                        component.set("v.recordTypeId", data[i].id);
                    }
                }
            } else if (state === "INCOMPLETE") {
            } else if (state === "ERROR") {
            }
        });
        
        $A.enqueueAction(getRecordTypes);
        
        var addressTypes = [
            {"value": "AUPAF", "text": "Australia"},
            {"value": "NZPAF", "text": "New Zealand"},
            {"value": "OS", "text": "Other"}
        ];
        
        component.set("v.addressTypes", addressTypes);
        component.set("v.selectedType", "AUPAF");
        
        var duplicateColumns = [
            {"label": "Account Name", "fieldName": "Link", "type": "url", "typeAttributes": {"label": {"fieldName": "Name"}}, "actions": {}},
            {"label": "ABN", "fieldName": "ABN", "type": "text", "actions": {}},
            {"label": "Address", "fieldName:": "Address", "type": "text", "actions": {}}
        ];
        
        component.set("v.duplicateColumns", duplicateColumns);
        
        var exemptReasons = [
            {"value": "RQ", "text": "No"},
            {"value": "PP", "text": "Yes - Private Party (less than $75k turnover)"},
            {"value": "NFP", "text": "Yes - Not for Profit"},
            {"value": "OS", "text": "Yes - Overseas Client"}
        ];
        
        component.set("v.exemptReasons", exemptReasons);
        
        component.set("v.selectedExempt", "RQ");
    },
    goBack: function(component, event, helper) {
        window.history.back();
    },
    selectRecordType: function(component, event, helper) {
        component.set("v.recordTypeId", event.getSource().get("v.value"));
        var recordTypes = component.get("v.recordTypes");
        var recordTypeId = component.get("v.recordTypeId");
        var showNames;
        console.log(recordTypes);
        console.log(recordTypeId);
        for(var i=0; i<recordTypes.length; i++){
            if(recordTypes[i].id == recordTypeId && recordTypes[i].isPersonType == true){
            	console.log(recordTypes[i].id == recordTypeId);
            	console.log(recordTypes[i].isPersonType);
                showNames = "true";
            }    
        }
        component.set("v.showNames", showNames); 
        //console.log(component.get("v.showNames"));
    },
    selectType: function(component, event, helper) {
        var selectedType = component.get("v.selectedType");
        
        component.set("v.street", "");
        component.set("v.city", "");
        component.set("v.postcode", "");
        component.set("v.state", "");
        component.set("v.country", "");
        component.set("v.dpid", "");
        
        if (selectedType == "OS") {
            component.set("v.searchAddress", false);
        	component.set("v.selectedExempt", "OS");
            component.set("v.abnExempt", true);
        } else if (selectedType == "NZPAF") {
            component.set("v.searchAddress", true);
            component.set("v.selectedExempt", "OS");
            component.set("v.abnExempt", true);
        } else {
            component.set("v.searchAddress", true);
            component.set("v.selectedExempt", "RQ");
            component.set("v.abnExempt", false);
        }
        
        //helper.duplicateCheck(component, helper);
    },
    checkAddress: function(component, event, helper) {
        var timer = component.get("v.typingTimer");
        
        if ((timer != undefined) && (timer != null)) {
            clearTimeout(timer);
        }
        
        var address = component.get("v.address");
        
        if ((address == null) || (address.length < 10)) {
            component.set("v.showAddresses", false);
            component.set("v.selectedAddress", null);
            return;
        }
        
        timer = setTimeout($A.getCallback(function(){
            component.set("v.loadingAddress", true);
            helper.addressSearch(component, helper);
        }), 750);
        
        component.set("v.typingTimer", timer);
	},
    selectAddress: function(component, event, helper) {
        var index = document.getElementById("addressList").selectedIndex;
        var selectedAddress = document.getElementById("addressList").value;

        var addresses = component.get("v.addresses");
        var sourceOfTruth = component.get("v.selectedType");
        
        component.set("v.selectedAddress", selectedAddress);
        
        if ((addresses[index].subdwelling != null) && (addresses[index].subdwelling != '')) {
            component.set("v.street", addresses[index].subdwelling + ' ' + addresses[index].streetNumber + ' ' + addresses[index].street);
        } else {
            component.set("v.street", addresses[index].streetNumber + ' ' + addresses[index].street);
        }
        
        component.set("v.city", addresses[index].locality);
        component.set("v.postcode", addresses[index].postcode);
        component.set("v.state", addresses[index].state);
        component.set("v.country", addresses[index].country);
        component.set("v.dpid", addresses[index].attributes.DPID);
        
        if ((sourceOfTruth == 'AUPAF') || (sourceOfTruth == 'GNAF')) {
            component.set("v.country", "AUSTRALIA");
        } else if (sourceOfTruth == 'NZPAF') {
            component.set("v.country", "NEW ZEALAND");
        } else {
            component.set("v.country", "");
        }
        
       // helper.duplicateCheck(component, helper);
    },
	validate: function(component, event, helper) {
        helper.validate(component, helper);
	},
    checkName: function(component, event, helper) {
        var timer = component.get("v.typingTimer");
        
        if ((timer != undefined) && (timer != null)) {
            clearTimeout(timer);
        }
        
        timer = setTimeout($A.getCallback(function(){
            //helper.duplicateCheck(component, helper);
        }), 750);
        
        helper.validate(component, helper);
    },
    exemptABN: function(component, event, helper) {
        var abn = component.get("v.abnInput");
        var exemptReason = component.get("v.selectedExempt");
        var exempt = (exemptReason != "RQ");
        
        if (exempt) {
            component.set("v.abnInput", "");
            component.set("v.validABN", false);
            component.set("v.loading", false);
            component.set("v.companyName", "");
            component.set("v.abnStatus", "");
        }
        
        if (exemptReason == "OS") {
            component.set("v.selectedType", "OS");
            component.set("v.searchAddress", false);
            
            component.set("v.street", "");
            component.set("v.city", "");
            component.set("v.postcode", "");
            component.set("v.state", "");
            component.set("v.country", "");
            component.set("v.dpid", "");
        } else {
            component.set("v.selectedType", "AUPAF");
            component.set("v.searchAddress", true);
        }
        
        component.set("v.abnExempt", exempt);
        
        helper.checkABN(component, helper);
    },
    checkABN: function(component, event, helper) {
        var abn = component.get("v.abnInput");
        var exempt = component.get("v.abnExempt");
        
        if ((abn != null) && (abn != "")) {
            component.set("v.abnExempt", false);
        }
        
        helper.checkABN(component, helper);
    },
    createAccount: function(component, event, helper) {
        helper.createAccount(component, helper);
    }
})