@isTest
public class CS_IssuePickerPluginImplementationTest {

    @IsTest
    public static void testGetIssues() {
        String testCode = 'ABCTEST';

        csmso__SalesOrderAPI__c soApi = TestDataSetupClass.createSalesOrderAPI();
        insert soApi;

        csmso__Business_Unit__c bu = TestDataSetupClass.createBusinessUnit();
        insert bu;

        csmso__Product_Node__c pn =  TestDataSetupClass.createProductNode('testNode',bu);
        insert pn;

        pn.csmso__Code__c = pn.Id;
        update pn;

        csmso__Node_Advert_Assignment__c nAa = TestDataSetupClass.createNodeAdvAssignment('testNodeAdv',pn);
        insert nAa;

        System.debug('My nAA :' + nAa );
        System.debug('My PN : ' + PN );

        String result = new CS_IssuePickerPluginImplementation().getIssuesJSON(pn.csmso__Code__c);
    }

}