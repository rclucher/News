public class Recreate_ProductOrders_modalbox {
    
    @AuraEnabled
    Public  static void Recreate_ProductOrders ( String OrderId){
        GenericWebServices.regenerateProductOrders(OrderId);       
    }

}