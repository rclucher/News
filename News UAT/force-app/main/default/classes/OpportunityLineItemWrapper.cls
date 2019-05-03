public class OpportunityLineItemWrapper 
{   
    private final Integer NUM_OF_PERIOD    =   1;
    private final String DEFAULT_PERIOD    =   'Week(s)';
    private final String DEFAULT_PATTERN   =   'Weekly';
    
    public String productName { get; set; }
    public OpportunityLineItem opportunityLineItem { get; set; }
    public List<String> pattern { get; set; }
    public String frequency { get; set; }
    public Integer numOfSchedules { get; set; }
    // modified by Tim Fabros 15 / 07 / 2014 - SFE-516
    // getter method no longer hard coded to return null
    // BEGIN:
    public Boolean isSelect { get {return isSelect = isSelect == NUll ? false : isSelect;} set;}
    // END:
    
    public OpportunityLineItemWrapper(String productName, OpportunityLineItem opportunityLineItem)
    {
        this.productName = productName;
        this.opportunityLineItem = opportunityLineItem;
        this.pattern = new List<string>();
        this.numOfSchedules = 0;
        
        if(this.opportunityLineItem.of_Periods__c == null)
            this.opportunityLineItem.of_Periods__c = NUM_OF_PERIOD;
        if(this.opportunityLineItem.Period__c == null)
            this.opportunityLineItem.Period__c = DEFAULT_PERIOD;
        if(this.opportunityLineItem.Pattern__c == null)
            this.opportunityLineItem.Pattern__c = DEFAULT_PATTERN;
    }
    
    public OpportunityLineItemWrapper(OpportunityLineItem opportunityLineItem)
    {
        this.opportunityLineItem = opportunityLineItem;
        this.pattern = new List<string>();
        this.numOfSchedules = 0;
    }
    
    public List<String> getRevenueSchedulePattern()
    {
        List<String> pattern = new List<String>();
        
        if(OpportunityProductSearch_Helper.patternInstanceMap.containsKey(opportunityLineItem.Pattern__c))
        {
            String patternLongString = OpportunityProductSearch_Helper.patternInstanceMap.get(opportunityLineItem.Pattern__c).Pattern__c;
                
            if(String.isNotBlank(patternLongString))
                pattern = patternLongString.split('');
        }
        
        System.debug('===pattern=== ' + pattern);
        
        return pattern;
    }
    
    public String getRevenueScheduleFrequency()
    {
        String frequency;
        
        system.debug('==pattern instance==' + this.opportunityLineItem.Pattern__c);
        
        if(OpportunityProductSearch_Helper.patternInstanceMap.containsKey(opportunityLineItem.Pattern__c))
        {
            frequency = OpportunityProductSearch_Helper.patternInstanceMap.get(opportunityLineItem.Pattern__c).Frequency__c;
        }
        
        System.debug('===frequency=== ' + frequency);
        
        return frequency;
    }
}