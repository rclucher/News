public class Set_High_Priority_Product_Order_ctrl {
    
    @AuraEnabled
    Public  static  String Set_High_Priority_mtd ( String OrderId){
        
        String result =  CS_OrchestratorPriorityControl.setOrchestratorPriorityProduct(OrderId , '3 - High' );
        return result;
    }
  }