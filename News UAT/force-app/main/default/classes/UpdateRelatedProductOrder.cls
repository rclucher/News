public class UpdateRelatedProductOrder {
    
    @InvocableMethod(label='Update the child records')
    public static void doAction(Request[] requests) {
        Set<Id> orderid = new Set<Id>();
        List<Product_Order__c> newList =  new List<Product_Order__c>();
        List<Product_Order__c> parentList = new List<Product_Order__c>();
        for(Request pr:requests){
            orderid.add(pr.orderId);
         }
        List<Product_Order__c> childRec = [select Id, Name, Order__c, RecordTypeId, RecordType.Name, Product_Node__c, Amazon_URL__c, Ebay_URL__c, Facebook_URL__c, Google_URL__c, External_System_ID2__c,Other_URL__c 
//          from Product_Order__c where Order__c in: orderid and  RecordType.Name in ('Search Engine Marketing', 'Social','Marketplace Feed') and Product_Node__r.Name in ('NX Search - SEM (Media Spend) [>$2000 p/m]','NX Social - Facebook - $3000+','NX - Marketplace Feed - Monthly Fee','NX Search - SEM (Media Spend) [less than $750  p/m]','NX Search - SEM (Media Spend) [$751 - $1999 p/m]','NX Social - Facebook - $995 to $1999','NX Social - Facebook - $2000 to $2999')];
          from Product_Order__c where Order__c in: orderid and  RecordType.Name in ('Search Engine Marketing', 'Social') and Product_Node__r.Name in ('NX Search - SEM (Media Spend) [>$2000 p/m]','NX Social - Facebook - $3000+','NX Search - SEM (Media Spend) [less than $750  p/m]','NX Search - SEM (Media Spend) [$751 - $1999 p/m]','NX Social - Facebook - $995 to $1999','NX Social - Facebook - $2000 to $2999')];
        for(Request pr:requests){
        for(Product_Order__c updatechild:childRec){
            if(updatechild.Order__c == pr.orderId){
            updatechild.Amazon_URL__c = pr.amazonUrl;
            updatechild.Ebay_URL__c = pr.ebayUrl;
            updatechild.Facebook_URL__c = pr.facebookUrl;
            updatechild.Google_URL__c = pr.googleUrl;
            updatechild.External_System_ID2__c = pr.extSys;
            updatechild.Other_URL__c = pr.otherUrl;
            newList.add(updatechild);
                
          }  
        }
      }
    update newList;
    }
    @TestVisible
    public with sharing class Request {
        @InvocableVariable(label='Order ID' required=true)
        public Id orderId;
        
        @InvocableVariable(label='Product ID' required=true)
        public Id productId;

        @InvocableVariable(label='Amazon URL')
        public String amazonUrl;
        
        @InvocableVariable(label='Ebay URL')
        public String ebayUrl;
        
        @InvocableVariable(label='Facebook URL')
        public String facebookUrl;
        
        @InvocableVariable(label='Google URL')
        public String googleUrl;

        @InvocableVariable(label='External System')
        public String extSys;
        
        @InvocableVariable(label='Other URL')
        public String otherUrl;
        
        @InvocableVariable(label='check MasterRecord')
        public Boolean flag;
    }
}