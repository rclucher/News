/**
* @author       Kamal Sharma
* @date         2018-06-06
* @className	NXX2_TaskReportGeneratorTest
* @description  This is a test class for NXX2_TaskReportGenerator.
*/
@isTest
public class NXX2_TaskReportGeneratorTest {
	     /**
    * @author       Kamal Sharma
    * @date         2018-06-06
    * @description  This method will test the handleInboundEmail method of NXX2_InboundEmailTrigger class for negative and positive scenario.
    * @param        NA
    * @return       void
    */
    static testMethod void testFetchMyTasks() {
        User user = TestDataFactory.createUser('System Administrator','Test','Demo',null,false,false);
        System.runAs(user){
            Product_Order__c productOrder = NXX2_TestUtility.createProductOrderWithoutNode();
            Creative__c creative = NXX2_TestUtility.createCreative(productOrder.Id,'Premedia');
            List<Id> whatIdsForTask = new List<Id>();
            whatIdsForTask.add(productOrder.Id);
            whatIdsForTask.add(productOrder.Order__c);
            whatIdsForTask.add(creative.Id);
            NXX2_TestUtility.createMultipleSObjectTasks(whatIdsForTask,user.Id);
            System.assertEquals(NXX2_TaskReportGenerator.fetchMyTasks(0,true).size(),3);
        }
    }
}