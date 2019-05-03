public class Export_Briefing_Form_ctrl {
    
    public Export_Briefing_Form_ctrl(ApexPages.StandardController controller) {
    }
    
    Public pagereference Export_Briefing_mthd(){
        Id OrderId =  ApexPages.currentPage().getParameters().get('id');
        Order__c order = [Select Briefing_Form__c , Opportunity__c from Order__c where id =: OrderId] ;
        
        
        If(order.Briefing_Form__c != null )  { 
            
            id Briefingform = order.Briefing_Form__c;
            id opportuid = order.Opportunity__c;
            string URL = '/apex/CS_ExportBriefingFormAsPDF?bfId='+Briefingform+ '&oppId='+opportuid ;   
            
            pagereference p = new pagereference(URL);
            p.setRedirect(true);
            return p;
            
        } else {
            
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.info, 'Briefing Form Not Created '));
            return null;
            
            
        }
    }
    
    
}