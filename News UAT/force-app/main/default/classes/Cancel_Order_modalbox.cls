public class Cancel_Order_modalbox {
    @AuraEnabled
	//NXRIII-374
    //Public  static Boolean updateOrder ( String OrderId){
	Public  static Boolean updateOrder ( String paymentid){
	    string OrderID = [Select Id, order__c from Payment__c where id =:paymentid ].order__c ;
        Order__c Order = [Select Status__c from Order__c where Id =: OrderID];
        if (Order.Status__c == 'Pending For Cancel' || Order.Status__c == 'Cancelled') {
            return true;
        }    else {
            Order.Status__c = 'Pending For Cancel';
            update Order;
            return false;
        }       
    }
}