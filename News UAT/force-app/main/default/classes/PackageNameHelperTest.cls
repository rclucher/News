@isTest(seeAllData=False)
public class PackageNameHelperTest {
    
    @isTest
    public static void AddPackageInsertTest()
    {
            Account acc = TestDataSetupClass.createAccount();
            RecordType rtypes = [Select Name, Id From RecordType where sObjectType='Account' and Name = 'Prospecting Account' and isActive=true];
            acc.RecordTypeId = rtypes.Id;
            insert acc;
            
            Contact con = TestDataSetupClass.createContact(acc);
            insert con;
            
            Opportunity opp = TestDataSetupClass.createOpportunity(acc, con);
            insert opp;
            
            csmso__Sales_Order__c so = TestDataSetupClass.createSalesOrder(acc, opp);
            so.Margin__c = 0.3;
            insert so;
            
            cscfga__Product_Basket__c prodBasket = TestDataSetupClass.createProdBasket(so);
            insert prodBasket;
        
            cscfga__Configuration_Offer__c configOffer = new cscfga__Configuration_Offer__c(Name = 'Test Configuration');
            insert configOffer;
        
            cscfga__Product_Configuration__c prodConfig = new cscfga__Product_Configuration__c(Name = 'Test Configuration 1', cscfga__Product_Basket__c = prodBasket.Id,cscfga__Configuration_Status__c = 'Valid',cscfga__originating_offer__c = configOffer.Id);
            insert prodConfig;
            
            

            Test.startTest();        
            PackageNameHelper asoClass = new PackageNameHelper();
            String str = so.Id;
            PackageNameHelper.AddPackageInsert(new list<cscfga__Product_Configuration__c> {prodConfig});
            //String paStr = asoClass.performAction(str);
            Test.stopTest();
        }
    
    @isTest
    public static void AddPackageUpdateTest()
    {
            Account acc = TestDataSetupClass.createAccount();
            RecordType rtypes = [Select Name, Id From RecordType where sObjectType='Account' and Name = 'Prospecting Account' and isActive=true];
            acc.RecordTypeId = rtypes.Id;
            insert acc;
            
            Contact con = TestDataSetupClass.createContact(acc);
            insert con;
            
            Opportunity opp = TestDataSetupClass.createOpportunity(acc, con);
            insert opp;
            
            csmso__Sales_Order__c so = TestDataSetupClass.createSalesOrder(acc, opp);
            so.Margin__c = 0.3;
            insert so;
            
            cscfga__Product_Basket__c prodBasket = TestDataSetupClass.createProdBasket(so);
            insert prodBasket;
        
            cscfga__Configuration_Offer__c configOffer = new cscfga__Configuration_Offer__c(Name = 'Test Configuration');
            insert configOffer;
        
            cscfga__Product_Configuration__c prodConfig = new cscfga__Product_Configuration__c(Name = 'Test Configuration 1', cscfga__Product_Basket__c = prodBasket.Id,cscfga__Configuration_Status__c = 'Valid',cscfga__originating_offer__c = configOffer.Id);
            insert prodConfig;
            update prodConfig;
            
            Test.startTest();        
            PackageNameHelper asoClass = new PackageNameHelper();
            String str = so.Id;
            PackageNameHelper.IsFirstRun = true;
            PackageNameHelper.AddPackageUpdate(new list<cscfga__Product_Configuration__c> {prodConfig});
            //String paStr = asoClass.performAction(str);
            Test.stopTest();
        }
    

    }