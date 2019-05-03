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
@isTest(SeeAllData=false)
private class Answer2Management_Test
{
	@testSetup static void runSetupUtil()
	{
		
	}


	/*------------------------------------------------------------
	Author:			Mike Jupp
	Company:		CloudSense
	Description:	Create and update Answer2 records
					Check that the Change History field is updated correctly
	History
	<Date>		<Authors Name>		<Brief Description of Change>
	Jul 18		Mike Jupp			Created
	------------------------------------------------------------*/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	static testMethod void testAnswer2Trigger()
	{
		// Create test data
		// Answer2
		list<Answer2__c> li_Answers = new list<Answer2__c>();
		
		li_Answers.add(new Answer2__c(Question_Text__c = 'Question1', Answer_Checkbox__c = true));
		li_Answers.add(new Answer2__c(Question_Text__c = 'Question2', Answer_Currency__c = 123.45));
		li_Answers.add(new Answer2__c(Question_Text__c = 'Question3', Answer_Date__c = system.today()));
		li_Answers.add(new Answer2__c(Question_Text__c = 'Question4', Answer_Email__c = 'homer.simpson@snpp.com'));
		li_Answers.add(new Answer2__c(Question_Text__c = 'Question5', Answer_Long_Text__c = 'some long text'));
		li_Answers.add(new Answer2__c(Question_Text__c = 'Question6', Answer_Numeric__c = 123));
		li_Answers.add(new Answer2__c(Question_Text__c = 'Question7', Answer_Percent__c = 5));
		li_Answers.add(new Answer2__c(Question_Text__c = 'Question8', Answer_Phone__c = '0211112222'));
		li_Answers.add(new Answer2__c(Question_Text__c = 'Question9', Answer_Text__c = 'some text'));
		li_Answers.add(new Answer2__c(Question_Text__c = 'Question10', Answer_Url__c = 'https://cloudsense.com'));
		
		// Start
		test.startTest();

		/***********************************************************************************************************
			Insert records
		***********************************************************************************************************/
		insert li_Answers;
		
		// Inspect the results
		map<string, Answer2__c> map_Answers1 = new map<string, Answer2__c>();
		map<id, Answer2__c> map_Answerst = new map<id, Answer2__c>();
		
		for (Answer2__c sAnswer :	[	select	id,
												Question_Text__c,
												Change_History__c
										from	Answer2__c
									])
		{
			map_Answers1.put(sAnswer.Question_Text__c, sAnswer);
			map_Answerst.put(sAnswer.id, sAnswer);
		}
		
		system.debug('*** map_Answers1 ***' + map_Answers1);

		Answer2__c sAnswer1 = map_Answers1.get('Question1');
		Answer2__c sAnswer2 = map_Answers1.get('Question2');
		Answer2__c sAnswer3 = map_Answers1.get('Question3');
		Answer2__c sAnswer4 = map_Answers1.get('Question4');
		Answer2__c sAnswer5 = map_Answers1.get('Question5');
		Answer2__c sAnswer6 = map_Answers1.get('Question6');
		Answer2__c sAnswer7 = map_Answers1.get('Question7');
		Answer2__c sAnswer8 = map_Answers1.get('Question8');
		Answer2__c sAnswer9 = map_Answers1.get('Question9');
		Answer2__c sAnswer10 = map_Answers1.get('Question10');
		
		checkChangeHistory(sAnswer1, 'true', 1);
		checkChangeHistory(sAnswer2, '123.45', 1);
		checkChangeHistory(sAnswer3, string.valueOf(system.today()), 1);
		checkChangeHistory(sAnswer4, 'homer.simpson@snpp.com', 1);
		checkChangeHistory(sAnswer5, 'some long text', 1);
		checkChangeHistory(sAnswer6, '123', 1);
		checkChangeHistory(sAnswer7, '5', 1);
		checkChangeHistory(sAnswer8, '0211112222', 1);
		checkChangeHistory(sAnswer9, 'some text', 1);
		checkChangeHistory(sAnswer10, 'https://cloudsense.com', 1);
		
		/***********************************************************************************************************
			Update records
		***********************************************************************************************************/
		sAnswer1.Answer_Checkbox__c = false;
		sAnswer2.Answer_Currency__c = 567.89;
		sAnswer3.Answer_Date__c = system.today().addDays(3);
		sAnswer4.Answer_Email__c = 'marge.simpson@gmail.com';
		sAnswer5.Answer_Long_Text__c = 'some more long text';
		sAnswer6.Answer_Numeric__c = 456;
		sAnswer7.Answer_Percent__c = 12;
		sAnswer8.Answer_Phone__c = '0344445555';
		sAnswer9.Answer_Text__c = 'some more text';
		sAnswer10.Answer_Url__c = 'https://cloudsensesolutions.com';
		
		li_Answers = new list<Answer2__c>();
		li_Answers.add(sAnswer1);
		li_Answers.add(sAnswer2);
		li_Answers.add(sAnswer3);
		li_Answers.add(sAnswer4);
		li_Answers.add(sAnswer5);
		li_Answers.add(sAnswer6);
		li_Answers.add(sAnswer7);
		li_Answers.add(sAnswer8);
		li_Answers.add(sAnswer9);
		li_Answers.add(sAnswer10);
		
		update li_Answers;
		
		// Inspect the results
		map<string, Answer2__c> map_Answers2 = new map<string, Answer2__c>();
		
		for (Answer2__c sAnswer :	[	select	id,
												Question_Text__c,
												Change_History__c
										from	Answer2__c
									])
		{
			map_Answers2.put(sAnswer.Question_Text__c, sAnswer);
		}
		
		system.debug('*** map_Answers2 ***' + map_Answers2);

		sAnswer1 = map_Answers2.get('Question1');
		sAnswer2 = map_Answers2.get('Question2');
		sAnswer3 = map_Answers2.get('Question3');
		sAnswer4 = map_Answers2.get('Question4');
		sAnswer5 = map_Answers2.get('Question5');
		sAnswer6 = map_Answers2.get('Question6');
		sAnswer7 = map_Answers2.get('Question7');
		sAnswer8 = map_Answers2.get('Question8');
		sAnswer9 = map_Answers2.get('Question9');
		sAnswer10 = map_Answers2.get('Question10');
		
		checkChangeHistory(sAnswer1, 'false', 2);
		checkChangeHistory(sAnswer2, '567.89', 2);
		checkChangeHistory(sAnswer3, string.valueOf(system.today().addDays(3)), 2);
		checkChangeHistory(sAnswer4, 'marge.simpson@gmail.com', 2);
		checkChangeHistory(sAnswer5, 'some more long text', 2);
		checkChangeHistory(sAnswer6, '456', 2);
		checkChangeHistory(sAnswer7, '12', 2);
		checkChangeHistory(sAnswer8, '0344445555', 2);
		checkChangeHistory(sAnswer9, 'some more text', 2);
		checkChangeHistory(sAnswer10, 'https://cloudsensesolutions.com', 2);

		/***********************************************************************************************************
			Update records again - change history should not be updated
		***********************************************************************************************************/
		li_Answers = new list<Answer2__c>();
		li_Answers.add(sAnswer1);
		li_Answers.add(sAnswer2);
		li_Answers.add(sAnswer3);
		li_Answers.add(sAnswer4);
		li_Answers.add(sAnswer5);
		li_Answers.add(sAnswer6);
		li_Answers.add(sAnswer7);
		li_Answers.add(sAnswer8);
		li_Answers.add(sAnswer9);
		li_Answers.add(sAnswer10);

		update li_Answers;
		
		test.stopTest();

		// Inspect the results
		map<string, Answer2__c> map_Answers3 = new map<string, Answer2__c>();
		
		for (Answer2__c sAnswer :	[	select	id,
												Question_Text__c,
												Change_History__c
										from	Answer2__c
									])
		{
			map_Answers3.put(sAnswer.Question_Text__c, sAnswer);
		}
		
		system.debug('*** map_Answers3 ***' + map_Answers3);

		sAnswer1 = map_Answers3.get('Question1');
		sAnswer2 = map_Answers3.get('Question2');
		sAnswer3 = map_Answers3.get('Question3');
		sAnswer4 = map_Answers3.get('Question4');
		sAnswer5 = map_Answers3.get('Question5');
		sAnswer6 = map_Answers3.get('Question6');
		sAnswer7 = map_Answers3.get('Question7');
		sAnswer8 = map_Answers3.get('Question8');
		sAnswer9 = map_Answers3.get('Question9');
		sAnswer10 = map_Answers3.get('Question10');
		
		checkChangeHistory(sAnswer1, 'false', 2);
		checkChangeHistory(sAnswer2, '567.89', 2);
		checkChangeHistory(sAnswer3, string.valueOf(system.today().addDays(3)), 2);
		checkChangeHistory(sAnswer4, 'marge.simpson@gmail.com', 2);
		checkChangeHistory(sAnswer5, 'some more long text', 2);
		checkChangeHistory(sAnswer6, '456', 2);
		checkChangeHistory(sAnswer7, '12', 2);
		checkChangeHistory(sAnswer8, '0344445555', 2);
		checkChangeHistory(sAnswer9, 'some more text', 2);
		checkChangeHistory(sAnswer10, 'https://cloudsensesolutions.com', 2);

		CS_GenericTriggerHandler a2m = new CS_GenericTriggerHandler();
		a2m.doAfterInsert(map_Answerst);
		
		List<Answer2__c> ansTestList = new List<Answer2__c>();
		ansTestList = map_Answerst.values();
		a2m.doBeforeInsert(ansTestList);
		a2m.doBeforeUpdate(map_Answerst,map_Answerst);
		a2m.doAfterUpdate(map_Answerst,map_Answerst);
		a2m.doBeforeDelete(map_Answerst);
		a2m.doAfterDelete(map_Answerst);
		a2m.doAfterUnDelete(map_Answerst);
	}

	/*------------------------------------------------------------
	Author:			Mike Jupp
	Company:		CloudSense
	Description:	Delete and undelete Answer2 records
					No code to test - this is just to improve coverage
	History
	<Date>		<Authors Name>		<Brief Description of Change>
	Aug 18		Mike Jupp			Created
	------------------------------------------------------------*/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	static testMethod void testDeleteUndelete()
	{
		// Create test data
		// Answer2
		Answer2__c sAnswer2 = new Answer2__c(Question_Text__c = 'Question1', Answer_Checkbox__c = true);
		
		insert sAnswer2;
		
		// Start
		test.startTest();

		/***********************************************************************************************************
			Delete record
		***********************************************************************************************************/
		delete sAnswer2;

		/***********************************************************************************************************
			Undelete record
		***********************************************************************************************************/
		undelete sAnswer2;
	}
	
	private static void checkChangeHistory(Answer2__c sAnswer2, string value, integer iNumberofEntries)
	{
		// Check that there actually is some change history
		system.assertEquals(false, string.isBlank(sAnswer2.Change_History__c), 'Change history missing for record ' + sAnswer2.Question_Text__c);
		
		list<CS_Questions_Utilities.ChangeHistoryWrapper> li_ChangeHistory = 
			(list<CS_Questions_Utilities.ChangeHistoryWrapper>)JSON.deserialize(sAnswer2.Change_History__c, list<CS_Questions_Utilities.ChangeHistoryWrapper>.class);
		
		system.assertEquals(iNumberofEntries, li_ChangeHistory.size(), 'Change history number of entries not as expected - record ' + sAnswer2.Question_Text__c);
		system.assertEquals(value, li_ChangeHistory[iNumberofEntries - 1].whatChanged, 'Change history saved value not as expected - record ' + sAnswer2.Question_Text__c);
	}

}