({
    initSelectOptions: function(component,event,helper){
        var objectOptions = [{"label":"Sales Order","id":"salesOrder"},{"label":"Sales Order Line Items","id":"productConfigurations"},{"label":"Campaign Order","id":"campaignOrder"},{"label":"Product Orders","id":"productOrders"}];
        component.set("v.objectOptions", objectOptions);

    },
    getAllHistory: function(component,event,helper){

        // get all the history tracking records
        // get all the fields (api names and labels)
        var action = component.get("c.getSoHistory");
        action.setParams({ salesOrderId: component.get('v.salesOrderId')});
        action.setCallback(this, function(response) {
            var state = response.getState();

            console.log('State: ' + state);

            if (state === "SUCCESS") {
                var response = JSON.parse(response.getReturnValue());
                console.log(response);

                if(response.code == 2000){
                    var allHistoryTrackings = JSON.parse(response.details);
                    var salesOrderHistory = allHistoryTrackings.salesOrderHistory;
                    var fieldSetMapping = allHistoryTrackings.fieldSetMappings;
                    var fieldMappings   = allHistoryTrackings.fieldMappings;

                    var allHistory = [];
                    var snapshotOptions = [];
                    if(salesOrderHistory){
                        for(var i = 0; i < salesOrderHistory.length; i++){
                            var snapshot = JSON.parse(salesOrderHistory[i]);

                            allHistory.push(snapshot);


                            var snapshotOption = {"label":snapshot.description + '  ---  ' + snapshot.createdDate, "id":snapshot.createdDate};
                            snapshotOptions.push(snapshotOption);
                        }
                    }
                    //snapshotOptions.sort((a,b) => (a.label > b.label) ? 1 : ((b.label > a.label) ? -1 : 0)); //sort
                    component.set('v.snapshotOptions', snapshotOptions);
                    component.set('v.fieldSetMapping', fieldSetMapping);
                    component.set('v.fieldMappings', fieldMappings);


                    // wip
                    component.set('v.allHistory', allHistory);

                }else{

                }

            } else if (state === "INCOMPLETE") {
            } else if (state === "ERROR") {
                window.scrollTo(0, 0);
            }
        });

        $A.enqueueAction(action);
    },
    getCampaignInfo: function(component,event,helper) {
        // get SO and CO names
        var action = component.get("c.getCampaignInfo");
        action.setParams({ salesOrderId: component.get('v.salesOrderId')});
        action.setCallback(this, function(response) {
            var state = response.getState();

            console.log('*** Campaign Info state: ' + state);

            if (state === "SUCCESS") {
                var response = JSON.parse(response.getReturnValue());
                console.log(response);

                if(response.code == 2000){
                    var campaignInfo = JSON.parse(response.details);
                    var auditCO_Name = campaignInfo.auditCO_Name;
                    var auditSO_Name = campaignInfo.auditSO_Name;

                    component.set('v.auditCO_Name', auditCO_Name);
                    component.set('v.auditSO_Name', auditSO_Name);

                }else{

                }

            } else if (state === "INCOMPLETE") {
            } else if (state === "ERROR") {
                window.scrollTo(0, 0);
            }
        });

        $A.enqueueAction(action);
    },
    loadSnapshot: function(component, index){
        console.log('loading ...');
        var historyToUpdate     = 'v.history' + index;
        var fieldToUpdate       = 'v.fields' + index;
        var object              = 'v.object' + index;
        var snapshot            = 'v.snapshot' + index;
        var showAllSeleted      = 'v.showAll' + index;

        if(!component.get(object) || !component.get(snapshot)){
            return;
        }

        // setting field mapping for display
        var showAll = component.get(showAllSeleted);
        var fieldMapping = showAll ? component.get('v.fieldMappings') : component.get('v.fieldSetMapping');
        var fieldSetMapping = this.setFieldsToDisplay(fieldMapping, component.get(object));

        // get snapshots
        var snapshotValue = this.getSnapshot(component.get('v.allHistory'), component.get(object), component.get(snapshot));
        var snapshotList = [];
        if(snapshotValue)snapshotList.push(snapshotValue);

        // generate the list to display
        if(snapshotList && fieldSetMapping){
            var historyToDisplay = [];
            for(var i=0; i<snapshotList.length; i++){
                var historyToDisplayLevel2 = [];
                if(snapshotList[i].length && snapshotList[i].length>0){
                    for(var j=0; j<snapshotList[i].length; j++){
                        var historyToDisplayLevel2 = [];

                        var recordName, recordId;
                        for(var k=0; k<fieldSetMapping.length; k++){
                            var label = fieldSetMapping[k].label;
                            var apiName = fieldSetMapping[k].fieldPath;

                            // if(snapshotList[i][j] && snapshotList[i][j].hasOwnProperty(apiName)){
                            if(snapshotList[i][j] ){
                                var snapshotFieldValue = this.getFieldValueIncludingLookups(snapshotList[i][j],apiName);
                                var row = {'label': label, 'value': snapshotFieldValue };
                                historyToDisplayLevel2.push(row);

                                // set the title of the accordian
                                if(component.get(object) == 'productConfigurations' && apiName =='Product_Name__c'){
                                    recordName = snapshotList[i][j][apiName];
                                }else if(component.get(object) == 'productOrders' && apiName =='Name'){
                                    recordName = snapshotList[i][j][apiName];
                                }else if(apiName =='Id'){
                                    recordId = snapshotList[i][j][apiName];
                                }
                            }
                        }
                        if (showAll) { //sort
                            historyToDisplayLevel2.sort((a,b) => (a.label > b.label) ? 1 : ((b.label > a.label) ? -1 : 0));
                        }
                        var tempObj = {};
                        tempObj.name        = recordName;
                        tempObj.id          = recordId;
                        tempObj.showhide    = 'slds-hide';
                        tempObj.list        = historyToDisplayLevel2;
                        historyToDisplay.push(tempObj);
                    }

                }else{
                    for(var k=0; k<fieldSetMapping.length; k++){
                        var label = fieldSetMapping[k].label;
                        var apiName = fieldSetMapping[k].fieldPath;

                        // if(snapshotList[i] && snapshotList[i].hasOwnProperty(apiName)){
                        if(snapshotList[i]){
                            var snapshotFieldValue = this.getFieldValueIncludingLookups(snapshotList[i],apiName);
                            var row = {'label': label, 'value': snapshotFieldValue};
                            historyToDisplayLevel2.push(row);
                        }
                    }
                    if (showAll) { //sort
                         historyToDisplayLevel2.sort((a,b) => (a.label > b.label) ? 1 : ((b.label > a.label) ? -1 : 0));
                    }
                    var tempObj = {};
                    tempObj.name = null;
                    tempObj.showhide    = '';
                    tempObj.list = historyToDisplayLevel2;
                    historyToDisplay.push(tempObj);

                }
            }

            component.set(historyToUpdate, historyToDisplay);
        }

    },
    setFieldsToDisplay: function(fieldMapping, object){
        if(fieldMapping.hasOwnProperty(object)){
            return fieldMapping[object];
        }
        return null;
    },
    getSnapshot: function(allHistory, object, datetime){
        if(allHistory && object && datetime){
            for(var i = 0; i < allHistory.length; i++){
                if(allHistory[i].createdDate === datetime && allHistory[i].hasOwnProperty(object)){
                    return allHistory[i][object];
                }
            }
        }
        return null;
    },
    getParameterByName: function(component, name, url) {
        if (!url) {
            url = window.location.href;
        }

        name = name.replace(/[\[\]]/g, "\\$&");
        var regex = new RegExp("[?&]" + name + "(=([^&#]*)|&|#|$)");
        var results = regex.exec(url);
        if (!results) {
            return null;
        }
        if (!results[2]) {
            return '';
        }

        return decodeURIComponent(results[2].replace(/\+/g, " "));
    },
    slideControlPanel: function(component, event, helper){
        var testcmp = component.find('controlPanel');
        $A.util.toggleClass(testcmp,'change');
    },
    toggleTable : function(component,event,secId) {
        var acc = component.find(secId);
        for(var cmp in acc) {
            $A.util.toggleClass(acc[cmp], 'slds-show');
            $A.util.toggleClass(acc[cmp], 'slds-hide');
        }
    },getFieldValueIncludingLookups: function(snapshot, apiName){
           //displaying lookup values
            var lookupFieldList = apiName.split('.'); //splitting field path i.e. Account__r.Name


            if (lookupFieldList.length > 1) {
                if (snapshot[lookupFieldList[0]]) { //check if lookup value is present snapshot['Account__r']
                    return snapshot[lookupFieldList[0]][lookupFieldList[1]]; //i.e. get snapshot['Account__r']['Name'];
                }

                return null;
                //return snapshot[lookupFieldList[0]][lookupFieldList[1]];
            } else {
                return snapshot[apiName];
            }

    },
    generateCsv : function(component, index){
        var history = component.get('v.history' + index);
        var object = component.get('v.object' + index);
        var snapshot = component.get('v.snapshot' + index);
        var recordNumber = index === 1  ? 'One' : index === 2 ? 'Two' : index === 3 ? 'Three' : '';
        var csv = 'Record ' + recordNumber + '\n';
        csv = csv +'Object,' + object + '\n';
        csv = csv + 'Snapshot,' + snapshot + '\n\n';
        if(object === 'productConfigurations' ||  object === 'productOrders' ){
            for(var i = 0 ; i < history.length ; i++){
                var hs = history[i];
                csv = csv + hs.name + '\n'
                for(var j = 0 ; j < hs.list.length ; j++){
                    csv = csv + hs.list[j].label + ',' + hs.list[j].value + '\n';
                }
                csv = csv + '\n\n';
            }



        }else{
            for(var i = 0 ; i < history.length ; i++){
                var hs = history[0];
                for(var j = 0 ; j < hs.list.length ; j++){
                    csv = csv + hs.list[j].label + ',' + hs.list[j].value + '\n';
                }
                csv = csv + '\n\n';
            }
        }
        return csv;
    },
    resetAll : function(component, index){
        component.set('v.history' + index, null);
        component.set('v.object' + index, null);
        component.set('v.snapshot' + index, null);
        component.set('v.fields' + index, null);
        component.set('v.showAll' + index, null);
    }
})