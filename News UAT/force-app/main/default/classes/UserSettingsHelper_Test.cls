/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
/*---------------------------------------------------------
 * Author:        Stuart Hamilton
 * Company:       Salesforce.com
 * Description:   Cache user-specific settings and config info
 * Test for:      UserSettings_Helper
 * History 
 * 12/06/2013     Stuart Hamilton Created
 * 2015-02-12     Atul Gupta      Updated
 // 2016-01-15 atul.gupta@bluewolfgroup.com
    // This class provides test coverage for
    //  - UserSettings_Helper   95%
---------------------------------------------------------*/
@isTest
private class UserSettingsHelper_Test {

    static testMethod void cyberAdSettingsTest() {
        // create user credentials for the system user
        // retrieve the credentials through the static class and check the count
        
        List<User> users = [SELECT Id, Name FROM User WHERE Id = :userInfo.getUserId()];
        
        system.debug('### users: ' + users);
        
        Map<id,list<CyberAd_User_Credential__c>> credentials = TestDataFactory.createCyberAdUserCredentials(3, users);
        list<CyberAd_User_Credential__c> tmpList = new list<CyberAd_User_Credential__c>();
        for(list<CyberAd_User_Credential__c> l : credentials.values())
        {
            tmpList.addAll(l);
        }
        
        insert tmpList;
        
        list<CyberAd_User_Credential__c> result = UserSettings_Helper.cyberAdSettings;
        system.debug('### result.size() :' + result.size());
        system.debug('### credentials.get(users[0].id).size() :' + credentials.get(users[0].id).size());
        
        system.assertEquals(result.size(), 3);
    }
	
	//Test method to cover cyberSellSettings getter setter
    static testMethod void cyberSellSettingsTest() {
    	
    	List<CyberAd_User_Credential__c> cyberAdUserList = TestDataFactory.createdCyberAdUserCredentials(Userinfo.getUserId());
		system.assertEquals(cyberAdUserList.size(), 4);
		
    	Boolean isCyberAdd = UserSettings_Helper.isCyberAddEnabled;
    	system.assertEquals(isCyberAdd, true);
    	
    	Boolean isCyberSell = UserSettings_Helper.isCyberSellEnabled;
    	system.assertEquals(isCyberSell, true);
    	
    	Boolean isAdPoint = UserSettings_Helper.isAdPointEnabled;
    	
    	String gbaType = UserSettings_Helper.createGBAType;
    	
    	String profName = UserSettings_Helper.profileName;
    	system.assertEquals('System Administrator', profName);
    	
    	Set<String> divisionsSet = UserSettings_Helper.findUserDivisions(UserInfo.getUserId());
    	system.assertEquals(divisionsSet.size(), 1);
    }
}