//##################################################################
//# Adpoint Custom controller / Extensions for Adpoint UI integration 
//# specified using describes.
//# 
//# Lineup Systems , June 2013
//# 
//# Version         Date        Author          Comments
//# initial         2/7/13      Craig Steen     Initial version.
//# updated         19/12/13    Bohao Chen      Updated version.
public  class AdPointOrder_Controller 
{
    public boolean syncCalled {get;set;}
    public  Account acc; 
    public Contact con;
    private id conId;   

    //# Accessors
    public String PageBaseURL
    {
        get
        {
            String PageBaseURL;
                
            if(SystemParameters__c.getAll().get('AdPoint_Url')!=null)
            {
                PageBaseURL = SystemParameters__c.getAll().get('AdPoint_Url').value__c;
            }
            return PageBaseURL;
        }
       
        private set;
    }  
    
    public boolean showHeaderAndSidebar {
        get { return Global_Helper.showHeaderAndSidebar; }
        set;
    }
    
    // constructor
    public AdPointOrder_Controller(ApexPages.StandardController controller) {} 
    
    public AdPointOrder_Controller() {} 
}