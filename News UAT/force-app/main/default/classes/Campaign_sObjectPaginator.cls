public with sharing Class Campaign_sObjectPaginator
{        
    // 2015-05-06 UserStory16.3 louis.wang@bluewolf.com
    //              This was the inner class in Campaign_ControllerX.
    //              The inner class is promoted to top class so Visualforce component can recognise it.
    //              All 7 tabs on Campaign Execution is now consolidated to one Visualforce component.

    // modified by Tim Fabros 17 / 06 / 2014 - SFE-184
    // was 100; now 200
    // BEGIN:

    // END:
    private final Integer PAGESIZE = 100;

    public String sortField { get; set;}    
    public String sortDir { get{ return sortDir = sortDir == null ? 'ASC' : sortDir; } set; }

    public Integer currentPage {get{return currentPage = currentPage == null? 0 : currentPage;} private set;}
    public Integer totalPages {get{return totalPages = totalPages == null? 0 : totalPages;} private set;}

    public Integer sizeOfList {get{return sizeOfList = sizeOfList == null? 0 : sizeOfList;} private set;}    

    // added by Tim Fabros / Bohao Chen 19 / 06 / 2014 - SFE-533
    // BEGIN: 
    public List<CampaignMember> ccrList {get {return ccrList = ccrList == null ? new List<CampaignMember>() : ccrList;} private set;}
    // END:

    public Campaign_sObjectPaginator() {}

    public boolean getHasNext()
    {
        return this.currentPage < this.totalPages;
    }

    public boolean getHasPrevious()
    {
        return this.currentPage > 1;
    }

    private Integer calculateTotalPages(Integer sizeOfList)
    {
        Integer i = 0;
        if(ccrList != null && sizeOfList > 0)
            i = Integer.valueof(math.ceil((double)sizeOfList / (double)PAGESIZE));
        return i;        
    }

    public void Next()
    {
        this.currentPage++;        
    }

    public void Previous()
    {
        this.currentPage--;
    }

    // Updated by Bohao Chen on 19/06/2014 for JIRA issue SFE-533
    // BEGIN
    public List<CampaignMember> getRecords(List<CampaignMember> cmList)
    {
        this.sizeOfList = cmList.size();

        if(sizeOfList > 0 && currentPage == 0)
            this.currentPage = 1;

        // calculate total number of pages
        this.totalPages = this.calculateTotalPages(sizeOfList);

        List<CampaignMember> sObjects = new List<CampaignMember>();
        if(sizeOfList > PAGESIZE)
        {   
            for(integer counter = (currentPage-1) * PAGESIZE ; counter < (math.min(currentPage * PAGESIZE, sizeOfList)); counter++)
            {
                //system.debug('@counter ' + counter);
                sObjects.add(cmList.get(counter));
            }
        }
        else
        {
            sObjects.addAll(cmList);
        }
        
         //sObjects.add(cmList.get((currentPage-1) * PAGESIZE));
        
        return sObjects;
    }
    // END
}