public class Start_Fulfilment_Product_Order {

     @AuraEnabled
    Public  static Boolean updateOrder ( String OrderId){
        
         Product_Order__c Order = [Select Status__c from Product_Order__c where Id =: OrderID];
             Order.Status__c = 'Fulfilment Started';
            update Order;
            return true;
    }
}