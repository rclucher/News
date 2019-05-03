public class Set_Normal_Priority_Modal_ctrl {
    
    @AuraEnabled
    Public  static  String Set_Normal_Priority_mtd ( String OrderId){
        
        String result =  CS_OrchestratorPriorityControl.setOrchestratorPriorityProduct(OrderId , '2 - Normal' );
        return result;
    }
}