@isTest
public class NXX2_GoogleDriveConnectorTest{
    public static testMethod void testContants() {
        List<Account> accounts = TestDataFactory.createAccounts(1,false);
        insert accounts;
        Test.startTest();
		Test.setMock(HttpCalloutMock.class, new NXX2_GoogleDriveAPIMockUp());
        NXX2_GoogleDriveConnector.uploadFile('Test', 'Test', 'Test', 'Test');
        NXX2_GoogleDriveConnector.retriveFiles('Test');
        NXX2_GoogleDriveConnector.verifyFolderExistOrNot('Test', 'Test');
        NXX2_GoogleDriveConnector.createFolder('Test', 'Test');
        NXX2_GoogleDriveConnector.validateFolderExistOrNotWithRecordIdIfNotCreateInDrive(accounts[0].Id, 'Test');
        NXX2_GoogleDriveConnector.deleteFiles('Test');
        NXX2_GoogleDriveConnector.getFileMetaData('Test');
        NXX2_GoogleDriveConnector.uploadFileInChunks('Test', 'Test', 'Test', 'Test', 0, 100, '100');
        NXX2_GoogleDriveConnector.requestUploadUrl('Test', 'Test', 'Test', 'Test', 0, 100, '100');
        NXX2_GoogleDriveConnector.makeFilePublic('Test');
        Test.stopTest();
    }
}