({
    handleRecordUpdated: function (component, event, helper) {
        var eventParams = event.getParams();
        if (eventParams.changeType === "LOADED") {
            // record is loaded (render other component which needs record data value)
            var Opportunity = component.get('v.opp');
            var urlBriefForm = $A.get("e.force:navigateToURL");
            if (Opportunity != null) {
                console.log('Briefing_Form__c ' + Opportunity.Briefing_Form__c);
                urlBriefForm.setParams({
                    "url": '/apex/CS_ExportBriefingFormAsPDF?bfId=' + Opportunity.Briefing_Form__c + '&oppId=' + Opportunity.Id,
                    "isredirect": "true"
                });

                if (Opportunity.OpportunityGroup__c === 'NewsXtend') {
                    if (Opportunity.Briefing_Form__c == null || Opportunity.Briefing_Form__c === undefined) 
                        helper.handleShowNotice(component,'warning','Briefing Form','Briefing form not created yet.');
                    else 
                        urlBriefForm.fire();
                }
                else {
                    helper.handleShowNotice(component,'error','This briefing form is for NewsXtend only.');
                }
            }
            $A.get("e.force:closeQuickAction").fire();
        }

    }
})