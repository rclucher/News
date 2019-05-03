@isTest(seeAllData = false)
public class CS_UtilsTest {

	@isTest
	public static void UtilTest(){

		Account acc       = TestDataSetupClass.createAccount();
		RecordType rtypes = [Select Name, Id From RecordType where sObjectType = 'Account' and Name = 'Prospecting Account' and isActive = true];
		acc.RecordTypeId = rtypes.Id;
		insert acc;

		Contact con = TestDataSetupClass.createContact(acc);
		insert con;

		Opportunity opp = TestDataSetupClass.createOpportunity(acc, con);
		insert opp;

		csmso__Sales_Order__c so = TestDataSetupClass.createSalesOrder(acc, opp);
		insert so;

		Test.startTest();
		CS_Utils asoClass = new CS_Utils();
		String str        = 'csmso__Sales_Order__c';
		CS_Utils.geCustomtSobjectFields(str);
		Test.stopTest();

	}

	@isTest
	public static void UtilStatResTest(){

		Account acc       = TestDataSetupClass.createAccount();
		RecordType rtypes = [Select Name, Id From RecordType where sObjectType = 'Account' and Name = 'Prospecting Account' and isActive = true];
		acc.RecordTypeId = rtypes.Id;
		insert acc;

		Contact con = TestDataSetupClass.createContact(acc);
		insert con;

		Opportunity opp = TestDataSetupClass.createOpportunity(acc, con);
		insert opp;

		csmso__Sales_Order__c so = TestDataSetupClass.createSalesOrder(acc, opp);
		insert so;

		Test.startTest();
		CS_Utils asoClass = new CS_Utils();
		String str        = 'test';
		CS_Utils.loadStaticResource(str);
		Test.stopTest();


	}

	@isTest
	public static void getFieldValueOfSafeDeepTest(){
		Account acc       = TestDataSetupClass.createAccount();
		RecordType rtypes = [Select Name, Id From RecordType where sObjectType = 'Account' and Name = 'Prospecting Account' and isActive = true];
		acc.RecordTypeId = rtypes.Id;
		insert acc;

		Contact con = TestDataSetupClass.createContact(acc);
		insert con;
		//create more depth in relationship
		acc.Primary_Contact__c = con.Id;
		update acc;

		Opportunity opp = TestDataSetupClass.createOpportunity(acc, con);
		insert opp;
		//query opportunity to get relationships for testing
		opp = [SELECT Id, Account.Name, Account.Primary_Contact__r.Name FROM Opportunity WHERE Id = :opp.Id];

		Test.startTest();
		String accName = CS_Utils.getFieldValueOfSafeDeep(opp, 'Account.Name');
		String contactName = CS_Utils.getFieldValueOfSafeDeep(opp, 'Account.Primary_Contact__r.Name');
		String invalidField = CS_Utils.getFieldValueOfSafeDeep(opp, 'SomeMadeUpName');
		Test.stopTest();
		//check results
		System.assertEquals('testAccountForSalesOrderSupportTest', accName, 'Name not as expected');
		System.assertEquals('test Con', contactName, 'Contact Name not as expected');
		System.assertEquals('', invalidField, 'Using invalid field should return empty string');
	}

	@isTest public static void incrementStringTest() {
		//expected tests
		String nullString;
		String emptyString         = '';
		String notEndingWithNumber = 'Test0001String';
		String usualFormat         = 'B-00001-001';
		//start testing
		Test.startTest();
		//results
		String nullStringResult          = CS_Utils.incrementString(nullString);
		String emptyStringResult         = CS_Utils.incrementString(emptyString);
		String notEndingWithNumberResult = CS_Utils.incrementString(notEndingWithNumber);
		String usualFormatResult         = CS_Utils.incrementString(usualFormat);
		Test.stopTest();
		//check results
		System.assertEquals(nullString, nullStringResult, 'Null value should be unchanged!');
		System.assertEquals(emptyStringResult, '1', 'Empty string should just have 1 appended!');
		System.assertEquals(notEndingWithNumberResult, notEndingWithNumber + '1', 'String that doesn\'t end with number should just have 1 appended!');
		System.assertEquals(usualFormatResult, 'B-00001-002', 'String should have last numerical part incremented while maintaining string length!');
	}
}
//Marko Comment