// This is a conversion from Classic version of the button

({
        handleRecordUpdated: function(component, event, helper) {
            var eventParams = event.getParams();
            if (eventParams.changeType === "LOADED") {
                // record is loaded (render other component which needs record data value)

                console.log("Record is loaded successfully.");
                var Opportunity = component.get('v.opp');

                var urlBriefForm = $A.get("e.force:navigateToURL");

                if (Opportunity != null) {
                    console.log('Opportunity stagename' + Opportunity.StageName);

                    if (Opportunity.StageName === 'Closed Won' && Opportunity.Briefing_Form_Status__c === 'Completed') {
                        helper.handleShowNotice(component, 'info', 'Briefing Form', 'If you want to view Sales Briefing Form, please click Export Briefing Form button.\nIf you need to amend Sales Briefing Form, please contact assigned Campaign Manager.');
                    } else {

                        if (Opportunity.OpportunityGroup__c != null) {

                            if (Opportunity.OpportunityGroup__c.includes('NewsXtend')) {
                                if (Opportunity.Briefing_Form__c == null || Opportunity.Briefing_Form__c === undefined) {
                                    console.log('@briefing with Oppt Id ' + Opportunity.Id);
                                    urlBriefForm.setParams({
                                        "url": '/apex/CS_ViewBriefingForm?rtName=Sales&oppId=' + Opportunity.Id,
                                        "isredirect": "true"
                                    });
                                } else {
                                    console.log('@briefing form redirect to bfId' + Opportunity.Briefing_Form__c);
                                    urlBriefForm.setParams({
                                        "url": '/apex/CS_ViewBriefingForm?bfId=' + Opportunity.Briefing_Form__c + '&oppId=' + Opportunity.Id,
                                        "isredirect": "true"
                                    });
                                }
                                urlBriefForm.fire();
                            } else {
                                helper.handleShowNotice(component, 'warning', 'Briefing Form', 'This briefing form is for NewsXtend only.');
                            }
                        }
                        else {
                            helper.handleShowNotice(component, 'warning', 'Briefing Form', 'This briefing form is for NewsXtend only.');
                        }
                    }
                    $A.get("e.force:closeQuickAction").fire();

                } else if (eventParams.changeType === "CHANGED") {
                    // record is changed
                } else if (eventParams.changeType === "REMOVED") {
                    // record is deleted
                } else if (eventParams.changeType === "ERROR") {
                    // there’s an error while loading, saving, or deleting the record
                }


            }
        }
})