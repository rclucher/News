/*---------------------------------------------------------
 * Author: Alistair Borley
 * Company: CloudSense
 * Description: 
 * This class contains an action handler which is called by a button press on the CloudSense Sales Order screen
 * It performs the action of proving manual approval of a Sales Order on behalf of the customer
 * This would typically occur when the customer has provided written approval rather than via the ClickApprove email based solution
 ---------------------------------------------------------*/

 global without sharing class ManualApprovalSalesOrder implements csmso.SalesOrderSupport.SalesOrderCustomAction{

    global String performAction(String salesOrderId) {

        System.debug('performAction for Manually Approve Sales Order');

        csmso__Sales_Order__c salesOrder = [select Id, Basket_Products__c, csmso__Status__c, Campaign_Start_Date__c, Margin_Flag__c, csmso__Total_Price__c, Campaign_Length__c, csmso__Advertiser__c, csmso__Booking_Contact__c, Total_Impressions__c, Platform_Set__c from csmso__Sales_Order__c where Id = :salesOrderId];

        System.debug('Margin ' + salesOrder.Margin_Flag__c + ' Price ' + salesOrder.csmso__Total_Price__c + ' Status ' + salesOrder.csmso__Status__c);
        
        /* T-26364 - original code

        If (((salesOrder.csmso__Status__c == 'Draft') || (salesOrder.csmso__Status__c == 'Externally Rejected') || (salesOrder.csmso__Status__c == 'Internally Rejected')) && (salesOrder.Margin_Flag__c  == 'Margin TOO LOW'))  {
            System.debug('Can not Manually Approve Sales Order, Margin too low' + salesOrder.Margin_Flag__c );
            return '{"status":"error", "message":"Can not manually approve on behalf of customer, Margin too low"}';
        } */
        // added check for campaign start date
        if (salesOrder.Campaign_Start_Date__c == null) {
            System.debug('Can not Manually Approve Sales Order, Campaign Start Date is not set');
            return '{"status":"error", "message":"Can not Manually Approve Sales Order, Campaign Start Date is not set"}';
        }
        
        // T-26364 new code (added check for campaign length)
        If (((salesOrder.csmso__Status__c == 'Draft') || (salesOrder.csmso__Status__c == 'Externally Rejected') || (salesOrder.csmso__Status__c == 'Retracted') || (salesOrder.csmso__Status__c == 'Internally Rejected')) &&
                ((salesOrder.Margin_Flag__c  == 'Margin TOO LOW' || salesOrder.Campaign_Length__C !=null) && (salesOrder.Platform_Set__c.contains('Xtend') && !salesOrder.Basket_Products__c.contains('Bundle'))))  {
        System.debug('Can not Manually Approve Sales Order, Margin too low or invalid campaign lenght' + salesOrder.Margin_Flag__c );
        return '{"status":"error", "message":"Can not manually approve on behalf of customer, Margin too low or campaign is a seasonal so it requires internal approval."}';
        }
        // T-26364 end          ``Q!q`

        if (salesOrder.Total_Impressions__c  == null) {
            System.debug('Can not Manually Approve Sales Order, Impressions are null');
            return '{"status":"error", "message":"Can not manually approve on behalf of customer, Sales Order not complete"}';
        }

       /* if (salesOrder.Campaign_Lenght__c == null) {
            System.debug('Can not Manually Approve Sales Order, Campain Length null');
            return '{"status":"error", "message":"Can not manually approve on behalf of customer, Campaign Length unknown"}';
        }*/

        salesOrder.csmso__Status__c = 'Manually Approved';

        try {
            update (salesOrder);
         } catch (DMLException e) {
                return '{"status":"error", "message":"'+ e.getmessage().escapejava() +'"}';
                }
        return '{"status":"ok", "message":"You have manually approved on behalf of the customer"}';
    }
}