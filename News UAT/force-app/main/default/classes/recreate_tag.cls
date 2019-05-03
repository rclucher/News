public class recreate_tag{

    @TestVisible
    private ApexPages.StandardController ctrl;
    
    public recreate_tag(ApexPages.StandardController controller) {
        this.ctrl = controller;
    }   
    
    public PageReference executeRecreateLogic() {
         //Id orderId = ctrl.getRecord().Id;
         try { 
            Id orderId = ctrl.getRecord().Id;
            String temp = '';
            temp = GenericWebServices.regenerateProductOrders(orderId);
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.INFO,temp)); 
            return null;
         } catch(Exception e) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL, e.getMessage()));
            return null;
         }
    }
    
}