/** 
 *
 * @author      Paul Kang, Bluewolf 
 * @description Batch Apex to process from Portfolio_Staging__c to Junction Owner and Portfolio2__
 * @description Modified 2018-02-05 Paul Kang 
 *              
 **/
@IsTest
public class PortfolioProcess_Test {

	private static Integer numberOfRecords = 100;	
    @testSetup static void setup() {
    	Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];

    	System.debug('Profile ' + p);

		List<User> userList = new List<User>();        
        for(Integer i = 0; i < numberOfRecords; i++) {
            User newUser = new User();
            newUser.FirstName = 'FirstName' + i;
            newUser.LastName = 'LastName' + i;
            newUser.Network_Username__c = 'random' + i;
            newUser.Username = 'username' + i + '@newscorp.com.au';
            newUser.Email = 'email' + i + '@newscorptest.com.au';
            newUser.Alias = 'test' + i;
            newUser.CommunityNickname = 'nickName' + i;
            newUser.TimeZoneSidKey = 'Australia/Sydney';
            newUser.LocaleSidKey = 'en_AU';
            newUser.EmailEncodingKey = 'UTF-8';
            newUser.ProfileId = p.Id;
            newUser.LanguageLocaleKey = 'en_US';
            userList.add(newUser);
        }
        insert userList;

        // Load all the staging objects
        List<Portfolio_Staging__c> stagingList = new List<Portfolio_Staging__c>();
        
        for(Integer y = 0; y < numberOfRecords; y++) {
        	Portfolio_Staging__c portStaging = new Portfolio_Staging__c();
        	portStaging.Conformed_Name__c = 'conformedName' + y;
        	portStaging.Conformed_Owner__c = 'conformedOwner' + y;
        	portStaging.Group_Name__c = 'gpName' + y;
        	portStaging.Group_Owner__c = 'gpOwner' + y;
        	portStaging.Master_Name__c = 'masterName' + y;
        	portStaging.Master_Owner__c = 'masterOwner' + y;
        	portStaging.Portfolio_Code__c = String.valueOf(y);
        	portStaging.Portfolio_Name_Owner__c = 'name_owner' + y;
        	stagingList.add(portStaging);
        }

        insert stagingList;
    }
     
	

	// Test the map for the fields
	@isTest static void test_GetUser() {
		Test.startTest();

		PortfolioProcess port = new PortfolioProcess();
		Id res = port.GetUser('vacant role 08', true);

		Test.stopTest();
		System.assertEquals(null, res);
	}

    @isTest
	static void test_PortfoliosPopulated() {
		Test.startTest();

		PortfolioProcess process = new PortfolioProcess();
		ID batchResId = Database.executeBatch(process, 200);

		Test.stopTest();

		System.assertEquals(numberOfRecords, [SELECT Count() FROM Portfolio2__c]);
	}



	
}