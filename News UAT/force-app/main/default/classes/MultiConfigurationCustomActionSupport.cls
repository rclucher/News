/*---------------------------------------------------------
 * Author: Alistair Borley
 * Company: CloudSense
 * Description: 
 * This class contains an action handler which is called by a button press on the CloudSense Sales Order screen
 * It performs the action of invoking the MultiLineEditor. It contains a hardwired reference to the Product to use. 
 * This ID needs to be updated as part of the configuration install/setup and is stored in the custom label MLE_Product_Definition_ID
 ---------------------------------------------------------*/

 global without sharing class MultiConfigurationCustomActionSupport implements csmso.SalesOrderSupport.SalesOrderCustomAction{

    global String performAction(String salesOrderId) {

        System.debug('performAction for MLE Initiation from Sales Order');
 
        csmso__Sales_Order__c so = [select Id, Name, (select Id from csmso__Product_Baskets__r) from csmso__Sales_Order__c where id = :salesOrderId];

        System.debug('Name ' + so.Name);
        System.debug('MLE Product to use ' + System.Label.MLE_Product_Definition_ID );

        if (so.csmso__Product_Baskets__r != null && !so.csmso__Product_Baskets__r.isEmpty()){
            return '{"status":"ok", "redirectURL":"/apex/csmle__Editor?id=' + so.csmso__Product_Baskets__r.get(0).Id + '&productDefinitionId=' + System.Label.MLE_Product_Definition_ID + '&batchSize=5&showHeader=false&sideBar=false&retURL=/' + salesOrderId + '", "message": "redirecting ..."}';
        }
        return '{"status":"warning", "message":"Basket Id is not available for csmso__Sales_Order__c with id \'' + salesOrderId + '\', cannot perform action."}';
    }
}