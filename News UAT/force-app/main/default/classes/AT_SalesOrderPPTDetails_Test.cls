@isTest
public class AT_SalesOrderPPTDetails_Test {    
    
    @isTest
    public static void UnitTest01(){
        String pubsReply;
        List<cscfga__Product_Configuration__c> cpc;
        
        Test.startTest();
        AT_SalesOrderPPTDetails atso = new AT_SalesOrderPPTDetails();
        atso.salesOrderRecordID='';
        atso.clientDiscountValue=0;
        atso.targetDiscountValue=0;
        atso.Owner_Name='Test Name';
        
        atso.Campaign_Start_Date_Formatted='01/10/2018';
        cpc = atso.getConfigs();
        System.assertNotEquals(-1, cpc.size());
        
        pubsReply = atso.getPublications();
        System.assertNotEquals(null, pubsReply);
        Test.stopTest();
    }    
    
}