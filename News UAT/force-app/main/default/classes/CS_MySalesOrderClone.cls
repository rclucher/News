/**
* @author           Kevin Wu
* @date             2018-10-01
* @className        CS_MySalesOrderClone
* @testClassName    CS_MySalesOrderCloneTest
* @description      Implementation of clone sales order 
*/
global class CS_MySalesOrderClone implements csmso.SalesOrderAPI.CloneFilter{
    global csmso__Sales_Order__c clonedSalesOrder;

    global void prepareReferences(Id salesOrderId){
    }

    global List<SObject> filter(String apiName, SObject source, SObject clone){ 
        List<SOBject> clones = new List<SObject>{clone};
        
        if (apiName == 'csmso__Sales_Order__c') {  
            clonedSalesOrder = (csmso__Sales_Order__c)clone;
            clonedSalesOrder.Campaign_Start_Date__c = null;
        }
        return clones;
    }

    global void cloningFinished(Boolean success){}
}