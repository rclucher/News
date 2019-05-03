/*---------------------------------------------------------
 * Author: Logabalakrishnan (LBK) Muthukrishnan
 * Company: News
 * Description: 
 * 1. This trigger is for Requirement: R-NNNN.
 *              The purpose of this trigger is to fetch the sales order id from CPQ Sales Order object 
 *              using Case - Opportunity - CPQ Sales Order relationship.
 *              This sales order id data in Case object helps in displaying a link to Booking Sheet functionality from Case Page Layout. 
 * History:
 * 2018-03-08   LBK     Created
 * 2018-06-21   Pratyush Chalasani  (NR-468) Updated to select only approved sales orders
 ---------------------------------------------------------*/

trigger FetchCPQSalesOrderTrigger on Case (BEFORE INSERT) {
    Set<ID> setOppIDs = new Set<ID>();
    Map<ID, String> mapOppSales = new Map<ID, String>();
    
    List<String> approvedStatuses = new String[]{'Manually Approved', 'Internally Approved', 'Externally Approved'};
    
    for(Case objCase : trigger.new){
        System.debug('objCase.Name : ' + objCase.CaseNumber);
        if(objCase.Opportunity__c != null){
            setOppIDs.add(objCase.Opportunity__c);
            System.debug('objCase.Opportunity__c : ' + objCase.Opportunity__c);
        }
    }
    //System.debug('setOppIDs : ' + setOppIDs);
    
    List<csmso__Sales_Order__c> lstOrders = [SELECT ID, csmso__Opportunity__c FROM csmso__Sales_Order__c WHERE  (csmso__Opportunity__c IN : setOppIDs) AND (csmso__Status__c IN :approvedStatuses) ORDER BY CreatedDate DESC];
    for(csmso__Sales_Order__c objOrder : lstOrders){
        mapOppSales.put(objOrder.csmso__Opportunity__c, String.valueOf(objOrder.ID));
    }
    
    //System.debug(mapOppSales.size());
    for(Case objCase : trigger.new){
        if(objCase.Opportunity__c != null){
            if (mapOppSales.containsKey(objCase.Opportunity__c)){
                objCase.CPQ_Sales_Order__c = mapOppSales.get(objCase.Opportunity__c);
                //System.debug('objCase.CPQ_Sales_Order__c : ' + objCase.CPQ_Sales_Order__c);
            }
        }
    }
}