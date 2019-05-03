public with sharing class AccountSearch_Controller extends ComponentControllerBase{

    public boolean isAndCondition {get;set;}
	public integer minCharLength {get{return minCharLength = minCharLength==null?1:minCharLength;} set;}
    public boolean isDebugMode {get;set;}
    
	public String searchAccountNameText {get;set;}
	public String searchPhoneText {get;set;}
	public boolean hasSearched {get {return hasSearched = hasSearched!=null?hasSearched:false;} private set;}


    private final Integer SEARCHLISTSIZE = 6;
    public Integer getSearchListSize()
    {
        return SEARCHLISTSIZE;
    }
    
    public Account selectedAccount {get {return selectedAccount = selectedAccount!=null?selectedAccount:new Account();}set;}
    
    
	public list<Account> findAccountResults {get;set;}
	
	public PageReference doAccountQuery()
	{

        system.debug('@ doAccountQuery()');
        System.debug('searchAccountNameText: ' + searchAccountNameText);
        System.debug('searchPhoneText: ' + searchPhoneText);        
        
            list<list<sObject>>searchList = new list<list<sObject>>();

            this.findAccountResults = null;
            map<id, Account> accountNameFound = null;
            map<id, Account> accountPhoneFound = null;
            
            
            
			if(searchAccountNameText.trim().length()>=minCharLength)
			{
	            String searchqueryName='FIND \'' + String.escapeSingleQuotes(searchAccountNameText) +
	                               '*\' IN NAME FIELDS RETURNING Account(id, Name, Phone, BillingStreet, BillingCountry, BillingPostalCode, BillingState, BillingCity) LIMIT 200';
	            System.debug('searchqueryName: ' + searchqueryName);
	            
	            list<list<sObject>> results = search.query(searchqueryName);
	            System.debug('account results: ' +  results);
	            if(results.size() > 0)
	            {
	            	searchList.addAll(results);
	        		accountNameFound = new map<id, Account>((list<Account>) results[0]);    
	            }
			}
			
			
			

			if(searchPhoneText.trim().length()>=minCharLength)
			{
	            String searchqueryPhone='FIND \'' + String.escapeSingleQuotes(searchPhoneText) +
	                               '*\' IN PHONE FIELDS RETURNING Account(id, Name, Phone, BillingStreet, BillingCountry, BillingPostalCode, BillingState, BillingCity) LIMIT 200';
	            
	            System.debug('searchqueryPhone: ' +  searchqueryPhone);

	            list<list<sObject>> results = search.query(searchqueryPhone);
	            System.debug('phone results: ' +  results);
	            
	            if(results.size() > 0)
	            {
	            	searchList.addAll(results);
	        		accountPhoneFound = new map<id, Account>((list<Account>) results[0]);    
	            }
			}


			


			set<Account> foundAccountSet = new set<Account>();
					
            if (searchList.size() > 0)
            {
            	if(!isAndCondition ||
            		(accountNameFound==null || accountPhoneFound==null))
            	{
	            	for(sObject acc : searchList[0])
	            	{
	            		foundAccountSet.add((Account) acc);	
	            	}
            	}
            	else
            	{
            		map<id,Account> foundAccountJoin = new map<id,Account>();

					System.debug('accountNameFound: ' + accountNameFound);
					System.debug('accountPhoneFound: ' + accountPhoneFound);
					
	            	for(Account acc : accountNameFound.values())
	            	{
	            		if(accountPhoneFound.containsKey(acc.id))
						{
							foundAccountJoin.put(acc.id,acc);
						}
	            	}     	
					foundAccountSet.addAll(foundAccountJoin.values());

            	}
            }

			
			if(foundAccountSet.size() > 0)
			{
				findAccountResults = new list<Account>();
			 	this.findAccountResults.addAll(foundAccountSet);
			 	setCon = null;
			}
			
			

            if(findAccountResults!=null &&
            	(findAccountResults.size() > getSearchListSize()))
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO,'There were found ' + findAccountResults.size() + ' accounts with the search parameter, please refine and search again'));


        hasSearched = true;

        return null;

	}

	public void doSelectAccount()
	{
		system.debug('@ doSelectAdvertiser()');
		try{
			if(ApexPages.currentPage().getParameters().get('selectedAccountId')!=null)
        	{
        		system.debug(ApexPages.currentPage().getParameters().get('selectedAccountId'));
        		selectedAccount = [Select id from Account where ID=:ApexPages.currentPage().getParameters().get('selectedAccountId')];
        		system.debug(selectedAccount);
        		
        		// call page controller method from component controller
        		PageControllerBase pageCtr = this.pageController;
        		
        		if (pageCtr instanceof SalesOrderCreateBookingv2_ControllerX) 
        		{
				    SalesOrderCreateBookingv2_ControllerX bookingCtr = (SalesOrderCreateBookingv2_ControllerX)pageCtr;
				    bookingCtr.populateSelectedAdvertiser();
			    } 
        	}
		}
		catch(Exception ex)
		{
			System.debug('Invalid selection account:' + ex.getMessage());
		}
	}

	//navigation

	public ApexPages.StandardSetController setCon {
	        get {
	            if(setCon == null && 
	            (findAccountResults!=null && findAccountResults.size() > 0))
	            {
	                setCon = new ApexPages.StandardSetController(findAccountResults);
	            	setCon.setPageSize(SEARCHLISTSIZE); 
	            }
	            return setCon;
	        }
	        set;
	    }

    public List<Account> getAccounts() {
        return (List<Account>) setCon.getRecords();
    }

	public integer getAccountListSize()
	{

		Decimal d = Decimal.valueOf(setCon.getResultSize()) / Decimal.valueOf(setCon.getPageSize());
		d = d.round(System.RoundingMode.UP);
		
		return Integer.valueOf(d);
	} 

	public integer getAccountListCurrentPage()
	{
		return setCon.getPageNumber();
	}
	
	public void accountPreviousPage()
	{
		setCon.previous();
	}	

	public void accountNextPage()
	{
		setCon.next();
	}	
	
	
	public boolean getAccountListHasNext()
	{
		return setCon.getHasNext();
	}

	public boolean getAccountListHasPrevious()
	{
		return setCon.getHasPrevious();
	}
}