public with sharing class Campaign_ControllerX_ResultLine
{
    // previoius class name: global with sharing class Campaign_ControllerX_ResultLine implements Comparable
    // 2015-05-12 UserStory16.3 louis.wang@bluewolf.com
    //              After merged back SFE-315, the functionality that sorts list based on this comparable class 
    //              no longer relevant. Sorting / Refreshing for Campaign Execution page is now achieved through
    //              specific SOQL query. The code is left here (commented out), in case business decides to use memory to perform
    //              sorting.

    // Which field should be considered for sorting
    public enum SortField 
    {
        fullName, companyOrAccount, ageInList, lockedBy, status, executionStatus, callBackDate, lastBookingValue
    }
    
    // Sorting direction ASCENDING or DESCENDING
    public enum SortDirection {ASCENDING, DESCENDING}
    
    // default sorting would be ascending
    public static SortDirection SORT_DIR = SortDirection.ASCENDING;
    // default sorting would be on name
    public static SortField SORT_FIELD = SortField.fullName;
    
    public CampaignMember cm {get { return cm = cm == null ? new CampaignMember() : cm; }set;}

    public String fullName { get{ return init_FieldValue(fullName);} set;}
    public String companyOrAccount { get{ return init_FieldValue(companyOrAccount);} set;}

    // added by Tim Fabros 10 / 07 / 2014 - SFE-375
    // added datetime field to capture latest response date
    // BEGIN:
    public String lastResponseDate {get { return lastResponseDate = lastResponseDate == null ? '' : lastResponseDate; }set;}
    // END:

    // added by Bohao Chen 15 / 07 / 2014 - SFE-315
    // performance enhancement to reduce view state for campaign execution page
    // BEGIN:
    public Id recordId {get; private set;}
    public String recordType {get {return recordType = recordType == null ? '' : recordType;} private set;}
    // End

    // CONSTRUCTOR
    public Campaign_ControllerX_ResultLine() {
    }

    // added by Bohao Chen 15 / 07 / 2014 - SFE-315
    // performance enhancement to reduce view state for campaign execution page
    // BEGIN:
    public Campaign_ControllerX_ResultLine(CampaignMember cm) 
    {
        if(cm.ContactId != null)
        {
            this.recordId = cm.ContactId;
            this.recordType = 'Contact';    
            this.fullName = cm.Contact.Name;     
        }
        else if(cm.LeadId != null)
        {
            this.recordId = cm.LeadId;
            this.recordType = 'Lead';
            this.fullName = cm.Lead.Name;
        }

        this.companyOrAccount = cm.CompanyOrAccount__c;        

        this.cm = cm;  
    }

    private String init_FieldValue(String assignValue)
    {
        string output = '';
        if(assignValue!=null)
        {
            output = assignValue;
        }
        return output;
    }    

/*
    public String lockedBy { get{ return init_FieldValue(lockedBy);} set;}
    public String status { get{ return init_FieldValue(status);} set;}
    public String executionStatus { get{ return init_FieldValue(executionStatus);} set;}
    public Decimal ageInList { get{ return init_FieldValue(ageInList);} set;}
    public DateTime callBackDate { get{ return init_FieldValue(callBackDate);} set;}
    public Decimal lastBookingValue { get{ return init_FieldValue(lastBookingValue);} set;}

    public String defaultSortField { get{ return init_FieldValue(defaultSortField);} set;}
    public String defaultSortOrder { get{ return init_FieldValue(defaultSortOrder);} set;} 

    private DateTime DEFAULT_DATETIME = Datetime.newInstance(1970,1,1);

    global Integer compareTo(Object result)
    {
        system.debug('@Campaign_ControllerX_ResultLine compareTo');

        Integer output = 0;
        if(SORT_FIELD==SortField.ageInList || SORT_FIELD==SortField.lastBookingValue)
        {
            // sort number fields
            output = compareTo_DecimalFields(result, SORT_FIELD, SORT_DIR);
        }
        else if(SORT_FIELD==SortField.callBackDate)
        {
            // sort Datetime fields
            output = compareTo_DatetimeFields(result, SORT_FIELD, SORT_DIR);
        }
        else
        {
            // sort string fields
            output = compareTo_StringFields(result, SORT_FIELD, SORT_DIR);
        }    
        return output;
    }

    private Integer compareTo_StringFields(Object line, SortField fieldName, SortDirection sortOrder)
    {        
        String thisString = '';
        String otherString = '';
        Integer output = 0;

        if(fieldName==SortField.companyOrAccount)
        {
            thisString = this.companyOrAccount.toLowerCase();
            otherString = init_Object(line, ((Campaign_ControllerX_ResultLine)line).companyOrAccount).toLowerCase();
        }
        else if(fieldName==SortField.fullName)
        {
            thisString = this.fullName.toLowerCase();
            otherString = init_Object(line, ((Campaign_ControllerX_ResultLine)line).fullName).toLowerCase();
        }
        else if(fieldName==SortField.lockedBy)
        {
            thisString = this.lockedBy.toLowerCase();
            otherString = init_Object(line, ((Campaign_ControllerX_ResultLine)line).lockedBy).toLowerCase();
        }
        else if(fieldName==SortField.status)
        {
            thisString = this.status.toLowerCase();
            otherString = init_Object(line, ((Campaign_ControllerX_ResultLine)line).status).toLowerCase();
        }
        else if(fieldName==SortField.executionStatus)
        {
            thisString = this.executionStatus.toLowerCase();
            otherString = init_Object(line, ((Campaign_ControllerX_ResultLine)line).executionStatus).toLowerCase();
        }

        if(sortOrder==SortDirection.ASCENDING)
        {
            output = otherString.compareTo(thisString);            
        }
        else
        {
            output = thisString.compareTo(otherString);
        }
        return output;
    }

    private Integer compareTo_DecimalFields(Object line, SortField fieldName, SortDirection sortOrder)
    {        
        Decimal thisDecimal = 0;
        Decimal otherDecimal = 0;
        Integer output = 0;

        if(fieldName==SortField.ageInList)
        {
            thisDecimal = this.ageInList;
            otherDecimal = init_Object(line, ((Campaign_ControllerX_ResultLine)line).ageInList);
        }
        else if(fieldName==SortField.lastBookingValue)
        {
            thisDecimal = this.lastBookingValue;
            otherDecimal = init_Object(line, ((Campaign_ControllerX_ResultLine)line).lastBookingValue);            
        }

        if(sortOrder==SortDirection.ASCENDING)
        {
            output = integer.valueOf(otherDecimal - thisDecimal);
        }
        else
        {
            output = integer.valueOf(thisDecimal - otherDecimal);
        }
        return output;
    }

    private Integer compareTo_DatetimeFields(Object line, SortField fieldName, SortDirection sortOrder)
    {        
        Datetime thisDatetime = DEFAULT_DATETIME;
        Datetime otherDatetime = DEFAULT_DATETIME;
        Integer output = 0;

        if(fieldName==SortField.callBackDate)
        {
            thisDatetime = this.callBackDate;
            otherDatetime = init_Object(line, ((Campaign_ControllerX_ResultLine)line).callBackDate);
        }

        if(sortOrder==SortDirection.ASCENDING)
        {
            output = integer.valueOf(otherDatetime.getTime() - thisDatetime.getTime());
        }
        else
        {
            output = integer.valueOf(thisDatetime.getTime() - otherDatetime.getTime());
        }
        return output;
    }

    private Decimal init_FieldValue(Decimal assignValue)
    {
        decimal output = 0;
        if(assignValue!=null)
        {
            output = assignValue;
        }
        return output;
    }

    private DateTime init_FieldValue(DateTime assignValue)
    {
        dateTime output = DEFAULT_DATETIME;
        if(assignValue!=null)
        {
            output = assignValue;
        }
        return output;
    }

    private String init_Object(Object obj, String assignValue)
    {
        String output = '';
        if(obj!=null && assignValue!=null)
        {
            output = assignValue;
        }
        return output;
    }

    private Decimal init_Object(Object obj, Decimal assignValue)
    {
        Decimal output = 0;
        if(obj!=null && assignValue!=null)
        {
            output = assignValue;
        }
        return output;
    }

    private Datetime init_Object(Object obj, Datetime assignValue)
    {
        Datetime output = DEFAULT_DATETIME;
        if(obj!=null && assignValue!=null)
        {
            output = assignValue;
        }
        return output;
    }
*/
}