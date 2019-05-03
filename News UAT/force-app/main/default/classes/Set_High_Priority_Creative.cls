public class Set_High_Priority_Creative {
    
    @AuraEnabled
    Public  static  String Set_High_Priority_mtd ( String CreativeId){
        
        String result =  CS_OrchestratorPriorityControl.setOrchestratorPriorityCreative(CreativeId , '3 - High');
        return result;
    }
    
}