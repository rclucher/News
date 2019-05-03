/*---------------------------------------------------------
 * Author: Alistair Borley
 * Company: CloudSense
 * Description: 
 * This class contains an action handler which is called by a button press on the CloudSense Sales Order screen
 * It performs the action of requesting approval of a Sales Order that is outside the business rules for automatic approval
 ---------------------------------------------------------*/

 global without sharing class RequestApprovalSalesOrder implements csmso.SalesOrderSupport.SalesOrderCustomAction{

    global String performAction(String salesOrderId) {

        System.debug('performAction for Request Approval of Sales Order');

        csmso__Sales_Order__c salesOrder = [select Id, Margin__c, Margin_Flag__c, Campaign_Length__c, Platform_Set__c,
                                                    Notes__c, csmso__Status__c, Print_Display_Approval_Level__c, Print_Display_MAX_PPT_Level__c
                                            from csmso__Sales_Order__c where Id = :salesOrderId]; //T-26364 - Added campaign_lenght to querry + T-28905 Added Notes__c to querry


        if (salesOrder.Platform_Set__c == '{Xtend}') {

            System.debug('Sales Order updated .... Margin is ' + salesOrder.Margin__c + ' and flag ' + salesOrder.Margin_Flag__c);

            If ((salesOrder.Margin_Flag__c  == 'Margin OK') && (salesOrder.Campaign_Length__c == null))  { //T-26364 - Added campaign_lenght check
                System.debug('Within guidelines. Further approval not required' + salesOrder.Margin_Flag__c );
                return '{"status":"warning", "message": "Sales Order is within pricing/margin guidelines. No internal approvals required."}'; //13/03 GB - error messages changes mail/SV changed status to warning
            }

            if (salesOrder.Margin__c == null) {
                System.debug('Margin is in error ' + salesOrder.Margin__c);
                return '{"status":"error", "message":"Margin is in error, please report problem"}';
            }

            if (salesOrder.Margin_Flag__c  == 'Margin OK' && salesOrder.Campaign_Length__c != null && String.isBlank(salesOrder.Notes__c)) {
                return '{"status":"error", "message":"No notes were added for Internal Approval Request; please add reason(s) for this Internal Approval Request in Notes"}';
            }

            // T-28905 NF_12/15/2016 start
            if ((salesOrder.Margin_Flag__c == 'Margin TOO LOW') && (String.isBlank(salesOrder.Notes__c))) { // JM 2017-02-19 (salesOrder.Notes__c == null )
                System.debug('No notes added for Margin too low' + salesOrder.Margin_Flag__c);
                return '{"status":"error", "message":"No notes were added for Internal Approval Request; please add reason(s) for this Internal Approval Request in Notes"}';
            }
            // T-28905 end


            salesOrder.csmso__Status__c = 'Sent for Internal Approval';
            try {
                update (salesOrder);
             } catch (DMLException e) {
                    return '{"status":"error", "message":"'+ e.getmessage().escapejava() +'"}';
                    }

            System.debug('Sales Order updated .... prepare to submit to proess');

            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setComments('Submitted for approval.  Please approve.');
            req.setObjectId(salesOrderId);
            req.setSkipEntryCriteria(false);

            // submit the approval request for processing
            System.debug('Sales Order updated .... submit proess. Margin is ' + salesOrder.Margin__c );
            Approval.ProcessResult result = Approval.process(req);

            // Get the ID of the newly created item
            List<Id> newWorkItemIds = result.getNewWorkitemIds();


            // display if the reqeust was successful
            System.debug('Submitted for approval successfully: ' +result.isSuccess());
            for (Integer j=0; j < newWorkItemIds.size(); j++) {
                system.debug('Work Item ID(s):' + newWorkItemIds[j]);
            }

            if (result.isSuccess()){
                return '{"status":"ok", "redirectURL":"", "message": "Successfully submitted for approval."}';
            }

            String errorSummary = '';
            for (Database.Error err : result.getErrors()){
                errorSummary += '\n' + err.getMessage();
            }
            return '{"status":"warning", "message":"Could not submit for approval: ' + errorSummary + '"}';
        } else {
            try {

                Boolean requiresApproval = true;

                requiresApproval = AT_SalesOrderApprovals.requiresApproval(salesOrder.Id);

                if (!requiresApproval) {
                    salesOrder.csmso__Status__c = 'Internally Approved';
                    update salesOrder;

                    return '{ "status" : "ok", "message": "Per CPQ Approver records the user is of required approval level therefore this Sales Order is automatically approved"}';
                }

                PageReference ativaPageReference = AT_SalesOrderApprovals.requestApproval(salesOrder.Id);

                String redirectURL = ativaPageReference.getUrl().replace('/apex/','apex/c__'); //need to swith to sf namespace

                String completeURL = String.format(
                        '{0}/{1}',
                        new String[] {
                                Site.getBaseUrl(),
                                redirectURL
                        });

                return '{"status":"ok", "redirectURL":"' + completeURL + '", "message": "Redirecting to approval page..."}';

            } catch (Exception e) {
                return  '{"status":"warning", "message":"Error when trying to get approval page: ' + e.getMessage().escapeJava() + '"}';
            }

        }

    }
}