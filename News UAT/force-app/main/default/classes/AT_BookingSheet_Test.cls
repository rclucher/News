// Using SeeAllData for now, will figure out how to define test data later
@isTest(SeeAllData = true)
public class AT_BookingSheet_Test {
    @isTest(SeeAllData = true)
    static void testBookingSheet() {
        
        
        Account objAccount = new Account();
        objAccount.Name = 'Test account 27';
        objAccount.No_Parent_Account__c = true;
        objAccount.BillingStreet = '69 Liz Dr';
        objAccount.BillingCity = 'DowSurry Hill';
        objAccount.BillingState = 'NSW';
        objAccount.BillingPostalCode = '2010';
        
        insert objAccount;
        
        Contact objContact = new Contact();
        objContact.FirstName = 'Test';
        objContact.LastName = 'T25';
        objContact.Email = 'test@test25.com';
        objContact.MobilePhone = '0432000000';
        objContact.AccountId = objAccount.Id;
        insert objContact;
        
        Opportunity objOpportunity = new Opportunity();
        //objOpportunity.RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'KAC' LIMIT 1].Id;
        objOpportunity.Name = 'Test Opp 27';
        objOpportunity.Amount = 1000;
        objOpportunity.AccountId = objAccount.Id;
        objOpportunity.CloseDate = System.today();
        objOpportunity.StageName = 'Discover Needs';
        objOpportunity.Revenue_Group__c = 'Retail'; //Ash added to fix testcalss failure 
        insert objOpportunity;
        
        csmso__Sales_Order__c objSalesOrder = new csmso__Sales_Order__c ();
        objSalesOrder.csmso__Opportunity__c = objOpportunity.Id;
        objSalesOrder.csmso__Advertiser__c  = objAccount.Id;
        objSalesOrder.csmso__Billing_Contact__c = objContact.Id;
        objSalesOrder.csmso__Booking_Contact__c = objContact.Id;
        objSalesOrder.Total_Duration_Price__c = 1000;
        //objSalesOrder.Total_Duration_GST__c = 200;
        //objSalesOrder.Total_Duration_Price_GST_Inclusive__c = 1200;
        objSalesOrder.Payment_Method__c = 'Credit Card';
        
        insert objSalesOrder;
        
        cscfga__Product_Basket__c objProductBasket = new cscfga__Product_Basket__c();
        objProductBasket.cscfga__Total_Price__c = 1000;
        objProductBasket.csmso__Sales_Order__c = objSalesOrder.Id;
        objProductBasket.cscfga__Opportunity__c = objOpportunity.Id;
        objProductBasket.cfgoffline__Account__c = objAccount.Id;
        insert objProductBasket;

        cscfga__Product_Configuration__c objProdConfig1 = new cscfga__Product_Configuration__c();
        //objProdConfig1.cscfga__Parent_Configuration__c = null; //Ash comment to fix testcalss failure
        objProdConfig1.Bundle_Name__c = 'XYZ';
        objProdConfig1.Platform__c = null;
        objProdConfig1.cscfga__Total_Price__c = 1000;
        objProdConfig1.Impressions_Quantity__c = 10;
        //objProdConfig1.Total_Xtend_Price__c = 100;
        objProdConfig1.Total_Print_Price__c = 100;
        objProdConfig1.Total_Digital_Price__c = 100;
        objProdConfig1.Base_Bundle_Price__c = 100;
        objProdConfig1.Total_Bundle_Price__c = 200;
        objProdConfig1.Digital_Quantity__c = 100;
        //objProdConfig1.Line_Item_Duration_Price__c = 100;
        objProdConfig1.Duration_Months__c = 10;
        //objProdConfig1.Total_Digital_Duration_Quantity__c = 10;
        //objProdConfig1.Total_Bundle_Price_GST_Inclusive__c = 1000;
        objProdConfig1.cscfga__Product_Basket__c = objProductBasket.Id;
        insert objProdConfig1;
        
        cscfga__Product_Configuration__c objProdConfig2 = new cscfga__Product_Configuration__c();
        objProdConfig2.cscfga__Parent_Configuration__c = objProdConfig1.Id;
        objProdConfig2.Bundle_Name__c = 'XYZ';
        objProdConfig2.Platform__c = 'Print';
        objProdConfig2.cscfga__Total_Price__c = 1000;
        objProdConfig2.Impressions_Quantity__c = 10;
        //objProdConfig2.Total_Xtend_Price__c = 100;
        objProdConfig2.Total_Print_Price__c = 100;
        objProdConfig2.Total_Digital_Price__c = 100;
        objProdConfig2.Base_Bundle_Price__c = 100;
        objProdConfig2.Total_Bundle_Price__c = 200;
        objProdConfig2.Digital_Quantity__c = 100;
        //objProdConfig2.Line_Item_Duration_Price__c = 100;
        objProdConfig2.Duration_Months__c = 10;
        //objProdConfig2.Total_Digital_Duration_Quantity__c = 10;
        //objProdConfig2.Total_Bundle_Price_GST_Inclusive__c = 1000;
        objProdConfig2.cscfga__Product_Basket__c = objProductBasket.Id;
        insert objProdConfig2;
        
        cscfga__Product_Configuration__c objProdConfig3 = new cscfga__Product_Configuration__c();
        objProdConfig3.cscfga__Parent_Configuration__c = objProdConfig1.Id;
        objProdConfig3.Bundle_Name__c = 'XYZ';
        objProdConfig3.Platform__c = 'Digital';
        objProdConfig3.cscfga__Total_Price__c = 1000;
        objProdConfig3.Impressions_Quantity__c = 10;
        //objProdConfig3.Total_Xtend_Price__c = 100;
        objProdConfig3.Total_Print_Price__c = 100;
        objProdConfig3.Total_Digital_Price__c = 100;
        objProdConfig3.Base_Bundle_Price__c = 100;
        objProdConfig3.Total_Bundle_Price__c = 200;
        objProdConfig3.Digital_Quantity__c = 100;
        //objProdConfig3.Line_Item_Duration_Price__c = 100;
        objProdConfig3.Duration_Months__c = 10;
        //objProdConfig3.Total_Digital_Duration_Quantity__c = 10;
        //objProdConfig3.Total_Bundle_Price_GST_Inclusive__c = 1000;
        objProdConfig3.cscfga__Product_Basket__c = objProductBasket.Id;
        insert objProdConfig3;
        
        ApexPages.StandardController controller = new ApexPages.StandardController(objSalesOrder);
            
        AT_BookingSheet booking = new AT_BookingSheet(controller);
/*
        List<cscfga__Product_Configuration__c> configs = [SELECT cscfga__Product_Basket__r.csmso__Sales_Order__c FROM cscfga__Product_Configuration__c WHERE cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Opportunity__c != null AND cscfga__Parent_Configuration__c = null];
        
        AggregateResult[] lstAggregateResults = [SELECT cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Opportunity__c, cscfga__Product_Basket__r.csmso__Sales_Order__r.Id, COUNT(Platform__c) FROM cscfga__Product_Configuration__c GROUP BY cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Opportunity__c, cscfga__Product_Basket__r.csmso__Sales_Order__r.Id HAVING cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Opportunity__c != null AND  COUNT(Platform__c) > 1 ORDER BY COUNT(Platform__c) DESC LIMIT 10];
        
        for(AggregateResult objAggregateResult : lstAggregateResults){
            String strSalesOrderId = String.valueOf(objAggregateResult.get('Id'));
            csmso__Sales_Order__c so = [SELECT Id FROM csmso__Sales_Order__c WHERE Id = : strSalesOrderId LIMIT 1];
            
            ApexPages.StandardController controller = new ApexPages.StandardController(so);
            
            AT_BookingSheet booking = new AT_BookingSheet(controller);
        }
*/
        // what do we test?
    }
}