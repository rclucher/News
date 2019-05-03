/*---------------------------------------------------------
 * Author: Partheeva Dhakappa
 * Company: CloudSense
 * Description: 
 * This class contains an action handler which is called by a button press on the CloudSense Sales Order screen
 * This buttons is put in place to handle Order Amendments.
 * This action would work when a Customer requests change on a Live Sales Order
 ---------------------------------------------------------*/


global without sharing class RecallSalesOrder implements csmso.SalesOrderSupport.SalesOrderCustomAction{
    
    //Implementing the method "performAction" for the Sales Order
    global String performAction(String salesOrderId){
        //if (System.Label.CS_Using_Old_Approvals == 'True') {
        csmso__Sales_Order__c salesOrder = [select Id, Platform_Set__c, OwnerId, csmso__Status__c,
            									Print_Display_Approval_Level__c, Print_Display_MAX_PPT_Level__c
                                            	from csmso__Sales_Order__c
                                            	where Id = :salesOrderId];

        if (salesOrder.Platform_Set__c == '{Xtend}') {
            CS_RecallSalesOrderResponse res = new CS_RecallSalesOrderResponse();

            try{

                Approval.ProcessWorkitemRequest PWR = new Approval.ProcessWorkitemRequest();
                List<ProcessInstanceWorkitem> piw = [SELECT Id FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId= :salesOrder.Id];
                PWR.setAction('Removed');
                PWR.setWorkitemId(piw[0].id);
                Approval.ProcessResult result =  Approval.process(PWR);

                if(result.isSuccess()){
                    res.status  = 'ok';
                    res.message = 'Sales Order Recalled';

                    salesOrder.csmso__Status__c = 'Draft';
                    update salesOrder;
                }

            } catch (Exception e) {
                res.status  = 'error';
                res.message = 'Exception occured with recall method:' + e.getmessage().escapejava();
            }

            return  JSON.serialize(res);

        } else {
            try {
                AT_SalesOrderApprovals.Result ativaResult = AT_SalesOrderApprovals.recall(Id.valueOf(salesOrderId));

                if (ativaResult.success) {
                    return '{"status":"ok", "message": "Sales Order Recalled"}';
                } else {
                    return '{"status":"error", "message": "' + ativaResult.message + '"}';
                }
            } catch (Exception e) {
                return '{"status":"error", "message":"Exception occured with recall method:' + e.getmessage().escapejava() + '"}';
            }
        }
    }

    public class CS_RecallSalesOrderResponse{
        String status;
        String message;
        String redirectURL;
    }

    public class CS_RecallSalesOrderException extends Exception {}

}