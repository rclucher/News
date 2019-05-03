@isTest(seeAllData=true)
public class GenerateSalesOrderIOTest {
    
    @IsTest
    public static void testPrintAdvIO() {
        
        GenerateSalesOrderIO gsoio = new GenerateSalesOrderIO();
        cscfga__Product_Configuration__c pc = [SELECT
                                            Id,
                                            Name,
                                            cscfga__Product_Basket__r.csmso__Sales_Order__c
                                        FROM cscfga__Product_Configuration__c
                                        WHERE 
                                            cscfga__Parent_Configuration__c = null AND
                                            Name = 'Print Display'
                                            AND cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Status__c = 'Draft'
                                            AND cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Process_Message_Type__c = 'preapproved'
                                  		ORDER BY CreatedDate DESC
                                        LIMIT 1];
        System.debug('SO PrintAdv: ' + pc.cscfga__Product_Basket__r.csmso__Sales_Order__c);
        
        csdg__Doc_Config__c dc = [SELECT 
                                    Id, Name,csdg__CustomerDocumentConfigId__c
                                    From csdg__Doc_Config__c
                                  WHERE csdg__CustomerDocumentConfigId__c = 'd3a37525-3660-42e5-bbac-592143ce7c05'
                                 	LIMIT 1];
        
        csdg.CadmusHttpCalloutMock.setTestCalloutMockSuccess(dc.Id);
       	Test.startTest();
        gsoio.performAction(pc.cscfga__Product_Basket__r.csmso__Sales_Order__c);
       	Test.stopTest();
    }
    
    @IsTest
    public static void testPrintLedIO() {
        
        GenerateSalesOrderIO gsoio = new GenerateSalesOrderIO();
        cscfga__Product_Configuration__c pc = [SELECT
                                                    Id, cscfga__Product_Basket__r.csmso__Sales_Order__c
                                                FROM cscfga__Product_Configuration__c
                                                WHERE  Name = 'Print Led' 
                                                        AND cscfga__Parent_Configuration__c = null
                                               			AND cscfga__Product_Basket__r.csmso__Sales_Order__c != null
                                               			AND cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Status__c = 'Draft'
                                                        AND cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Process_Message_Type__c = 'preapproved'
                                  				ORDER BY CreatedDate DESC
                                        LIMIT 1];
        System.debug('SO PrintLed: ' + pc.cscfga__Product_Basket__r.csmso__Sales_Order__c);
        
        csdg__Doc_Config__c dc = [SELECT 
                                    Id, Name,csdg__CustomerDocumentConfigId__c
                                    From csdg__Doc_Config__c
                                  WHERE csdg__CustomerDocumentConfigId__c = 'd3a37525-3660-42e5-bbac-592143ce7c05'
                                 	LIMIT 1];
        
        csdg.CadmusHttpCalloutMock.setTestCalloutMockSuccess(dc.Id);
       	Test.startTest();
        gsoio.performAction(pc.cscfga__Product_Basket__r.csmso__Sales_Order__c);
       	Test.stopTest();
    }
    
    @IsTest
    public static void testXtendLedIO() {
        
        GenerateSalesOrderIO gsoio = new GenerateSalesOrderIO();
        cscfga__Product_Configuration__c pc = [SELECT
                                                    Id, cscfga__Product_Basket__r.csmso__Sales_Order__c
                                                FROM cscfga__Product_Configuration__c
                                                WHERE  Name = 'Xtend Led' 
                                                        AND cscfga__Parent_Configuration__c = null
                                                        AND cscfga__Product_Basket__r.csmso__Sales_Order__c != null
                                               			AND cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Status__c = 'Draft'
                                                        AND cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Process_Message_Type__c = 'preapproved'

                                                ORDER BY CreatedDate DESC
                                        LIMIT 1];
        System.debug('SO XtendLed: ' + pc.cscfga__Product_Basket__r.csmso__Sales_Order__c);
        
        csdg__Doc_Config__c dc = [SELECT 
                                    Id, Name,csdg__CustomerDocumentConfigId__c
                                    From csdg__Doc_Config__c
                                  WHERE csdg__CustomerDocumentConfigId__c = 'd3a37525-3660-42e5-bbac-592143ce7c05'
                                 	LIMIT 1];
        
        csdg.CadmusHttpCalloutMock.setTestCalloutMockSuccess(dc.Id);
       	Test.startTest();
        gsoio.performAction(pc.cscfga__Product_Basket__r.csmso__Sales_Order__c);
       	Test.stopTest();
    }
}