/*---------------------------------------------------------
 * Author: Alistair Borley
 * Company: CloudSense
 * Description: 
 * This class contains an action handler which is called by a button press on the CloudSense Sales Order screen
 * It performs the action of invoking a file selection and attachement by redirecting to the AttachSalesOrderRedirect VF page
 ---------------------------------------------------------*/

 global without sharing class AttachIOSalesOrder implements csmso.SalesOrderSupport.SalesOrderCustomAction{

    global String performAction(String salesOrderId) {

        System.debug('performAction for Attach IO from Sales Order ' + salesOrderId);

        string retURL=URL.getSalesforceBaseUrl().toExternalForm().replace('csmso','c')+'/apex/AttachIOSalesOrderRedirect?id='+Id.valueOf(salesOrderId);
        //string retURL='/'+ salesOrder.csmso__Opportunity__c;
        return '{"status":"ok","redirectURL":"' + retURL + '"}';   

        //return '{"status":"ok","redirectURL":"http://www.google.com","title":"Success","text":"Custom action successful","target":"1"}';
    }
}