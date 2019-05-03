public class Set_Normal_Priority_ctrl {
    
    @AuraEnabled
    Public  static  String Set_Normal_Priority_mtd ( String OrderId){
        
        String result =  CS_OrchestratorPriorityControl.setOrchestratorPriorityCampaign(OrderId , '2 - Normal' );
        return result;
    }
    

}