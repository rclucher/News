global without sharing class PreviousEndDateBuySheetAddOneYear implements CSPOFA.ExecutionHandler {
    private static final String STEP_STATUS_COMPLETE = 'Complete';
    private static final String STEP_STATUS_ERROR = 'Error';
    
    global List<sObject> process(List<sObject> data) {
        List<sObject> results = new List<sObject>();
        List<CSPOFA__Orchestration_Step__c> stepList = (List<CSPOFA__Orchestration_Step__c>)data;

        //let's extract all ProcessIds
        List<Id> processIds = new List<Id>();
        for (CSPOFA__Orchestration_Step__c step : stepList) {
            processIds.add(step.CSPOFA__orchestration_process__c);
        }
        //now we fetch Processes and their related Product_Order__c, with the fields we need
        //if we put it in a Map, it's easy to fetch the right record later
        Map<Id, CSPOFA__Orchestration_Process__c> processes = new Map<Id, CSPOFA__Orchestration_Process__c>(
            [Select Id, Name, Product_Order__c, Product_Order__r.Status__c, Product_Order__r.Previous_End_Date_Buy_Sheet_add_1y__c FROM CSPOFA__Orchestration_Process__c where Id IN :processIds]
            );

        Product_Order__c prodOrder = null;
        for (CSPOFA__Orchestration_Step__c step : stepList) {
            prodOrder = processes.get(step.CSPOFA__Orchestration_Process__c).product_order__r;
            system.debug('prodOrder:' + prodOrder);
            if (prodOrder.status__c == null) {
                system.debug('prodOrder.status__c:' + prodOrder.status__c);
            }
            if (prodOrder == null) {
                step.CSPOFA__Status__c = STEP_STATUS_ERROR;
                step.CSPOFA__Message__c = 'Product Order not found on Process!';
            } else {    
                //prodOrder is not null!
                prodOrder.Previous_End_Date_Buy_Sheet_add_1y__c += 365; //this assumes each Process is related to a separate Product Order. Otherwise the field might get increased multiple times!
                results.add(prodOrder);                                 //instead of this, you can perform the DML update yourself (with try-catch around it etc.)
                step.CSPOFA__Status__c = STEP_STATUS_COMPLETE;
                step.CSPOFA__Message__c = 'Custom step succeeded';
                step.CSPOFA__Completed_Date__c = Date.today();
            }
            results.add(step);
        }
        
        return results;
    }
}