/*---------------------------------------------------------
 * Author: Alistair Borley
 * Company: CloudSense
 * Description: 
 * This class contains an action handler which is called by a button press on the CloudSense Sales Order screen
 * It responds to the Reject button action and rejects the Sales Order waiting for approval
 ---------------------------------------------------------*/

 global without sharing class RejectSalesOrder implements csmso.SalesOrderSupport.SalesOrderCustomAction{

    global String performAction(String salesOrderId) {

        System.debug('performAction for Reject Sales Order');
        //if (System.Label.CS_Using_Old_Approvals == 'True') {

		csmso__Sales_Order__c salesOrder = [select Id, Platform_Set__c, OwnerId, csmso__Status__c, 
            									Print_Display_Approval_Level__c, Print_Display_MAX_PPT_Level__c
                                            	from csmso__Sales_Order__c 
                                            	where Id = :salesOrderId];

        if (salesOrder.Platform_Set__c == '{Xtend}') {
            List<Profile> PROFILE = [SELECT Id, Name FROM Profile WHERE Id=:userinfo.getProfileId() LIMIT 1];
            String MyProfileName = PROFILE[0].Name;

            System.debug('Profile Name : ' + MyProfileName);

            Boolean foundGroupMember = false;
            for(GroupMember g : [Select UserorGroupId From GroupMember WHERE group.name = 'News Xtend Approvers']){
                System.debug('News Xtend Public Group Member : ' + g.UserOrGroupID + ' searching for ' + UserInfo.getUserId());
                if(g.UserOrGroupID == UserInfo.getUserId()) {
                    foundGroupMember = true;
                    break;
                }
            }

            if ((MyProfileName != 'System Administrator' ) &&  (!foundGroupMember)) {
                return '{"status":"error", "message":"Only News Xtend Approvers and Systems Adminstrators can Reject Sales Orders"}';
            }

            //csmso__Sales_Order__c salesOrder = [select Id, csmso__Status__c from csmso__Sales_Order__c where Id = :salesOrderId];
            // salesOrder.csmso__Status__c = 'Draft';
            salesOrder.csmso__Status__c = 'Internally Rejected';

            // See if this Reject is associated with an Approval process
            Id workItemId = null;
            for(ProcessInstanceWorkitem workItem  : [Select p.Id from ProcessInstanceWorkitem p where p.ProcessInstance.TargetObjectId =: salesOrderId])
            {
                workItemId  =  workItem.Id;
                break;
            }

            // Do we have an outstanding Approval process, if so lets mark it as rejected
            if (workItemId == null) {
                System.debug('Could not find a workitem');
            }
            else {
                System.debug('Found WorkItemID ' + workItemId);
                // Instantiate the new ProcessWorkitemRequest object and populate it
                Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                req.setComments('Rejecting request via SO Reject Button');
                req.setAction('Reject');
                req.setNextApproverIds(new Id[] {UserInfo.getUserId()});

                // Use the ID from the newly discovered item to be worked
                req.setWorkitemId(workItemId);

                // Submit the request for approval
                Approval.ProcessResult result =  Approval.process(req);

                // display if the reqeust was successful
                System.debug('Submitted for rejection successfully: '+result.isSuccess());
            }

            try {
                update (salesOrder);
             } catch (DMLException e) {
                    return '{"status":"error", "message":"'+ e.getmessage().escapejava() +'"}';
                    }
            return '{"status":"ok"}';
        } else {
            try {
                //reject so call new page
                PageReference ativaPageReference = AT_SalesOrderApprovals.rejectSO(salesOrder.Id);

                String redirectURL = ativaPageReference.getUrl().replace('/apex/','apex/c__'); //need to swith to sf namespace

                String completeURL = String.format(
                        '{0}/{1}',
                        new String[] {
                                Site.getBaseUrl(),
                                redirectURL
                        });

                return '{"status":"ok", "redirectURL":"' + completeURL + '", "message": "Redirecting to reject page..."}';

            } catch (Exception e) {
                return '{"status":"error", "message":"Exception occured with reject method:' + e.getmessage().escapejava() + '"}';
            }
        }
    }
}