// 2015-12-01 darshan.gosar@bluewolfgroup.com
    // Removed seeAllData condition 
    // This class provides test coverage for
    //  - Global_Helper                94%
@isTest
private class Global_Helper_Test {
    
    @isTest 
    static void globalHelperTest() {
        
        // test record type method
        RecordType rt = [SELECT Id, Name, SobjectType FROM RecordType LIMIT 1];
        String recordTypeId = Global_Helper.getRecordTypeIdByName(rt.Name, rt.SobjectType);
        System.assertEquals(recordTypeId, rt.Id);

        // create sales Order test data
        // method contains insert DML
        Sales_Order__c so = TestDataFactory.createSalesOrder('HWT');

        // test email data for sendMessageToUsers() method.
        String subject = 'Test Email Subject';
        String message = 'Test Email Message body';
        String bodyType = 'html';
        List<String> toAddresses = new List<String>{'test@testemail.com'};
        Map<String, String> messagesByEmail = new Map<String, String>();
        messagesByEmail.put('test@testemail.com', message);

        // sendMessageToUsers(String subject, Map<String, String> messagesByEmail)
        Global_Helper.sendMessageToUsers(subject, messagesByEmail);

        // plain text email
        Global_Helper.sendMessageToUsers(subject, message, toAddresses, null);
        // html email
        Global_Helper.sendMessageToUsers(subject, message, toAddresses, bodyType);

        // notifySysAdminException (List<String> failedIds, String subject, String toAddress)
        Global_Helper.notifySysAdminException (toAddresses, subject, toAddresses[0]);

        // isEmailAddressValid
        Global_Helper.isEmailAddressValid(toAddresses[0]);

        String validFaxNumber = '612999999992';
        // isValidFax(String fax)
        System.assert(true, Global_Helper.isValidFax(validFaxNumber));

        //Global_Helper.addIdIntoSalesOrderIdSet(so.Id);
        //System.assertEquals(false,Global_Helper.isNotInSalesOrderIdSet(so.Id));

        Map<Id, Id> parentRoleIdByRoleId = Global_Helper.parentRoleIdByRoleId;

        String id1, id2;
        for (Id id : parentRoleIdByRoleId.keySet())
        {
            if (id1 != '' && id2 == null) {
                id2 = id;
                break;
            }
            if (id1 == '')
                id1 = id;
        }
        Global_Helper.isBelowRoleHierarchy(id1, id2);

        Global_Helper.getSObjecDescribetBySObjectPrefix('001');

        User u = TestDataFactory.createUser('News Integration', 'lastName', 'firstName', null, false, false);

        System.runAs(u)
        {
            Global_Helper.amIIntegrationUser();
        }

        // set arbitrary page and assign 's' parameter to page.
        PageReference pr = Page.CampaignActionPage;
        pr.getParameters().put('s', 'true');
        Test.setCurrentPage(pr);

        // 
        System.assert(Global_Helper.showHeaderAndSidebar);
    }
}