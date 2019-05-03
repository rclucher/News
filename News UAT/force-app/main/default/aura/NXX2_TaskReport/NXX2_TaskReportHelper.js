({
    populateColumnLables : function(component) {
        var columns = [
            {
                'lable' : 'Subject',
                'isHyperLinked' : true,
                'sObjectIdFieldName' : 'taskId',
                'fieldName' : 'taskSubject'
            },
            {
                'lable' : 'Status',
                'isHyperLinked' : false,
                'fieldName' : 'taskStatus'
            },
            {
                'lable' : 'Related To',
                'isHyperLinked' : true,
                'sObjectIdFieldName' : 'relatedToId',
                'fieldName' : 'taskRelatedTo'
            },
            {
                'lable' : 'Account Name',
                'isHyperLinked' : false,
                'fieldName' : 'accountName'
            },
            {
                'lable' : 'Customer Tier',
                'isHyperLinked' : false,
                'fieldName' : 'customerTier'
            },
            {
                'lable' : 'Proposed Start Date',
                'isHyperLinked' : false,
                'fieldName' : 'proposedStartDate'
            },
            {
                'lable' : 'Assigned Fulfillment Owner',
                'isHyperLinked' : false,
                'fieldName' : 'assignedFulfillmentOwner'
            }];
        var appPageName = component.get("v.AppPageName");
        if(appPageName == 'Social'){
            columns.push({
                'lable' : 'Assigned Campaign Manager',
                'isHyperLinked' : false,
                'fieldName' : 'assignedCampaignManager'
            });
            columns.push({
                'lable' : 'Created Date',
                'isHyperLinked' : false,
                'fieldName' : 'createdDate'
            });
            columns.push({
                'lable' : 'Next Social Go Live',
                'isHyperLinked' : false,
                'fieldName' : 'nextSocialGoLive'
            });
        }
        component.set("v.reportColumns",columns);
    },
    processRawTask : function(component,tasks) {
        var columns = component.get("v.reportColumns");
        var processedTask = [];
        var field = {};
        for(var i = 0; i < tasks.length; i++){
            processedTask.push({
                fields : []
            })
            for(var j = 0; j < columns.length; j++){
                field = {};
                if(columns[j].isHyperLinked){
                    field = {
                        'isHyperLinked' : true,
                        'sObjectId' : tasks[i][columns[j].sObjectIdFieldName]
                    }
                }
                field.value = tasks[i][columns[j].fieldName];
                if((j == 5 || j > 7) && field.value !== null && field.value !== undefined && field.value !== ''){
                    field.value = $A.localizationService.formatDate(field.value, "DD/MM/YYYY")
                }
                processedTask[i].fields.push(field);
            }
        }
        return processedTask;
    },
    renderPage: function(component) {
        var pageNumber = component.get('v.currentPageNumber');
        if(pageNumber > 10){
            component.set("v.serverPage",component.get("v.serverPage") + 1 );
            this.fetchTaskFromServer(component,1);
        }if(pageNumber == 0){
            component.set("v.serverPage",component.get("v.serverPage") - 1 );
            this.fetchTaskFromServer(component,10);
        }else{
            var records = component.get("v.allTask"),
                pageRecords = records.slice((pageNumber-1)*10, pageNumber*10);
            component.set("v.currentList", this.processRawTask(component,pageRecords));
        }
	},
    fetchTaskFromServer : function(component,pageNumber){
        component.set("v.displayLoader",true);
        var action = component.get('c.fetchMyTasks');
        action.setParams({
            "pageNumber" : component.get("v.serverPage"),
            "isSocial" : component.get("v.AppPageName") == "Social"
        });
        action.setCallback(this, function(actionResult) { 
            var state = actionResult.getState();
            if(state == 'SUCCESS') {
                component.set("v.allTask",actionResult.getReturnValue());
                component.set('v.currentPageNumber',pageNumber);
            } else {
                var errors = actionResult.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        component.set("v.errorMessage",errors[0].message);
                    }
                }
            }
            component.set("v.displayLoader",false);
        });
        $A.enqueueAction(action);
    }
})