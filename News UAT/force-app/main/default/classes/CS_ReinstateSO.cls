/**
* @author           Kevin Wu
* @date             2018-10-01
* @className        CS_ReinstateSO
* @testClassName    CS_ReinstateSOTest
* @description      Entry for reinstate so. This class contains an action handler which is called by a button press on the CloudSense Sales Order screen
*/
global without sharing class CS_ReinstateSO implements csmso.SalesOrderSupport.SalesOrderCustomAction{
    
    //Implementing the method "performAction" for the Sales Order
    global String performAction(String salesOrderId){
        // create a savepoint in case exception happens
        Savepoint sp = Database.setSavepoint();

        CS_ReinstateSOResponse res = new CS_ReinstateSOResponse();
        try{
        	csmso__Sales_Order__c so = [Select Id, csmso__Status__c, csmso__Opportunity__r.StageName, 
        										Retracted_Date__c, Retracted_Product_Configurations__c, Retraction_Cache_Data__c, 
                                                    	(Select Id, Overall_Status__c, Status__c From Orders__r), 
                                                    	(Select Id From csmso__Product_Baskets__r) 
	                                                From 	csmso__Sales_Order__c
	                                                Where   Id = :salesOrderId Limit 1];
	    	CS_ReinstateSalesOrderService.validate(so);
            CS_ReinstateSalesOrderService.undo(so.Id, so.Retraction_Cache_Data__c);
            
            res.status = 'ok';
            res.message = 'success';
            res.redirectURL = '/' + salesOrderId;
        }catch(CS_ReinstateSalesOrderService.ReinstateSalesOrderException ex){
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
    

    public class CS_ReinstateSOResponse{
        String status;
        String message;
        String redirectURL;
    }
}