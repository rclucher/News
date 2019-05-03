/*---------------------------------------------------------------------------------------------------
* Author: Christopher Henschke
* Company: Salesforce.com
* Description: Test class for the NLM Project trigger OpportunityTeamManagement
*
*
* History:
*
* 27/01/2015  Christopher Henschke  Created
* 29/01/2015  Christopher Henschke  Updated to include the Creative Services Traffic Manager
* 2017-05-17 Item-00276 louis.wang@bluewolf.com - updated test class to work with conditional mandatory Opportunity.Contact__c
*     This class provides test coverage for
*      - OpportunityTeamManagement.cls        97%
*      - OpportunityTeamManagement.trigger    100%
*
---------------------------------------------------------------------------------------------------*/

@isTest (SeeAllData=false)
private class OpportunityTeamManagement_Trigger_Test 
{
  static testMethod void validateOpportunityTeamTrigger() 
  {
    // create test data
    createCustomSettings();
      
    List <Opportunity> opportunities = new List <Opportunity>();
    List <OpportunityTeamMember> opportunityteam = new List <OpportunityTeamMember>();
    List <OpportunityTeamMember> opportunityteam_brandstrategy = new List <OpportunityTeamMember>();
    List <OpportunityTeamMember> opportunityteam_operations = new List <OpportunityTeamMember>();
    List <OpportunityTeamMember> opportunityteam_creative = new List <OpportunityTeamMember>();
    List <OpportunityTeamMember> opportunityteam_brandstrategy2 = new List <OpportunityTeamMember>();
    List <OpportunityTeamMember> opportunityteam_operations2 = new List <OpportunityTeamMember>();
    List <OpportunityTeamMember> opportunityteam_creative2 = new List <OpportunityTeamMember>();
    
      
    // create a new account and opportunity
    opportunities = createOpportunities(1);
    insert opportunities;
    
    system.debug('@@@debug opportunities ' + opportunities);

    // test case 1: validate that on opportunity team insert the NLM Lead Brand Strategy Manager, NLM Operations and
    //              NLM Creative Services Traffic Manager roles are stamped on the opportunity

    // create an opportunity team  
    opportunityteam = createOpportunityTeam(opportunities);
    
    test.startTest();
       
    // insert the opportunity team
    insert opportunityteam;
   
    system.debug('@@@debug opportunityteam ' + opportunityteam);
       
    // query the database for the updated opportunities
    List <Opportunity> insert_OpptyList = [select ID, NLM_Opportunity_Team_Member_1__c, 
      NLM_Opportunity_Team_Member_2__c, NLM_Opportunity_Team_Member_3__c
      from Opportunity where ID IN :opportunities order by ID limit 1];
    
    system.debug('@@@debug insert_OpptyList ' + insert_OpptyList);
    
    // query the database for the associated opportunity team
    List <OpportunityTeamMember> insert_opportunityteam = [Select UserId, TeamMemberRole 
      From OpportunityTeamMember where OpportunityId IN :opportunities order by TeamMemberRole desc limit 200];
    
    system.debug('@@@debug insert_opportunityteam ' + insert_opportunityteam);
    
    // validate that the fields on the Opportunity have been updated
    for (Opportunity oppty : insert_OpptyList)
    { 
      System.assertEquals(insert_opportunityteam[3].userid, oppty.NLM_Opportunity_Team_Member_1__c); 
      System.assertEquals(insert_opportunityteam[0].userid, oppty.NLM_Opportunity_Team_Member_2__c); 
      System.assertEquals(insert_opportunityteam[2].userid, oppty.NLM_Opportunity_Team_Member_3__c); 
    }
    
    // test case 2: validate that when the NLM Lead Brand Strategy Manager, NLM Operations and 
    //              NLM Creative Services Traffic Manager roles are changed the 
    //              fields NLM_Opportunity_Team_Member_1__c, NLM_Opportunity_Team_Member_2__c and
    //              NLM_Opportunity_Team_Member_2__c on the opportunity are set to null
    
    // update opportunity team to change the role of NLM Brand Strategy Manager to Account Manager and
    // the role of NLM Operations to Customer Solutions
    for (OpportunityTeamMember opptyteam : opportunityteam)
    {
      if (opptyteam.TeamMemberRole == 'NLM Lead Brand Strategy Manager')
      {
        opptyteam.TeamMemberRole = 'Account Manager';
        opportunityteam_brandstrategy.add(opptyteam);
      }
      else if (opptyteam.TeamMemberRole == 'NLM Operations')
      {
        opptyteam.TeamMemberRole = 'Customer Solutions';
        opportunityteam_operations.add(opptyteam);
      }
      else if (opptyteam.TeamMemberRole == 'NLM Creative Services Traffic Manager')
      {
        opptyteam.TeamMemberRole = 'Market Manager';
        opportunityteam_creative.add(opptyteam);
      }
    }
      
    // update the opportunity team one record at a time. there seems to be an issue with multiple updates on the opportunity team
    // see: https://developer.salesforce.com/forums/ForumsMain?id=906F000000092BnIAI
    update opportunityteam_brandstrategy;
    update opportunityteam_operations;
    update opportunityteam_creative;
     
    // query the database for the updated opportunity team
    List <OpportunityTeamMember> update_opportunityteam = [Select UserId, TeamMemberRole 
      From OpportunityTeamMember where OpportunityId IN :opportunities order by TeamMemberRole desc limit 200]; 
     
    system.debug('@@@debug update_opportunityteam ' + update_opportunityteam);
    
    // query the database for the updated opportunities
    List <Opportunity> update_OpptyList = [select ID, NLM_Opportunity_Team_Member_1__c, 
      NLM_Opportunity_Team_Member_2__c, NLM_Opportunity_Team_Member_3__c
      from Opportunity where ID IN :opportunities order by ID limit 1];
    
    system.debug('@@@debug update_OpptyList ' + update_OpptyList);
    
    // validate that the fields on the Opportunity have been updated to null
    for (Opportunity oppty : update_OpptyList)
    { 
      System.assertEquals(NULL, oppty.NLM_Opportunity_Team_Member_1__c); 
      System.assertEquals(NULL, oppty.NLM_Opportunity_Team_Member_2__c);
      System.assertEquals(NULL, oppty.NLM_Opportunity_Team_Member_3__c); 
    }
    
    // test case 3: validate that when the NLM Lead Brand Strategy Manager, NLM Operations and  
    //              NLM Creative Services Traffic Manager users are deleted the 
    //              fields NLM_Opportunity_Team_Member_1__c, NLM_Opportunity_Team_Member_2__c and
    //              NLM_Opportunity_Team_Member_2__c on the opportunity are set to null
    
    // update opportunity team to change the role of Account Manager to NLM Brand Strategy Manager and
    // the role of Customer Solutions to NLM Operations 
    for (OpportunityTeamMember opptyteam : opportunityteam)
    {
      if (opptyteam.TeamMemberRole == 'Account Manager')
      {
        opptyteam.TeamMemberRole = 'NLM Lead Brand Strategy Manager';
        opportunityteam_brandstrategy2.add(opptyteam);
      }
      else if (opptyteam.TeamMemberRole == 'Customer Solutions')
      {
        opptyteam.TeamMemberRole = 'NLM Operations';
        opportunityteam_operations2.add(opptyteam);
      }
      else if (opptyteam.TeamMemberRole == 'Market Manager')
      {
        opptyteam.TeamMemberRole = 'NLM Creative Services Traffic Manager';
        opportunityteam_creative2.add(opptyteam);
      }
    }
    
    // update the opportunity team one record at a time. there seems to be an issue with multiple updates on the opportunity team
    // see: https://developer.salesforce.com/forums/ForumsMain?id=906F000000092BnIAI
    update opportunityteam_brandstrategy2;
    update opportunityteam_operations2;
    update opportunityteam_creative2;
        
    // delete the opportunity team one record at a time. there seems to be an issue with multiple deletes on the opportunity team
    // see: https://developer.salesforce.com/forums/ForumsMain?id=906F000000092BnIAI
    delete opportunityteam_brandstrategy2;
    delete opportunityteam_operations2;
    delete opportunityteam_creative2;
       
    // query the database for the opportunities
    List <Opportunity> delete_OpptyList = [select ID, NLM_Opportunity_Team_Member_1__c, 
      NLM_Opportunity_Team_Member_2__c, NLM_Opportunity_Team_Member_3__c
      from Opportunity where ID IN :opportunities order by ID limit 1];
    
    system.debug('@@@debug delete_OpptyList ' + delete_OpptyList);
    
    // validate that the fields on the Opportunity have been updated to null
    for (Opportunity oppty : delete_OpptyList)
    { 
      System.assertEquals(NULL, oppty.NLM_Opportunity_Team_Member_1__c); 
      System.assertEquals(NULL, oppty.NLM_Opportunity_Team_Member_2__c); 
      System.assertEquals(NULL, oppty.NLM_Opportunity_Team_Member_3__c);
    }
    
    test.stopTest();   
  }
   
/*---------------------------------------------------------------------------------------------------
* 
* Test class test data generation
*
---------------------------------------------------------------------------------------------------*/ 
     
  public static void createCustomSettings()
  {
   		 insert new NLM_Global_Settings__c  (
         					SetupOwnerId = UserInfo.getProfileId(),
         					Fire_NLM_Triggers__c  = true);
  }
    
    
  public static List <Opportunity> createOpportunities(Integer numberOfOpportunities)
  {
    // declare variables
    List <Account> accounts = new List<Account>();
    List <Opportunity> opportunities = new List <Opportunity>();
    
    // create accounts
    for (Integer i = 0 ; i < numberOfOpportunities ; i++) 
    {       
      Account account = new Account(
        Name = 'Test Account ' + String.valueOf(i),
        BillingPostalCode='2000',
        BillingCountry = 'Australia',
        BillingState = 'NSW',
        BillingCity = 'Sydney',
        BillingStreet = 'George Street',
        DPID_Primary_Address__c = '555' + String.valueOf(i),
        AccountNumber = '12345678901',
        Phone = '61021234567' + String.valueOf(i),
        Revenue_Group__c = 'Classified - Marketplace',
        No_Parent_Account__c = true,
        Total_Customer_Spend__c = 0,
        Total_Agency_Spend__c = 0,
        Total_Group_Spend__c = 0
        );      
            
      accounts.add(account);            
    }
    
    insert accounts;

    // create contact
    List<Contact> contacts = TestDataFactory.createContacts(1, accounts[0]);
    insert contacts;
        
    for (Integer i = 0 ; i < numberOfOpportunities ; i++)
    {
      Opportunity opportunity = new Opportunity(
        Name = 'Test Opportunity ' + String.valueof(i),
        CloseDate = date.today().addDays(i),
        StageName = 'Qualify Opportunity',
        Classification__c = 'New Business',
        Description = 'Test Opportunity',
        Is_Test__c = true,
        Campaign_Start_Date__c = date.today().addMonths(1),
        AccountId = accounts[i].Id,
        NLM_Opportunity_Team_Member_1__c = NULL,
        NLM_Opportunity_Team_Member_2__c = NULL,
        Contact__c = contacts[0].Id
       );
         
       opportunities.add(opportunity);
     }
     
     return opportunities;
  }
  
  public static List <OpportunityTeamMember> createOpportunityTeam(List <Opportunity> opportunities)
  {
    // declare variables
    List <User> users = new List <User>();
    Integer countofUsers = opportunities.size() * 4;
    List <OpportunityTeamMember> opportunityteam = new List <OpportunityTeamMember>();
    Integer j = 0;
    Integer k = 1;
    Integer l = 2;   
    Integer m = 3;
    
    String profileId = [Select p.Id From Profile p where name = 'NLM Key Account Manager' LIMIT 1].id;
        
    for (Integer i = 0 ; i < countofUsers ; i++)
    {
      Double r = Math.random() * 1000;
     
      User tmpUser = new User(
        firstname = 'User',
        lastname = i + r.intValue() + ' TestUser',
        alias = 'tu' + i+ r.intValue(),
        Username = 'testuser' + i + r.intValue() +  '@email.com.au.nlmtest',
        Email = 'user' + i+ r.intValue() + '@email.com.au.nlmtest',
        TimeZoneSidKey = 'GMT',
        LocaleSidKey = 'en_AU',
        EmailEncodingKey = 'ISO-8859-1',
        LanguageLocaleKey = 'en_US',
        ProfileId = profileId,
        Network_Username__c = 'testuser' + i + r.intValue()
        );
            
        users.add(tmpUser);
    }
    
    insert users;
    
    system.debug('@@@createOpportunityTeam_debug users ' + users);
          
    for (Opportunity oppty : opportunities)
    {
      OpportunityTeamMember opportunityteammember1 = new OpportunityTeamMember(
        opportunityid = oppty.id,
        userid = users[j].id,
        TeamMemberRole = 'NLM Lead Brand Strategy Manager'
      );
      
      OpportunityTeamMember opportunityteammember2 = new OpportunityTeamMember(
        opportunityid = oppty.id,
        userid = users[k].id,
        TeamMemberRole = 'NLM Operations'
      );
      
      OpportunityTeamMember opportunityteammember3 = new OpportunityTeamMember(
        opportunityid = oppty.id,
        userid = users[l].id,
        TeamMemberRole = 'NLM Creative Services Traffic Manager'
      );
      
      OpportunityTeamMember opportunityteammember4 = new OpportunityTeamMember(
        opportunityid = oppty.id,
        userid = users[m].id,
        TeamMemberRole = 'NLM Sales Producer'
      );
      
      opportunityteam.add(opportunityteammember1);
      opportunityteam.add(opportunityteammember2);
      opportunityteam.add(opportunityteammember3);
      opportunityteam.add(opportunityteammember4);
      
      system.debug('@@@createOpportunityTeam_debug opportunityteam ' + opportunityteam);
      
      j = j + 4;
      k = k + 4;
      l = l + 4;
      m = m + 4;
    }
    
    return opportunityteam;
  }
  
}