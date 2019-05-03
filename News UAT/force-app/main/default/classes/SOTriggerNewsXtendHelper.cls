//*******************************************************************
// Developed by:  Malvika Sharma
// Date Created: 19.4.2016 (dd.MM.yyyy)
// Last Update: 19.4.2016 (dd.MM.yyyy)
// Description: Helper class for SOTriggerNewsXtend Trigger 
//              to update package name
//*******************************************************************

public class SOTriggerNewsXtendHelper {

    public static void AddPackageInsert(List<csmso__Sales_Order__c> newsoList){
        Set<Id> soIds = new Set<Id>();
        List<cscfga__Product_Basket__c > prodBasketList = new List<cscfga__Product_Basket__c >();     
        List<csmso__Sales_Order__c> soInsertList = new List<csmso__Sales_Order__c>();
        Map<Id,cscfga__Product_Basket__c > basketOrderMap = new Map<Id,cscfga__Product_Basket__c>();
    
        for (csmso__Sales_Order__c so : newsoList){
            soIds.add(so.Id);
        }
        
        prodBasketList= [Select Id,Name,csmso__Sales_Order__c , (Select Id,Name,cscfga__originating_offer__c,cscfga__originating_offer__r.Name From cscfga__Product_Configurations__r LIMIT 1)From cscfga__Product_Basket__c WHERE csmso__Sales_Order__c IN : soIds ];
        
        for(cscfga__Product_Basket__c bas:prodBasketList)
        {
            basketOrderMap.put(bas.csmso__Sales_Order__c,bas);
        }
        if(prodBasketList!=null){
            for(csmso__Sales_Order__c so : newsoList){
                if(basketOrderMap!=null && basketOrderMap.get(so.id)!=null && basketOrderMap.get(so.id).cscfga__Product_Configurations__r != Null && basketOrderMap.get(so.id).cscfga__Product_Configurations__r.size()>0 && basketOrderMap.get(so.id).cscfga__Product_Configurations__r[0].cscfga__originating_offer__c != NULL)
                {
                    so.Package_Name__c = basketOrderMap.get(so.id).cscfga__Product_Configurations__r[0].cscfga__originating_offer__r.Name;
                    soInsertList.add(so);
                }
                
            }
            update soInsertList;
        }        
        
      }  
      
      public static void AddPackageUpdate(List<csmso__Sales_Order__c> newsoList){
      
        Set<Id> soIds = new Set<Id>();
        List<cscfga__Product_Basket__c > prodBasketList = new List<cscfga__Product_Basket__c >();     
        List<csmso__Sales_Order__c> soUpdateList = new List<csmso__Sales_Order__c>();
        Map<Id,cscfga__Product_Basket__c > basketOrderMap = new Map<Id,cscfga__Product_Basket__c>();
    
        for (csmso__Sales_Order__c so : newsoList){
            soIds.add(so.Id);
        }
        
        prodBasketList= [Select Id,Name,csmso__Sales_Order__c , (Select Id,Name,cscfga__originating_offer__c,cscfga__originating_offer__r.Name From cscfga__Product_Configurations__r LIMIT 1)From cscfga__Product_Basket__c WHERE csmso__Sales_Order__c IN : soIds ];
        
        for(cscfga__Product_Basket__c bas:prodBasketList)
        {
            basketOrderMap.put(bas.csmso__Sales_Order__c,bas);
        }
        if(prodBasketList!=null){
            for(csmso__Sales_Order__c so : newsoList){
                for(cscfga__Product_Configuration__c prodConf : basketOrderMap.get(so.id).cscfga__Product_Configurations__r){
                    if(prodConf.cscfga__originating_offer__c == Null){
                        so.Package_Name__c = 'Custom';
                        soUpdateList.add(so);
                    }
                    
                    if(prodConf.CreatedDate != prodConf.LastModifiedDate )
                    {
                        so.Package_Name__c = 'Custom';
                        soUpdateList.add(so);
                    }                    
                }                
            }
            update soUpdateList;
        }                
      }  
}