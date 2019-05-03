/*---------------------------------------------------------
 * Author: Alistair Borley
 * Company: CloudSense
 * Description: 
 * This class contains an action handler which is called by a button press on the CloudSense Sales Order screen
 ---------------------------------------------------------*/

 global without sharing class ApproveSalesOrder implements csmso.SalesOrderSupport.SalesOrderCustomAction{

    global String performAction(String salesOrderId) {

        //if (System.Label.CS_Using_Old_Approvals == 'True') {


            System.debug('performAction for Approve Sales Order');
            csmso__Sales_Order__c salesOrder = [select Id, Platform_Set__c, OwnerId, csmso__Status__c, 
            									Print_Display_Approval_Level__c, Print_Display_MAX_PPT_Level__c,
												csmso__Opportunity__r.Has_an_Approved_SO__c
                                            	from csmso__Sales_Order__c 
                                            	where Id = :salesOrderId];

			//master check before even trying to see what approval to use
			//Opportunity already has approved SO and it is not possible to approve any other
			if (salesOrder.csmso__Opportunity__r.Has_an_Approved_SO__c) {
				return '{"status":"error", "message":"This sales order cannot be approved, as a previous order has already been approved!"}';
			}
			
            if (salesOrder.Platform_Set__c == '{Xtend}') {
            	
	            List<Profile> PROFILE = [SELECT Id, Name FROM Profile WHERE Id = :userinfo.getProfileId() LIMIT 1];
	            String MyProfileName = PROFILE[0].Name;
	
	            System.debug('Profile Name : ' + MyProfileName);
	
	            Boolean foundGroupMember = false;
	            for (GroupMember g : [Select UserorGroupId From GroupMember WHERE group.name = 'News Xtend Approvers']) {
	                System.debug('News Xtend Public Group Member : ' + g.UserOrGroupID + ' searching for ' + UserInfo.getUserId());
	                if (g.UserOrGroupID == UserInfo.getUserId()) {
	                    foundGroupMember = true;
	                    break;
	                }
	            }
	
	            if ((MyProfileName != 'System Administrator') && (!foundGroupMember)) {
	                return '{"status":"error", "message":"Only News Xtend Approvers and Systems Adminstrators can Approve Sales Orders"}';
	            }
	
	            //csmso__Sales_Order__c salesOrder = [select Id, csmso__Status__c, OwnerId from csmso__Sales_Order__c where Id = :salesOrderId];
	            salesOrder.csmso__Status__c = 'Internally Approved';
	
	            // See if this Approval is associated with an Approval process
	            Id workItemId = null;
	            for (ProcessInstanceWorkitem workItem : [Select p.Id from ProcessInstanceWorkitem p where p.ProcessInstance.TargetObjectId = :salesOrderId]) {
	                System.debug('workitem' + workItem);
	                workItemId = workItem.Id;
	                break;
	            }
	
	            // Do we have an outstanding Approval process, if so lets mark it as approved
	            if (workItemId == null) {
	                System.debug('Could not find a workitem');
	            } else {
	                System.debug('Found WorkItemID ' + workItemId);
	                // Instantiate the new ProcessWorkitemRequest object and populate it
	                //added by Davor Dubokovic for SFE-860
	                List<ProcessInstance> lstProcessInstance = [
	                        SELECT TargetObjectId, SubmittedById
	                        FROM ProcessInstance
	                        where TargetObjectId = :salesOrderId and (Status = 'Pending' OR Status = 'Started')
	                ];
	
	                if (lstProcessInstance.size() > 0) {
	                    Id OwnerId = salesOrder.OwnerId;
	                    Id SubmitterId = lstProcessInstance[0].SubmittedById;
	                    Id CurrentUserId = UserInfo.getUserId();
	
	                    if ((CurrentUserId == OwnerId) || (CurrentUserId == SubmitterId)) {
	                        return '{"status":"error", "message":"Approver cannot be submitter or owner of the Sales Order"}';
	                    }
	                }
	                //end of code added by Davor Dubokovic for SFE-860
	
	                Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
	                req.setComments('Approving request via SO Approval Button');
	                req.setAction('Approve');
	                req.setNextApproverIds(new Id[]{
	                        UserInfo.getUserId()
	                });
	
	                // Use the ID from the newly discovered item to be worked
	                req.setWorkitemId(workItemId);
	
	                // Submit the request for approval
	                Approval.ProcessResult result = Approval.process(req);
	
	                // display if the reqeust was successful
	                System.debug('Submitted for approval successfully: ' + result.isSuccess());
	            }
	
	            try {
	                update (salesOrder);
	            } catch (DMLException e) {
	                return '{"status":"error", "message":"../..' + e.getmessage().escapejava() + '"}';
	            }
	            return '{"status":"ok"}';
	        }
        	else {
            try {
                AT_SalesOrderApprovals.Result ativaResult = AT_SalesOrderApprovals.approve(Id.valueOf(salesOrderId),'');

                if (ativaResult.success) {
                   return '{"status":"ok", "message": "Sales Order Approved"}';
                } else {
                    return '{"status":"error", "message": "' + ativaResult.message + '"}';
                }
            } catch (Exception e) {
                return '{"status":"error", "message":"Exception occured with approval method:' + e.getmessage().escapejava() + '"}';
            }

        }
    }
}