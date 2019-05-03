@isTest
public with sharing class TaskManagement_Trigger_Test {
    static testMethod void test() {
        // create dummy Task
        List < Task > tasks = TestDataFactory.createTasks(40);

        Test.startTest();

        // determine due date
        List < Task > queryTasks = [SELECT ActivityDate, Usable_Due_Date__c FROM Task WHERE Id IN: tasks];

        // compare results for insert new tasks      
        Integer i = 0;
        for (Task t: queryTasks) {
            system.assertEquals(Date.today().addDays(i), t.Usable_Due_Date__c);
            t.ActivityDate = t.ActivityDate.addDays(1); // for later update test
            i++;
        }

        // compare results for update existing tasks
        update queryTasks;

        queryTasks = [SELECT ActivityDate, Usable_Due_Date__c FROM Task WHERE Id IN: tasks];

        i = 0;
        for (Task t: queryTasks) {
            system.assertEquals(Date.today().addDays(i + 1), t.Usable_Due_Date__c);
            i++;
        }

        Test.stopTest();
    }

    /*
     * This method is written to test Last Client Engagement Update
     * Date: 05-Jul-2018
     */
    static testMethod void testLCE() {

        Test.startTest();
        Integer numberOfRecords = 5;

        List < Account > accList = TestDataFactory.createAccounts(numberOfRecords, false);
        insert accList;

        // create dummy Task
        List < Task > tasks = createTasks(numberOfRecords, 'Call - Outbound', accList, true);

        // determine due date
        List < Task > queryTasks = [SELECT ActivityDate, Usable_Due_Date__c FROM Task WHERE Id IN: tasks FOR UPDATE];

        // compare results for insert new tasks      
        Integer i = 0;
        for (Task t: queryTasks) {
            Integer remainder = math.mod(i, 2);
            if (remainder == 0) {
                t.Status = 'Done';
            } else {
                t.Status = 'Completed';
            }
            i++;
        }

        update queryTasks;

        for (Task t: queryTasks) {
            system.assertEquals(t.lastModifiedDate, t.Account.Last_Client_Engagement__c);
        }

        //Changing Status at random to On Hold
        i = 0;
        for (Task t: queryTasks) {
            Integer remainder = math.mod(i, 3);
            if (remainder == 0) {
                t.Status = 'On Hold';
            } else {
                t.Status = 'Completed';
            }
            i++;
        }

        update queryTasks;

        i = 0;
        for (Task t: queryTasks) {
            Integer remainder = math.mod(i, 3);
            if (remainder == 0) {
                system.assertEquals(t.lastModifiedDate, t.Account.Last_Client_Engagement__c);
            }
            i++;
        }

        //Changing Status to Done against the whole list
        i = 0;
        for (Task t: queryTasks) {
            t.Status = 'Done';
        }

        update queryTasks;

        i = 0;
        for (Task t: queryTasks) {
            Integer remainder = math.mod(i, 3);
            if (remainder == 0) {
                system.assertEquals(t.lastModifiedDate, t.Account.Last_Client_Engagement__c);
            }
            i++;
        }

        Test.stopTest();
    }

    public static List < Task > createTasks(Integer numberOfTasks, String taskType, List < Account > whatId, Boolean insertFlag) {
        List < Task > tasks = new List < Task > ();

        for (Integer i = 0; i < numberOfTasks; i++) {
            Task t = new Task(ActivityDate = Date.today());
            t.type = taskType;
            t.WhatId = whatId[i].id;
            t.Subject = taskType;
            tasks.add(t);
        }

        if (insertFlag)
            insert tasks;
        return tasks;
    }
}