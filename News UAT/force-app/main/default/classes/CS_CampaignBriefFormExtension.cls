public class CS_CampaignBriefFormExtension {


    @TestVisible
    private ApexPages.StandardController ctrl;
        
    public CS_CampaignBriefFormExtension(ApexPages.StandardController controller) {
        this.ctrl = controller;
    }   
       
    public PageReference creatOrViewBriefForm() {
                
            Id orderId = ctrl.getRecord().Id;
            Order__c myOrder = [SELECT Id,Briefing_Form__c,Opportunity__c FROM Order__c WHERE ID =:orderId ];
            PageReference pageRef = null;
            if (myOrder.Briefing_Form__c==null) {
                pageRef = new PageReference('/apex/CS_ViewBriefingForm?rtName=Campaign&orderId='+ myOrder.Id + '&oppId='+myOrder.Opportunity__c);
            } else {
                pageRef = new PageReference( '/apex/CS_ViewBriefingForm?bfId=' + myOrder.Briefing_Form__c + '&oppId='+myOrder.Opportunity__c);

            }
            
         return pageRef;
    }
}