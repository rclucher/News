/*
 * Authour: Peter Charalambous
 * Company: Bluewolf
 * Date: 16/08/2016
 * Description: Test functionality of TaskTrigger
 *
 */
 @isTest

 private class nvmCallRouting_Test 
 {
  static testMethod void nvmCallRouting_Test() 
  {
    //Retrieve User ID where Alias is equal to 'nserv'
    List<User> userAlias = new List<User>([SELECT Id FROM User WHERE Alias = 'nserv' LIMIT 1]);
    System.assert(!userAlias.isEmpty(), 'User Alias is empty');

    //Retrieve ID from Group where the Type is equal to Queue
    List<Group> groupList = new List<Group>([select Id from Group where Type = 'Queue' LIMIT 1]);
    System.assert(!groupList.isEmpty(), 'Group List is empty');

    //Create new Case with Status equaled to 'Queued'
    Case c = new Case(Status = 'Queued', Ownerid = groupList[0].id, Origin = 'IVR');
    insert c;

    //Create new Task
    Task t = new Task(ActivityDate = Date.today().addDays(7), Subject='Sample Task', WhatId = c.Id, OwnerId = UserInfo.getUserId(), Status='In Progress');
    insert t;
  }
}