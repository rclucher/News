public class Pause_Product_Order_modalbox {
    
    @AuraEnabled
    Public  static Boolean updateOrder ( String OrderId){
        
        Product_Order__c Order = [Select Status__c from Product_Order__c where Id =: OrderID];
        if (Order.Status__c == 'Pending For Pause' || Order.Status__c == 'Paused') {
            return true;
        }    else {
            Order.Status__c = 'Pending For Pause';
            update Order;
            return false;
        }       
    }

}