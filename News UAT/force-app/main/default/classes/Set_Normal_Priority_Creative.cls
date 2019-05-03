public class Set_Normal_Priority_Creative {
    
    @AuraEnabled
    Public  static  String Set_Normal_Priority_mtd ( String CreativeId){
        
        String result =  CS_OrchestratorPriorityControl.setOrchestratorPriorityCreative(CreativeId , '2 - Normal' );
        return result;
    }
    

}