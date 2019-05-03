/*
 * Authour: Peter Charalambous
 * Company: Bluewolf
 * Date: 16/08/2016
 * Description: Identify if Task is NVM Task and if criteria is met, set NVM
 *              routable flag to true
 * History:
 * 16/08/2016 Peter Charalambous   Trigger helper clas created
 * 18/08/2016 David Dawson         Updated NVMCaseRouting class to update the case origin field instead of the NVM routable flag.
 * 30/01/2017 David Scullion       Updated to remove Task Record Type references
 * 22/05/2017 Jon Ng               CCESADS-210 - NVMCaseRouting - Check for Activity Task WhatID
 */

public class TaskTrigger_Helper
{
    //This function designates the Task Record Type ID to equal that of the retrieved ID
    //where the Name in the Task field is equal to 'NVM Task'
    public static void designateTaskRecordType()
    {
        //Retrieve User ID where Alias is equal to 'nserv'
        List<User> userAlias = new List<User>([SELECT Id FROM User WHERE Alias = 'nserv' LIMIT 1]);
        //Retrieve RecordType ID for NVM tasks
        List<RecordType> rType = new List<RecordType>([SELECT Id FROM RecordType WHERE SObjectType = 'task' AND Name = 'NVM Task' LIMIT 1]);
        
        if(!rtype.isEmpty() && !userAlias.isEmpty())
        {
            //Loop through Trigger.New
            for(Task t : (List<Task>)Trigger.NEW)
            {
                if(t.createdByID == userAlias[0].Id)
                {
                    //Assign RecordType ID to equal ID retrieved in query
                    t.RecordTypeID = rType[0].ID;
                }
            }
        }
    }

    //Route case through to NVM upon meeting criteria
    public static void NVMCaseRouting(List<Task> taskList)
    {

        List<RecordType> rType = new List<RecordType>([SELECT Id FROM RecordType WHERE SObjectType = 'task' AND Name = 'NVM Task' LIMIT 1]);
        
        //Create set of ID's
        Set<Id> caseID = new Set<Id>();
        
        //Retrieve Key Prefix for Case
        String caseKeyPrefix = Schema.SObjectType.Case.getKeyPrefix();

        if(!rtype.isEmpty())
        {
            //Loop through taskList, checking if RecordTypeID is equal to the one queried
            for(Task t : taskList)
            {
                //Check WhatID is not Null. Click to Call from Contacts (Campaign Member calls) will not have a related Case
                if(t.whatId != Null)
                {
                    if(t.RecordTypeID == rType[0].ID && String.valueOf(t.whatId).startsWith(caseKeyPrefix))
                    {
                        caseID.add(t.whatId);
                    }
                }    
            }

            //Query Case object where ID is in set
            //List<Case> caseList = new List<Case>([SELECT Id, CaseNumber, Owner.type, Owner.id, Owner.alias, Status FROM Case WHERE ID IN :caseID]);
            List<Case> caseList = new List<Case>([SELECT Id, CaseNumber, Owner.type, Owner.id, Owner.alias, Status,Transfer_to_Queue__c FROM Case WHERE ID IN :caseID]);
                      
            for(Case c : caseList)
            {
                //Check if Status is Queued or Owner is a queue
                //if(c.Status == 'Queued' && c.owner.type == 'Queue')
                //if(c.Status == 'Queued'&& c.owner.alias == 'nserv')
                if(c.Status == 'Queued' && c.owner.alias == 'nserv' && c.Transfer_to_Queue__c != NULL)
                {
                    c.Origin = 'Email - Inbound for Routing';
                }
               
                update caseList;
            }
                
        }                                     
    }
    
/*
Requirement By Stephan Delfino: Update Last Client Engagement DateTime when a Task is marked Completed / Done.
MA: This method has been added with reference to Jira Ticket: NR-497
We are commenting this method until the requirements are approved by Business for Tasks & Events.
*/

public static void UpdateLastClientEngagement(List<Task> taskList, Map<Id, Task> oldMap)
    {
        for(Task t : taskList)
        {
        
            Task oldStatus = oldMap.get(t.Id);
            //if status of the Task is Completed or Done & the old status is not Completed or Done
            if ((t.Status=='Completed' || t.Status=='Done') && (oldStatus.Status != 'Completed' && oldStatus.Status != 'Done')){
                List<Account> acc = new List<Account>([SELECT Id, Last_Client_Engagement__c FROM Account WHERE ID = :t.WhatID]);
                for (Account account_ID: acc){
                account_ID.Last_Client_Engagement__c = System.Now();
                }
                update acc;
            }
        }
    }
}