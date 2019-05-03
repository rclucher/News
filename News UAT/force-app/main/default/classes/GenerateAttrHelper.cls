//*************************************************
// Developed by: Malvika Sharma
// Date Created: 12.04.2016 (dd.MM.yyyy)
// Last Update: 12.04.2016 (dd.MM.yyyy)
// Description: Helper class for to get Attributes
// Modifications
//    Add in additional attributes required via the select statement (Alistair Borley)
//    Added in CPM and Cost CPM for CSV purposes (Alistair Borley)
//*************************************************

global class GenerateAttrHelper{
     // TODO: Xtend E2E Billing Trail
    //get product basket
    global cscfga__Product_Basket__c ProdBasketList(Id salesOrderId){
        system.debug('***'+salesOrderId);
        cscfga__Product_Basket__c  productBas = [Select Id, Name , csmso__Sales_Order__c from cscfga__Product_Basket__c  where csmso__Sales_Order__c =: salesOrderId LIMIT 1];
        return productBas;
    }
    
    //set of attributes
    global static String[] attrName = new String[]{'Provider Name', 'Source','Site Section Group', 'Site Section', 'Product Line Name', 'Total Impressions', 'Price', 'Email','Company Name','CPM', 'Cost CPM'};
    global static String[] attrNameCSV = new String[]{'Total Impressions', 'Total Cost','Provider Name', 'Product Line Name', 'Product Type Name', 'Product Name','Network Name','Discount', 'Cost Model', 'Price', 'CPM', 'Cost CPM'};


    //get product config
    global list<cscfga__Product_Configuration__c > ProdConfigList(Id prodBasketId){
        list<cscfga__Product_Configuration__c> allProdConfig = new list<cscfga__Product_Configuration__c>();
        allProdConfig= [SELECT Name, cscfga__Description__c,  cscfga__Product_Basket__r.csmso__Sales_Order__r.Name, 
        cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__From__c,
        cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.Name,
        cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.Id,
        cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Booking_Contact__r.FirstName,
        cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Booking_Contact__r.LastName,     
        cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Booking_Contact__r.Email,
        cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Booking_Contact__r.Phone ,
        cscfga__Product_Basket__r.csmso__Sales_Order__r.Package_Name__c,
        cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.BillingCountry,
        cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.BillingState,
        cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.BillingCity,
        cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.BillingStreet,
        cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.BillingPostalCode,
        cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.Fax,
        cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.Website,
        cscfga__Product_Basket__r.csmso__Sales_Order__r.Social_URL__c, 
        cscfga__Product_Basket__r.csmso__Sales_Order__r.Campaign_Start_Date__c,       
        //** Commented for field type switch Start        
        cscfga__Product_Basket__r.csmso__Sales_Order__r.Campaign_End_Date2__c,       
        //** Commented for field type switch End   
        cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.Owner.FirstName,
        cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.Owner.LastName,
        cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.Owner.Phone,
        cscfga__Product_Basket__r.csmso__Sales_Order__r.Dashboard__c,
        cscfga__Product_Basket__r.csmso__Sales_Order__r.Conversion_Tracking__c,
        cscfga__Product_Basket__r.csmso__Sales_Order__r.Creative_Services__c,
        cscfga__Product_Basket__r.csmso__Sales_Order__r.Call_Tracking__c,
        cscfga__Product_Basket__r.csmso__Sales_Order__c, cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__To__c, 
        cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Total_Price__c, 
        cscfga__Configuration_Status__c, (Select  Name, cscfga__Value__c, cscfga__Attribute_Definition__r.Name, cscfga__Product_Configuration__r.Name 
        FROM cscfga__Attributes__r 
        where cscfga__Attribute_Definition__r.Name IN : attrName ORDER BY cscfga__Attribute_Definition__r.Name DESC NULLS LAST ) 
        FROM cscfga__Product_Configuration__c WHERE cscfga__Product_Basket__c=:prodBasketId
        AND  Line_Item_Platform__c = 'Xtend' AND Bundle_Item__c = false];//OPG: Xtend E2E Billing Trail - fixed PC select];
        return allProdConfig;
    }
    
    //get product config
    global list<cscfga__Product_Configuration__c > ProdConfigListCSV(Id prodBasketId){
        list<cscfga__Product_Configuration__c> allProdConfig = new list<cscfga__Product_Configuration__c>();
        allProdConfig= [SELECT Name, cscfga__Description__c,  cscfga__Product_Basket__r.csmso__Sales_Order__r.Name, 
        cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__From__c,
        cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.Name,
        cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.Id,
        cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Booking_Contact__r.FirstName,
        cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Booking_Contact__r.LastName,     
        cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Booking_Contact__r.Email,
        cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Booking_Contact__r.Phone ,
        cscfga__Product_Basket__r.csmso__Sales_Order__r.Package_Name__c,
        cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.BillingCountry,
        cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.BillingState,
        cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.BillingCity,
        cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.BillingStreet,
        cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.BillingPostalCode,
        cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.Fax,
        cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.Website,
        cscfga__Product_Basket__r.csmso__Sales_Order__r.Social_URL__c, 
        cscfga__Product_Basket__r.csmso__Sales_Order__r.Campaign_Start_Date__c,        
        //** Commented for field type switch Start        
        cscfga__Product_Basket__r.csmso__Sales_Order__r.Campaign_End_Date2__c,    
        //** Commented for field type switch End   
        cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.Owner.FirstName,
        cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.Owner.LastName,
        cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.Owner.Phone,
        cscfga__Product_Basket__r.csmso__Sales_Order__r.Dashboard__c,
        cscfga__Product_Basket__r.csmso__Sales_Order__r.Conversion_Tracking__c,
        cscfga__Product_Basket__r.csmso__Sales_Order__r.Creative_Services__c,
        cscfga__Product_Basket__r.csmso__Sales_Order__r.Call_Tracking__c,
        cscfga__Product_Basket__r.csmso__Sales_Order__c, cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__To__c, 
        cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Total_Price__c, 
        cscfga__Configuration_Status__c, (Select  Name, cscfga__Value__c, cscfga__Attribute_Definition__r.Name, cscfga__Product_Configuration__r.Name,
        cscfga__Product_Configuration__r.cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.Name,
        cscfga__Product_Configuration__r.cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.Id,
        cscfga__Product_Configuration__r.cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Booking_Contact__r.FirstName,
        cscfga__Product_Configuration__r.cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Booking_Contact__r.LastName,     
        cscfga__Product_Configuration__r.cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Booking_Contact__r.Email,
        cscfga__Product_Configuration__r.cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Booking_Contact__r.Phone ,
        cscfga__Product_Configuration__r.cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.BillingCountry,
        cscfga__Product_Configuration__r.cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.BillingState,
        cscfga__Product_Configuration__r.cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.BillingCity,
        cscfga__Product_Configuration__r.cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.BillingStreet,
        cscfga__Product_Configuration__r.cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.BillingPostalCode,
        cscfga__Product_Configuration__r.cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.Fax,
        cscfga__Product_Configuration__r.cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.Website,
        cscfga__Product_Configuration__r.cscfga__Product_Basket__r.csmso__Sales_Order__r.Campaign_Start_Date__c,
        //** Commented for field type switch Start  
        cscfga__Product_Configuration__r.cscfga__Product_Basket__r.csmso__Sales_Order__r.Campaign_End_Date2__c,
        //** Commented for field type switch End  
        cscfga__Product_Configuration__r.cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.Owner.FirstName,
        cscfga__Product_Configuration__r.cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.Owner.LastName,
        cscfga__Product_Configuration__r.cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.Owner.Phone,
        cscfga__Product_Configuration__r.cscfga__Product_Basket__r.csmso__Sales_Order__r.Dashboard__c,
        cscfga__Product_Configuration__r.cscfga__Product_Basket__r.csmso__Sales_Order__r.Conversion_Tracking__c,
        cscfga__Product_Configuration__r.cscfga__Product_Basket__r.csmso__Sales_Order__r.Creative_Services__c,
        cscfga__Product_Configuration__r.cscfga__Product_Basket__r.csmso__Sales_Order__r.Call_Tracking__c,
        cscfga__Product_Configuration__r.cscfga__Product_Basket__r.csmso__Sales_Order__c,
        cscfga__Product_Configuration__r.cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Total_Price__c      
        FROM cscfga__Attributes__r 
        where cscfga__Attribute_Definition__r.Name IN : attrNameCSV  ORDER BY cscfga__Attribute_Definition__r.Name DESC NULLS LAST ) 
        FROM cscfga__Product_Configuration__c WHERE cscfga__Product_Basket__c=:prodBasketId
        AND  Line_Item_Platform__c = 'Xtend' AND Bundle_Item__c = false];//OPG: Xtend E2E Billing Trail - fixed PC select];
        return allProdConfig;
    }
}