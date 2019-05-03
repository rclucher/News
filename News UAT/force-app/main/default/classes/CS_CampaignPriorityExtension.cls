public class CS_CampaignPriorityExtension{

    @TestVisible
    private ApexPages.StandardController ctrl;
    
    public static final String PRIORITY_NORMAL = '2 - Normal';
    public static final String PRIORITY_HIGH   = '3 - High';
    
    public CS_CampaignPriorityExtension(ApexPages.StandardController controller) {
        this.ctrl = controller;
    }   
    
    public PageReference executeHighPriorityLogic() {
         return executePriorityLogic(PRIORITY_HIGH);
    }
    
    public PageReference executeNormalPriorityLogic() {
          return executePriorityLogic(PRIORITY_NORMAL);
    }
    
    public PageReference executePriorityLogic(String priorityLevel) {
         //Id orderId = ctrl.getRecord().Id;
         try { 
            Id orderId = ctrl.getRecord().Id;
            String temp = '';
            
            //invoke order priority for order objects, and product priority for product orders
            if ( Order__c.getSObjectType() == ctrl.getRecord().getSObjectType() ) {
                   temp = CS_OrchestratorPriorityControl.setOrchestratorPriorityCampaign(orderId, priorityLevel);
                   
            } else if ( Product_Order__c.getSObjectType() == ctrl.getRecord().getSObjectType() ) {
                   temp = CS_OrchestratorPriorityControl.setOrchestratorPriorityProduct(orderId, priorityLevel);
            } 

            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, temp));        
            return null;
         
         } catch(Exception e) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL, e.getMessage()));
            return null;
         }
    }
    

    
}