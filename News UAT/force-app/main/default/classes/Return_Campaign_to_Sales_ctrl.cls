public class Return_Campaign_to_Sales_ctrl {
    
    @AuraEnabled
    Public  static Boolean updateOrder ( String OrderId){
        
        Order__c Order = [Select Status__c from Order__c where Id =: OrderID];
        
        if (Order.Status__c == 'Returned to Sales') {
            return true;
        }    else {
            Order.Status__c = 'Returned to Sales';
            update Order;
            return false;
        }       
    }
    //NXRIII-347  
    @AuraEnabled
    public static string initClass(String OrderId){
        string strNotesForFailure;
        Order__c Order = [Select Status__c,Notes_for_Failure__c from Order__c where Id =: OrderID];
        
        if(Order!=null){
            strNotesForFailure = Order.Notes_for_Failure__c;
        }

        return strNotesForFailure;
        
    }

}