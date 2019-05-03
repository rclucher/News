public class View_Briefing_Form_ctrl {
    
    public View_Briefing_Form_ctrl(ApexPages.StandardController controller) {
    }
    
    Public pagereference View_Briefing_mthd(){
        Id ProductOrderId =  ApexPages.currentPage().getParameters().get('id');
        Product_order__c Porder = [Select Briefing_Form__c, Opportunity__c from Product_order__c where id =: ProductOrderId] ;
        id Briefingform = Porder.Briefing_Form__c;
        id opportuid = Porder.Opportunity__c;
        If (Porder.Briefing_Form__c == null ){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.info, 'Campaign Order does not have a Briefing Form created'));
            return null;
            
        }
        else{
            
            string URL = '/apex/CS_ViewBriefingForm?bfId='+Briefingform+ '&oppId='+opportuid ;   
            
            pagereference p = new pagereference(URL);
            p.setRedirect(true);
            return p;              
        }
        
    }
}