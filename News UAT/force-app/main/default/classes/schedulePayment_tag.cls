public class schedulePayment_tag {

    @TestVisible
    private ApexPages.StandardController ctrl;
    
    public schedulePayment_tag (ApexPages.StandardController controller) {
        this.ctrl = controller;
    }   
    
    public PageReference executePaymentLogic() {
         try { 
            Id oppId= ctrl.getRecord().Id;
            String temp = Order_PaymentSchedulerController.updateOrder_Payment(oppId);
            return ctrl.view();
         } catch(Exception e) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL, e.getMessage()));
            return null;
         }
    }
    
    
}