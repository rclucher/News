/**
 * Controller for Salesforce Lightning action to Schedule Payments
 * Deletes old orders and payments if all payment schedules are pending or cancelled
 */
public class CS_SchedulePaymentsController {
    
    @TestVisible
    private ApexPages.StandardController ctrl;
    
    public CS_SchedulePaymentsController(ApexPages.StandardController controller) {
        this.ctrl = controller;
    }
    
    /**
     * Schedule payments Lightning action
     */
    public PageReference schedulePayments() {
        try {
            Id oppId = ctrl.getRecord().Id;
            List<Opportunity> oppList = new list<Opportunity> ([select OpportunityGroup__c, Account.AdPoint_ID__c, Payer_Account__r.AdPoint_ID__c from Opportunity where id =:oppId]);
            //**Commented for field type switch Start            
            List<csmso__Sales_Order__c> salesOrders = [
                select id,Name,csmso__Status__c,Campaign_Start_Date__c,Campaign_End_Date2__c,Campaign_Length__c,Total_GST_inclusive__c,csmso__Total_Price__c,csmso__Booking_Contact__r.Name,GST__c 
                from csmso__Sales_Order__c 
                where csmso__Opportunity__c =:oppId
                and (csmso__Status__c = 'externally approved'
                    or csmso__Status__c = 'manually approved')
            ];
            //**Commented for field type switch End 
            if (salesOrders.size() > 1) {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL, 'More than one manually or externally approved Sales Order.'));
                return null;
            }
            /*
            else if (salesOrders[0].Campaign_Start_Date__c < system.today()){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL, 'Campaign start date cannot be sooner than today, please amend the start date on the Sales Order to schedule payments.'));
                return null;
            }
            */
            List<Order__c> ordersToDelete = [
                select id 
                from Order__c
                where Opportunity__c = :oppId
            ];
            List<Payment_Schedule__c> psToDelete = [
                select Id, Status__c
                from Payment_Schedule__c
                where Payment__r.Order__r.Opportunity__c = :oppId
            ];
            List<Payment__c> pToDelete = [
                select Id
                from Payment__c
                where Order__r.Opportunity__c = :oppId
            ];
            List<Payment_Line_Item__c> pliToDelete = [
                select Id
                from Payment_Line_Item__c
                where Payment_Schedule__r.Payment__r.Order__r.Opportunity__c = :oppId
            ];
            for (Payment_Schedule__c ps : psToDelete) {
                if (ps.Status__c != 'Pending' && ps.Status__c != 'Cancelled') {
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL, 'Campaign already started. Cannot reschedule payments.'));
                    return null;
                }
            }
            if (!pliToDelete.isEmpty()) {
                delete pliToDelete;
            }
            if (!psToDelete.isEmpty()) {
                delete psToDelete;
            }
            if (!pToDelete.isEmpty()) {
                delete pToDelete;
            }
            if (!ordersToDelete.isEmpty()) {
                delete ordersToDelete;
            }
            if (oppId !=null && salesOrders.size()>0){
                Order_PaymentSchedulerController.getOrder(oppId,salesOrders[0]);
                Order_PaymentSchedulerController.createPayment(salesOrders[0],oppList[0]);
                Order_PaymentSchedulerController.createPaymentSchedule(salesOrders[0]);
                Order_PaymentSchedulerController.createPaymentLineItem(salesOrders[0]);
            }
            return ctrl.view();
        } catch(Exception e) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL, e.getMessage()));
            return null;
        }
    }

}