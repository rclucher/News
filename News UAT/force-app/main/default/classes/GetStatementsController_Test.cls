/**
* @description  test class for GetStatementsController.cls
* 
* @author       Paul Kang
* @date         2017-11-08
**/
@isTest
private class GetStatementsController_Test {
    
    @isTest static void accessComputershare() {

        Account newAct = new Account();
        newAct.Name = 'testAccount';
        newAct.No_Parent_Account__c = True;
        insert newAct;

        // insert a sample External_Account__c record
        External_Account__c ext = new External_Account__c();
        ext.JDE_Account_Number__c = '3423706';
        ext.Customer_Account__c = newAct.Id;
        ext.External_Id__c = '1234'; // sample external id value

        insert ext;

        string id = ext.Id;

        List<User> users = TestDataFactory.createUsers(1, 'System Administrator', null, null, false);
        insert users;
        
        Test.startTest();
        
        Test.setMock(WebServiceMock.class, new svc_GvpWebServiceGenerateTokenMock());

        String resultToken = GetStatementsController.accessComputershare(id);

        Test.stopTest();

        System.assert(resultToken != null);
    }
    
    
    
}