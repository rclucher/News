//*******************************************************************
// Developed by:  Malvika Sharma
// Date Created: 19.4.2016 (dd.MM.yyyy)
// Last Update: 19.4.2016 (dd.MM.yyyy)
// Description: Helper class for PackageName Trigger 
//              to update package name
//*******************************************************************

public class PackageNameHelper {

    public static Boolean isFirstRun = true;
    public static void AddPackageInsert(List<cscfga__Product_Configuration__c> prodConfigList){
    if(isFirstRun)
       {
        isFirstRun = false; 
        Set<Id> basketIds = new Set<Id>();
        List<cscfga__Product_Basket__c > prodBasketList = new List<cscfga__Product_Basket__c >();     
        Map<Id,cscfga__Product_Basket__c > basketOrderMap = new Map<Id,cscfga__Product_Basket__c>();
        List<csmso__Sales_Order__c> soQueryList = new List<csmso__Sales_Order__c>();
        Map<Id,csmso__Sales_Order__c> soUpdateMap = new Map<Id,csmso__Sales_Order__c>();
        
        for(cscfga__Product_Configuration__c pc : prodConfigList){
             basketIds.add(pc.cscfga__Product_Basket__c);
        }
        
        
        
        prodBasketList= [Select Id,Name,csmso__Sales_Order__c , (Select Id,Name,cscfga__originating_offer__c,cscfga__originating_offer__r.Name,CreatedDate,LastModifiedDate From cscfga__Product_Configurations__r)From cscfga__Product_Basket__c WHERE Id IN : basketIds ];
        
        for(cscfga__Product_Basket__c bas:prodBasketList)
        {
            basketOrderMap.put(bas.csmso__Sales_Order__c,bas);
        }
        
        
        soQueryList = [Select Id, Name, Package_Name__c From csmso__Sales_Order__c WHERE Id In : basketOrderMap.keyset()];
        
        for(csmso__Sales_Order__c so : soQueryList){
              for(cscfga__Product_Configuration__c prodConf : basketOrderMap.get(so.id).cscfga__Product_Configurations__r){
                if(prodConf.cscfga__originating_offer__c == Null){
                        so.Package_Name__c = 'Custom';
                        if(soUpdateMap.isEmpty()||(soUpdateMap.get(so.id)==null))
                          soUpdateMap.put(so.id,so);
                    } 
                 else 
                 {
                    so.Package_Name__c = basketOrderMap.get(so.id).cscfga__Product_Configurations__r[0].cscfga__originating_offer__r.Name;
                    if(soUpdateMap.isEmpty()||(soUpdateMap.get(so.id)==null))
                          soUpdateMap.put(so.id,so);
                 }    
             }
            }
            if(!soUpdateMap.IsEmpty())
            update soUpdateMap.Values();
        }    
    }
    
    public static void AddPackageUpdate(List<cscfga__Product_Configuration__c> prodConfigList){
        if(isFirstRun)
        {
        isFirstRun = false;
        Set<Id> basketIds = new Set<Id>();
        List<cscfga__Product_Basket__c > prodBasketList = new List<cscfga__Product_Basket__c >();     
        Map<Id,cscfga__Product_Basket__c > basketOrderMap = new Map<Id,cscfga__Product_Basket__c>();
        List<csmso__Sales_Order__c> soQueryList = new List<csmso__Sales_Order__c>();
        Map<Id,csmso__Sales_Order__c> soUpdateMap = new Map<Id,csmso__Sales_Order__c>();
        
        
        for(cscfga__Product_Configuration__c pc : prodConfigList){
             basketIds.add(pc.cscfga__Product_Basket__c);
        }
        
        
        
        prodBasketList= [Select Id,Name,csmso__Sales_Order__c , (Select Id,Name,cscfga__originating_offer__c,cscfga__originating_offer__r.Name,CreatedDate,LastModifiedDate From cscfga__Product_Configurations__r)From cscfga__Product_Basket__c WHERE Id IN : basketIds ];
        
        for(cscfga__Product_Basket__c bas:prodBasketList)
        {
            basketOrderMap.put(bas.csmso__Sales_Order__c,bas);
        }
        
        
        soQueryList = [Select Id, Name, Package_Name__c From csmso__Sales_Order__c WHERE Id In : basketOrderMap.keyset()];
        
        for(csmso__Sales_Order__c so : soQueryList){
                for(cscfga__Product_Configuration__c prodConf : basketOrderMap.get(so.id).cscfga__Product_Configurations__r){

                    if(prodConf.CreatedDate != prodConf.LastModifiedDate )
                    {
                        so.Package_Name__c = 'Custom';
                        if(soUpdateMap.isEmpty()||(soUpdateMap.get(so.id)==null))
                          soUpdateMap.put(so.id,so);
                    }                    
                }    
                 
            }
           
            if(!soUpdateMap.IsEmpty())
            update soUpdateMap.Values();
    }
   } 
        
}