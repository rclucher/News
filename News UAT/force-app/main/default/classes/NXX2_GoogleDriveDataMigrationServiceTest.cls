@isTest
public class NXX2_GoogleDriveDataMigrationServiceTest{
    public static testMethod void testContants() {
        List<Account> accounts = TestDataFactory.createAccounts(1,false);
        insert accounts;
        Test.startTest();
		Test.setMock(HttpCalloutMock.class, new NXX2_GoogleDriveAPIMockUp());
        NXX2_GoogleDriveDataMigrationService.retriveFiles('Test', 'Test','Test');
        NXX2_GoogleDriveDataMigrationService.verifyFolderExistOrNot('Test', 'Test','Test');
        NXX2_GoogleDriveDataMigrationService.createFolder('Test', 'Test','Test');
        NXX2_GoogleDriveDataMigrationService.validateFolderExistOrNotWithRecordIdIfNotCreateInDrive(accounts[0].Id, 'Test','Test');
        NXX2_GoogleDriveDataMigrationService.copyFile('Test','Test','Test');
        NXX2_GoogleDriveDataMigrationService.processFileMigration(accounts[0].Id,'Test');
        Test.stopTest();
    }
}