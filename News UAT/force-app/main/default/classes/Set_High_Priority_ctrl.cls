public class Set_High_Priority_ctrl {
    
    @AuraEnabled
    Public  static  String Set_High_Priority_mtd ( String OrderId){
        
        String result =  CS_OrchestratorPriorityControl.setOrchestratorPriorityCampaign(OrderId , '3 - High' );
        return result;
    }
    
}