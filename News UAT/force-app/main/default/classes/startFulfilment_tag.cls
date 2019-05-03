public class startFulfilment_tag {

    @TestVisible
    private ApexPages.StandardController ctrl;
    
    public startFulfilment_tag (ApexPages.StandardController controller) {
        this.ctrl = controller;
    }   
    
    public PageReference executeStartFulfilmentLogic() {
         //Id orderId = ctrl.getRecord().Id;
         try { 
            Id orderId = ctrl.getRecord().Id;
            String temp = GenericWebServices.startFulfilment(orderId);
            return ctrl.view();
         } catch(Exception e) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL, e.getMessage()));
            return null;
         }
    }
    
    
}