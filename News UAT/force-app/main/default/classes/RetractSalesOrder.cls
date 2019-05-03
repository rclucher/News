/*---------------------------------------------------------
 * Author: Partheeva Dhakappa
 * Company: CloudSense
 * Description: 
 * TestClassName:    RetractSalesOrderTest
 * This class contains an action handler which is called by a button press on the CloudSense Sales Order screen
 * This buttons is put in place to handle Order Amendments.
 * This action would work when a Customer requests change on a Live Sales Order
 ---------------------------------------------------------*/


global without sharing class RetractSalesOrder implements csmso.SalesOrderSupport.SalesOrderCustomAction{
    
    //Implementing the method "performAction" for the Sales Order
    global String performAction(String salesOrderId){
        CS_RetractSalesOrderResponse res = new CS_RetractSalesOrderResponse();
        // create a savepoint in case exception happens
        Savepoint sp = Database.setSavepoint();
        try{
            String result = CS_RetractSalesOrderService.retract(salesOrderId);
            res.status = 'ok';
            res.message = result;
            res.redirectURL = '/' + salesOrderId;
        }catch(CS_RetractSalesOrderService.RetractSalesOrderException ex){
            res.status = 'error';
            res.message = ex.getMessage();
            Database.rollback(sp);
        }catch(Exception ex){
            res.status = 'error';
            res.message = 'System error. Please contact your System Administrator.';
            Database.rollback(sp);
        }
        

        return JSON.serialize(res);
    }    
    

    public class CS_RetractSalesOrderResponse{
        String status;
        String message;
        String redirectURL;
    }
}