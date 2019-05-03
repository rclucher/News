/*---------------------------------------------------------
 * Author: Alistair Borley
 * Company: CloudSense
 * Description: 
 * This class contains an action handler which is called by a button press on the CloudSense Sales Order screen
 * It performs the action of returning the user to the Oppurtunity Associated with the Sales Order (or home if no Opportunity is associated)
 ---------------------------------------------------------*/

global without sharing class SaveExitSalesOrder implements csmso.SalesOrderSupport.SalesOrderCustomAction{

    global String performAction(String salesOrderId) {

        System.debug('performAction for Save and Exit Sales Order');

        csmso__Sales_Order__c salesOrder = [select Id, Name, csmso__Opportunity__c from csmso__Sales_Order__c where id = :salesOrderId];

        if (salesOrder.csmso__Opportunity__c != null) {
            System.debug('Save and Exit Sales Order. Opportunity ' + salesOrder.csmso__Opportunity__c);
            Opportunity oppt = new Opportunity(Id = salesOrder.csmso__Opportunity__c);
            return '{"status":"ok", "redirectURL":"/' + oppt.Id + '", "message": "redirecting to opportunity ..."}';
        }
        return '{"status":"warning", "redirectURL":"/home/home.jsp", "message": "Successfully saved. No Opportunity selected, redirecting to home ..."}';
    }
}