//<!--
//	This is the first of many controllers to provide the Campaign Execution functionality in Lightning Sales Console.

//	Author: LBK
//	Date: 	2018-10-16
//-->
public with sharing class CampaignExecutionController {
	//public CampaignExecutionController() {
		
	//}

	@AuraEnabled
	public static Campaign getCampaign(Id campaignId){
		Campaign objCampaign = [SELECT 	Id, Name, Type, NEWS_Campaign_Type__c, Hide_Column_from_Campaign_Exec__c, Default_Sort_Field_for_Campaign_Exec__c, Default_Sort_Order_for_Campaign_Exec__c, Allow_DNC_Calls__c 
								FROM Campaign WHERE Id =: campaignId LIMIT 1];
		return objCampaign;
	}

  @AuraEnabled
  public static Id getCurrentUserId(){
    return UserInfo.getUserId();
  }
  
  @AuraEnabled
  public static CampaignExecutionSearchWrapper resetCampaignExecutionSearchWrapper(){
    CampaignExecutionSearchWrapper objCampaignExecutionSearchWrapper = new CampaignExecutionSearchWrapper();
    objCampaignExecutionSearchWrapper.searchLead_Contact_Name= '';
    objCampaignExecutionSearchWrapper.searchCompanyOrAccount= '';
    objCampaignExecutionSearchWrapper.searchExecution_Status= '';
    objCampaignExecutionSearchWrapper.searchLast_Booking_Line_Item_Publication_Divs= '';
    objCampaignExecutionSearchWrapper.searchStatus= '';
    objCampaignExecutionSearchWrapper.filterCall_Count= '';
    objCampaignExecutionSearchWrapper.searchCall_Count= '';
    objCampaignExecutionSearchWrapper.filterAge_In_List= '';
    objCampaignExecutionSearchWrapper.searchAge_In_List= '';
    objCampaignExecutionSearchWrapper.filterLast_Booking_Value= '';
    objCampaignExecutionSearchWrapper.searchLast_Booking_Value= ''; 
    objCampaignExecutionSearchWrapper.filterResponse_DateTime= '';
    objCampaignExecutionSearchWrapper.filterCall_Back_Date= '';
    objCampaignExecutionSearchWrapper.searchResponse_DateTime= null;
    objCampaignExecutionSearchWrapper.searchCall_Back_Date= null;
    objCampaignExecutionSearchWrapper.includeFilterOptions = false;
    return objCampaignExecutionSearchWrapper;
  }

	@AuraEnabled
	public static List<SelectOptionWrapper> getStatus()
  {
     List<SelectOptionWrapper> options = new List<SelectOptionWrapper>();
          
     Schema.DescribeFieldResult fieldResult =  CampaignMember.Status.getDescribe();
     List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
     //options.add(new SelectOption('None', 'None'));
                 
     for( Schema.PicklistEntry f : ple)
     {
        SelectOptionWrapper objSelectOptionWrapper = new SelectOptionWrapper();
     	  objSelectOptionWrapper.optionLabel = f.getLabel();
     	  objSelectOptionWrapper.optionValue = f.getValue();
        options.add(objSelectOptionWrapper);
     }
     system.debug('CampaignExecutionController :: getStatus :: options ::' + options);
     return options;
  }
  
  @AuraEnabled
  public static List<SelectOptionWrapper> getExecutionStatus()
  {
     List<SelectOptionWrapper> options = new List<SelectOptionWrapper>();
          
     Schema.DescribeFieldResult fieldResult =  CampaignMember.Execution_Status__c.getDescribe();
     List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
     //options.add(new SelectOption('None', 'None'));
                 
     for( Schema.PicklistEntry f : ple)
     {
     	  SelectOptionWrapper objSelectOptionWrapper = new SelectOptionWrapper();
     	  objSelectOptionWrapper.optionLabel = (String) f.getLabel();
     	  objSelectOptionWrapper.optionValue = (String) f.getValue();
        options.add(objSelectOptionWrapper);
     }
     system.debug('CampaignExecutionController :: getExecutionStatus :: options ::' + options);
     return options;
  }

  @AuraEnabled
  public static List<SelectOptionWrapper> getCampaignMemberClassification()
  {
     List<SelectOptionWrapper> options = new List<SelectOptionWrapper>();
          
     	  SelectOptionWrapper objSelectOptionWrapper = new SelectOptionWrapper();
     	  objSelectOptionWrapper.optionLabel = 'To Do';// + (nCountToDo>0?' (' + nCountToDo + ')':'');
     	  objSelectOptionWrapper.optionValue = 'ToDo';
        options.add(objSelectOptionWrapper);

        objSelectOptionWrapper = new SelectOptionWrapper();
     	  objSelectOptionWrapper.optionLabel = 'Not Started';// + (nCountNotStarted>0?' (' + nCountNotStarted + ')':'');
     	  objSelectOptionWrapper.optionValue = 'NotStarted';
        options.add(objSelectOptionWrapper);

        objSelectOptionWrapper = new SelectOptionWrapper();
     	  objSelectOptionWrapper.optionLabel = 'My Calls To Do';// + (nCountMyCallsToDo>0?' (' + nCountMyCallsToDo + ')':'');
     	  objSelectOptionWrapper.optionValue = 'MyCallsToDo';
        options.add(objSelectOptionWrapper);

        objSelectOptionWrapper = new SelectOptionWrapper();
     	  objSelectOptionWrapper.optionLabel = 'All Calls To Do';// + (nCountAllCallsToDo>0?' (' + nCountAllCallsToDo + ')':'');
     	  objSelectOptionWrapper.optionValue = 'AllCallsToDo';
        options.add(objSelectOptionWrapper);

        objSelectOptionWrapper = new SelectOptionWrapper();
     	  objSelectOptionWrapper.optionLabel = 'My Completed';// + (nCountMyCompleted>0?' (' + nCountMyCompleted + ')':'');
     	  objSelectOptionWrapper.optionValue = 'MyCompleted';
        options.add(objSelectOptionWrapper);

        objSelectOptionWrapper = new SelectOptionWrapper();
     	  objSelectOptionWrapper.optionLabel = 'All Completed';// + (nCountAllCompleted>0?' (' + nCountAllCompleted + ')':'');
     	  objSelectOptionWrapper.optionValue = 'AllCompleted';
        options.add(objSelectOptionWrapper);

        objSelectOptionWrapper = new SelectOptionWrapper();
     	  objSelectOptionWrapper.optionLabel = 'All';// + (nCountAll>0?' (' + nCountAll + ')':'');
     	  objSelectOptionWrapper.optionValue = 'All';
        options.add(objSelectOptionWrapper);

     system.debug('CampaignExecutionController :: getCampaignMemberClassification :: options ::' + options);
     return options;
  }

	//private static Integer nCountAll  = 0;
 // private static Integer nCountToDo  = 0;
 // private static Integer nCountNotStarted  = 0;
 // private static Integer nCountMyCallsToDo  = 0;
 // private static Integer nCountAllCallsToDo  = 0;
 // private static Integer nCountMyCompleted  = 0;
 // private static Integer nCountAllCompleted  = 0;

  @AuraEnabled
  public static Map<String, List<CampaignMember>> getSearchResults(Campaign campaign, String campaignExecutionSearchWrapperJSON, String sortField, String sortDir){
  	Map<String, List<CampaignMember>> output = new Map<String, List<CampaignMember>>();    	
  	List<CampaignMember> lstAll = new List<CampaignMember>();
  	List<CampaignMember> lstToDo = new List<CampaignMember>();
  	List<CampaignMember> lstNotStarted = new List<CampaignMember>();
  	List<CampaignMember> lstMyCallsToDo = new List<CampaignMember>();
  	List<CampaignMember> lstAllCallsToDo = new List<CampaignMember>();
  	List<CampaignMember> lstMyCompleted = new List<CampaignMember>();
  	List<CampaignMember> lstAllCompleted = new List<CampaignMember>();

  	Map<String, String> mapToDo = new Map<String, String>();
  	mapToDo.put('', '');
  	mapToDo.put('Not Started', 'Not Started');
  	mapToDo.put('Attempted', 'Attempted');
  	mapToDo.put('Call to Do', 'Call to Do');
  	mapToDo.put('Call Limit Reached', 'Call Limit Reached');
  	
  	Map<String, String> mapNotStarted = new Map<String, String>();
  	mapNotStarted.put('', '');
  	mapNotStarted.put('Not Started', 'Not Started');
  	
  	Map<String, String> mapCallsToDo = new Map<String, String>();
  	mapCallsToDo.put('Call to Do', 'Call to Do');
  	
  	Map<String, String> mapCompleted = new Map<String, String>();
  	mapCompleted.put('Completed', 'Completed');

  	CampaignExecutionSearchWrapper campaignExecutionSearchWrapper = (CampaignExecutionSearchWrapper)JSON.deserialize(campaignExecutionSearchWrapperJSON, CampaignExecutionSearchWrapper.class);
  	String queryString = getQueryString(campaign, campaignExecutionSearchWrapper, sortField, sortDir);
  	List<CampaignMember> lstCampaignMembers = (List<CampaignMember>)Database.query(queryString);

  	if(lstCampaignMembers.size() > 0){
  		lstAll = lstCampaignMembers;
  		for(CampaignMember objCampaignMember : lstCampaignMembers){
  			String sExecutionStatus = String.valueOf(objCampaignMember.Execution_Status__c);
  			if(sExecutionStatus == null){
  				sExecutionStatus = '';
  			}
  			if(mapToDo.containsKey(sExecutionStatus)){
  				lstToDo.add(objCampaignMember);
  			}
  			if(objCampaignMember.Locked_By__r.Id == UserInfo.getUserId()){
            lstMyCallsToDo.add(objCampaignMember);
        }
        if(mapCallsToDo.containsKey(sExecutionStatus)){
            lstAllCallsToDo.add(objCampaignMember);
        }            
        if(mapNotStarted.containsKey(sExecutionStatus) && objCampaignMember.Locked_By__c == null){
            lstNotStarted.add(objCampaignMember);
        }           
        if(mapCompleted.containsKey(sExecutionStatus)){
            lstAllCompleted.add(objCampaignMember);
            if(objCampaignMember.Locked_By__r.Id == UserInfo.getUserId()){
            	lstMyCompleted.add(objCampaignMember);
            }
        }
  		}
  	}

  	output.put('All', lstAll);
  	//nCountAll = lstAll.size();
  	output.put('ToDo', lstToDo);
  	//nCountToDo = lstToDo.size();
  	output.put('NotStarted', lstNotStarted);
  	//nCountNotStarted = lstNotStarted.size();
  	output.put('MyCallsToDo', lstMyCallsToDo);
  	//nCountMyCallsToDo = lstMyCallsToDo.size();
  	output.put('AllCallsToDo', lstAllCallsToDo);
  	//nCountAllCallsToDo = lstAllCallsToDo.size();
  	output.put('MyCompleted', lstMyCompleted);
  	//nCountMyCompleted = lstMyCompleted.size();
  	output.put('AllCompleted', lstAllCompleted);
  	//nCountAllCompleted = lstAllCompleted.size();

  	return output;
  }


  /* 24-05-2019 AdSales 272 darshan.gosar@bluewolfgroup.com
      Added new method add filter criteria in query based on filter selection on UI  */
  private static string applyFilters(String filterValue, String field, String searchValue){
      String temp = '';        
      
      if(filterValue == 'equals')
          temp = ' And ' + field + ' = ' + searchValue;
      
      if(filterValue == 'not equals to')
          temp = ' And ' + field + ' != ' + searchValue;
      
      if(filterValue == 'less than')
          temp = ' And ' + field + ' < ' + searchValue;
      
      if(filterValue == 'greater than')
          temp = ' And ' + field + ' > ' + searchValue;
      
      if(filterValue == 'less or equal')
          temp = ' And ' + field + ' <= ' + searchValue;
      
      if(filterValue == 'greater or equal')
          temp = ' And ' + field + ' >= ' + searchValue;        
      
      return temp;
  }
  

  /* 24-05-2019 AdSales 272 darshan.gosar@bluewolfgroup.com
      Added new method add filter criteria in query based on filter selection on UI  */       
  private static string applyDateFilters(String filterValue, String field, Date dateValue){
      String temp = '';
      String searchValue = '';        
      
      DateTime d = datetime.newInstance(dateValue, Time.newInstance(0,0,0,0));
      String sameDay = d.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
      String nextDay = d.addDays(1).formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
      
      if(filterValue == 'equals')
          temp = ' And ' + field + ' > ' + sameDay + ' And ' + field + ' < ' + nextDay;
      
      if(filterValue == 'not equals to')
          temp = ' And ((' + field + ' < ' + sameDay + ' OR ' + field + ' > ' + nextDay + ') OR ' + field + '=' + 'NULL)';
      
      if(filterValue == 'less than')
          temp = ' And ' + field + ' < ' + sameDay;
      
      if(filterValue == 'greater than')
          temp = ' And ' + field + ' > ' + nextDay;
      
      if(filterValue == 'less or equal')
          temp = ' And ' + field + ' < ' + nextDay;
      
      if(filterValue == 'greater or equal')
          temp = ' And ' + field + ' > ' + sameDay;        
      
      return temp;
  }
  
  // generate query string for different campaign lists according to different statuses
  private static String getQueryString(Campaign campaign, CampaignExecutionSearchWrapper campaignExecutionSearchWrapper, String sortField, String sortDir)
  {
      String queryString = 'Select c.Status, c.Execution_Status__c, c.Response_Type__c, c.Id, c.CreatedDate, c.ContactId, c.LeadId, c.CampaignId, c.Lead.Phone_DNC_Is_Contactable__c, '
                                   + ' c.Contact.Home_Phone_on_DNC__c, c.CompanyOrAccount__c, c.Account__c, c.Locked_By__c, c.Contact.Name, c.Lead.Name, c.Contact.DNC_A_Number_Is_Contactable__c,  c.Lead.DNC_A_Number_Is_Contactable__c, '
                                   + 'c.Campaign.Allow_DNC_Calls__c,In_Progress__c, c.Contact.Mobile_on_DNC__c, c.Account__r.Name, c.Account__r.Id, Completed_by__c, Date_Completed__c,  '
                                   + 'Age_in_List__c, Call_Count__c, Call_Back_Date__c, Response_Datetime__c, Response_Comment__c, Locked_By__r.Name, Last_Booking_Value__c, Last_Booking_Line_Item_Publication_Divs__c, Response_Sub_Type__c, '
                                   + 'Campaign.Hide_Column_from_Campaign_Exec__c, Campaign.Default_Sort_Order_for_Campaign_Exec__c, Campaign.Default_Sort_Field_for_Campaign_Exec__c, Member_Type__c, '
                                   + 'DNC_A_Number_is_Contactable__c '
                                   + 'From CampaignMember c '
                                   + 'Where c.CampaignId = \'' + campaign.Id + '\' ';
      
      if(!campaign.Allow_DNC_Calls__c)
      {
          queryString += ' AND (DNC_A_Number_is_Contactable__c=true OR DNC_Override__c=true)'; 
      }   
           
      if(campaignExecutionSearchWrapper.includeFilterOptions){
          
          if(campaignExecutionSearchWrapper.searchLead_Contact_Name != null && campaignExecutionSearchWrapper.searchLead_Contact_Name != '')
          {
              queryString += ' And ( c.lead.name like \'%'+String.escapeSingleQuotes(campaignExecutionSearchWrapper.searchLead_Contact_Name)+'%\'';
              queryString += ' Or c.contact.name like \'%'+String.escapeSingleQuotes(campaignExecutionSearchWrapper.searchLead_Contact_Name)+'%\')';
          }
          if(campaignExecutionSearchWrapper.searchCompanyOrAccount != null && campaignExecutionSearchWrapper.searchCompanyOrAccount != '') queryString += ' And c.CompanyOrAccount__c like \'%'+String.escapeSingleQuotes(campaignExecutionSearchWrapper.searchCompanyOrAccount)+'%\'';
          if(campaignExecutionSearchWrapper.searchExecution_Status != null && campaignExecutionSearchWrapper.searchExecution_Status != '' && campaignExecutionSearchWrapper.searchExecution_Status != 'None') queryString += ' And c.Execution_Status__c =\''+campaignExecutionSearchWrapper.searchExecution_Status+'\'';

          //searchStatus
          //if(campaignExecutionSearchWrapper.searchStatus != null && campaignExecutionSearchWrapper.searchStatus != '' && campaignExecutionSearchWrapper.searchStatus != 'None') queryString += ' And c.Execution_Status__c =\''+campaignExecutionSearchWrapper.searchStatus+'\'';
          
          if(campaignExecutionSearchWrapper.searchLast_Booking_Line_Item_Publication_Divs != null && campaignExecutionSearchWrapper.searchLast_Booking_Line_Item_Publication_Divs != '') queryString += ' And c.Last_Booking_Line_Item_Publication_Divs__c  Like \'%' + String.escapeSingleQuotes(campaignExecutionSearchWrapper.searchLast_Booking_Line_Item_Publication_Divs) + '%\'';
          if(campaignExecutionSearchWrapper.searchLast_Booking_Value != null && campaignExecutionSearchWrapper.searchLast_Booking_Value != '')queryString += applyFilters(campaignExecutionSearchWrapper.filterLast_Booking_Value, 'c.Last_Booking_Value__c', campaignExecutionSearchWrapper.searchLast_Booking_Value);
          if(campaignExecutionSearchWrapper.searchCall_Count != null && campaignExecutionSearchWrapper.searchCall_Count != '')queryString += applyFilters(campaignExecutionSearchWrapper.filterCall_Count, 'c.Call_Count__c', campaignExecutionSearchWrapper.searchCall_Count);
          if(campaignExecutionSearchWrapper.searchAge_In_List != null && campaignExecutionSearchWrapper.searchAge_In_List != '')queryString += applyFilters(campaignExecutionSearchWrapper.filterAge_In_List, 'c.Age_in_List__c', campaignExecutionSearchWrapper.searchAge_In_List);
          if(campaignExecutionSearchWrapper.searchResponse_DateTime != null) queryString += applyDateFilters(campaignExecutionSearchWrapper.filterResponse_DateTime, 'c.Response_Datetime__c', campaignExecutionSearchWrapper.searchResponse_DateTime);
          if(campaignExecutionSearchWrapper.searchCall_Back_Date != null) queryString += applyDateFilters(campaignExecutionSearchWrapper.filterCall_Back_Date, 'c.Call_Back_Date__c', campaignExecutionSearchWrapper.searchCall_Back_Date);
      }

      if(String.isNotBlank(sortField) && String.isNotBlank(sortDir))
      {
          if(sortField=='CompanyOrAccount')
          {
              queryString += ' Order By CompanyOrAccount__c ' + sortDir + ', Age_in_List__c ';
          }
          else if(sortField=='fullName')
          {
              queryString += ' Order By Full_Name__c ' + sortDir + ', Age_in_List__c ';
          }
          else if(sortField=='lastBookingValue')
          {
              queryString += ' Order By Last_Booking_Value__c ' + sortDir + ', Age_in_List__c ';
          }
          
          /* 24-05-2019 AdSales 272 darshan.gosar@bluewolfgroup.com
              Added new sort condition for field Last_Booking_Line_Item_Publication_Divs__c  */                
          else if(sortField=='lastBookingLineItemPublicationDivs')
          {
              queryString += ' Order By Last_Booking_Line_Item_Publication_Divs__c ' + sortDir + ', Age_in_List__c ';
          }
          else if(sortField=='executionStatus')
          {
              queryString += ' Order By Execution_Status__c ' + sortDir + ', Age_in_List__c ';
          }
          else if(sortField=='status')
          {
              queryString += ' Order By Status ' + sortDir + ', Age_in_List__c ';
          }
          else if(sortField=='callBackDate')
          {
              queryString += ' Order By Call_Back_Date__c ' + sortDir + ', Age_in_List__c ';
          }
          else if(sortField=='lockedBy')
          {
              queryString += ' Order By Locked_By__r.Name ' + sortDir + ', Age_in_List__c ';
          }
          else if(sortField=='ageInList')
          {
              queryString += ' Order By Age_in_List__c ' + sortDir + ' ';
          }
      }
      else if(campaign.NEWS_Campaign_Type__c == 'Retention' || campaign.NEWS_Campaign_Type__c == 'Contact Plan')
      {
          queryString += ' Order By Age_in_List__c';      
      }
      else
      {
          queryString += ' Order By Status, CompanyOrAccount__c';
      }
      
      queryString += ' LIMIT 1000';

      system.debug('===queryString is === ' + queryString);
      
      system.debug('@getQueryString queryString: ' + queryString);

      return queryString;
  }
}