public class Start_Fulfilment {
    
    @AuraEnabled
    Public  static  String  Start_Fulfilment_mtd ( String OrderId){
        
        String result =  GenericWebServices.startFulfilment(OrderId);
        return result;
    } 

}