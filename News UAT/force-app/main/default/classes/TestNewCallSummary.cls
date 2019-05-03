/*---------------------------------------------------------
* Author: Jamie Cooper (New Voice Media)
* Date: May 2016
* Description: Test class to cover the extract skill process
* Changelog:
  - 12/05/2016 | Jamie Cooper | created and wrote the test class to cover:
    "The test class inserts a new Call Summary record which is populated with the core data. The Trigger will 
    then extract the relevant ‘skills’ from a long text string and insert into the relevant custom field. The 
    test class checks that the skills extracted are what we expect from the long string. In addition to this 
    another test is executed where the long text string does not contain any data, we ensure that the trigger 
    handles this correctly."
  - 10/06/2016 | David Dawson | updated the test class to include commenting and indentation/formatting.
 ---------------------------------------------------------*/

@isTest 
public class TestNewCallSummary {
  static testMethod void testInsertSummary(){

    NVMStatsSF__NVM_Call_Summary__c summaryToCreate = new NVMStatsSF__NVM_Call_Summary__c();

    // Insert a new call summary with ChkStr
    summaryToCreate.NVMStatsSF__NVM_Service_Name__c = 'Test Record';
    summaryToCreate.NVMStatsSF__ChkStr__c = '20150128092531-S1-0-000-Start OK|20150128092531-NA-0-001-SkillTagger~ST Consumer Overview|20150128092845-S-194-072-END~AN Thank you~Caller|';
    //Key fields

    try {
      insert summaryToCreate;
    } catch (Exception e) { 
      System.debug('An error happened, as predicted!');
    }

    // Now we try to find our new Call Summary
    List<NVMStatsSF__NVM_Call_Summary__c> newEscalation = [SELECT NVMStatsSF__NVM_Service_Name__c, Associated_Skill__C 
    from NVMStatsSF__NVM_Call_Summary__c 
    where Associated_Skill__C = 'Consumer Overview'];
    System.assertEquals(1, newEscalation.size()); 
    //Trigger should have created this record and extracted skill so Asserts should equal 1 

    NVMStatsSF__NVM_Call_Summary__c summaryToCreate2 = new NVMStatsSF__NVM_Call_Summary__c();

    // Insert a new call summary without a valid ChkStr
    summaryToCreate2.NVMStatsSF__NVM_Service_Name__c = 'Test Record 2';
    summaryToCreate2.NVMStatsSF__ChkStr__c = 'No Skill on this call';
    //Key fields

    try {
      insert summaryToCreate2;
    } catch (Exception e) { 
      System.debug('An error happened, as predicted!');
    }

    // Now we try to find our new Call Summary
    List<NVMStatsSF__NVM_Call_Summary__c> newEscalation2 = [SELECT NVMStatsSF__NVM_Service_Name__c, Associated_Skill__C 
    from NVMStatsSF__NVM_Call_Summary__c 
    where NVMStatsSF__NVM_Service_Name__c = 'Test Record 2'
    AND Associated_Skill__C = 'Consumer Overview'];
    System.assertEquals(0, newEscalation2.size());
    //No skill given in second example, so should not have populated the skill field - therefore System Asserts = 0
  }
}