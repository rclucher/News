/**
* @company      Bluewolf
* @author       Noel Lim (noel.lim@bluewolf.com)
* @date         17/11/2014
* @description  Controller class for FeatureCalendar VF page
* - Remote method to update the Calendar via AJAX
* - Methods to build filter dropdowns and checkboxes
* - @todo remove Printable View
* @history
* - 20150216 added Feature End Date. This is an optional field, supported by FullCalendar as an optional field.
*/
global class CtrlFeatureCalendar {
    
    private static final String CSS_EVENT_TEXT_COLOR = '#ffffff';
    private static final String CSS_EVENT_BORDER_COLOR = '#000000';
    private static final String CSS_EVENT_DEFAULT_BACKGROUND_COLOR = '#3a87ad';
    
    public String featureNameFilter {get; set;}
    public String productFilter {get; set;}
    public String sectionFilter {get; set;}    
    public Date startDateFilter {get; private set;}   
    public Date endDateFilter {get; private set;}   
    public Map<String, List<String>> checkboxFilterMap {get; private set;}
    
    public Map<String, String> categoryColours{
        get{
            
            Map<String, Feature_Category_Colour__c> custSettingCatColour = Feature_Category_Colour__c.getAll();
            
            Map<String, String> mapCategoryColour = new Map<String, String>();
            for(String id : custSettingCatColour.keySet()){
                mapCategoryColour.put(custSettingCatColour.get(id).Name, custSettingCatColour.get(id).Colour__c);
            }        
    
            return mapCategoryColour;
        }
        set;
    }
    
    
    
    //CONSTRUCTOR
    public CtrlFeatureCalendar() {        
        buildCheckboxFilters();
    }
    
    /**
     * Queries Features to display in the Calendar based on date range and filters.
     *
     * Checkbox filters are received as JSON.
     */
    @RemoteAction    
    global static String getJSONFeatures(String strStartDate, String strEndDate, 
                        String featureNameFilterR, String productFilterR, String sectionFilterR, String strSDFilter, String strEDFilter, String jsonCheckboxFilters) {    
        
        Date startDate = Date.valueOf(strStartDate);
        Date endDate = Date.valueOf(strEndDate);
        
        if(strSDFilter != ''){
           startDate = Date.valueOf(strSDFilter);
        }
        if(strEDFilter != '')  {
           endDate = Date.valueOf(strEDFilter);
        }

        
        //QUERYSTRING - Feature End Date is optional
        String featureQuery = 'SELECT Name, Feature_Date__c, Feature_End_Date__c, Product__c, Contact_Name__c, Contact_Email__c, Material_Deadline__c, Category__c ' +
                               'FROM Feature__c WHERE ((Feature_Date__c >= :startDate AND Feature_Date__c <= :endDate) OR (Feature_End_Date__c >= :startDate AND Feature_End_Date__c <= :endDate))';

        if(featureNameFilterR != ''){
            featureQuery += ' AND Name LIKE \'%' + String.escapeSingleQuotes(featureNameFilterR) + '%\'';
        }
        if(productFilterR != ''){
            featureQuery += ' AND Product__c = \'' + String.escapeSingleQuotes(productFilterR) + '\'';
        }
        if(sectionFilterR != ''){
            featureQuery += ' AND Section_in_Product__c = \'' + String.escapeSingleQuotes(sectionFilterR) + '\'';
        }
        
        //System.debug(LoggingLevel.DEBUG, 'getJSONFeatures - query is ' + featureQuery);        
        
        Map<String, Object> mapDeserializedCF = (Map<String, Object>) JSON.deserializeUntyped(jsonCheckboxFilters);
        for(String filter : mapDeserializedCF.keySet()) {
            
            string clause = filter == 'Type' || filter == 'Status' ?'IN':'INCLUDES';
            
            Map<String,Object> mapFilterOption = (Map<String,Object>) mapDeserializedCF.get(filter);
            if(!mapFilterOption.isEmpty()){
                featureQuery += ' AND ' + filter + '__c ' + clause + ' (';
                Integer filterOptionSize = mapFilterOption.size();
                Integer count = 0;
                
                for(String filterOption : mapFilterOption.keySet()){
                    featureQuery += '\''+filterOption+'\'';
                    count++;
                    if(count < filterOptionSize)
                        featureQuery += ',';
                    else
                        featureQuery += ')';
                } 
            }
        }
        
        //BUILD and RETURN DATA
        List<Feature__c> features = Database.query(featureQuery);                
        List<FullCalendarEvent> fcEvents = new List<FullCalendarEvent>();  
        List<Feature_Category_Colour__c> lstCategory= new List<Feature_Category_Colour__c>([SELECT Name, Colour__c FROM Feature_Category_Colour__c LIMIT 100]);
        
        Map<String, String> mapCategoryColour = new Map<String, String>();
        for(Feature_Category_Colour__c categoryColour : lstCategory){
            mapCategoryColour.put(categoryColour.Name, categoryColour.Colour__c);
        }
              
        for(Feature__c feature : features)
        {
            FullCalendarEvent fce = new FullCalendarEvent();
            fce.title = feature.Name;
            fce.start = feature.Feature_Date__c;
            fce.endDate = feature.Feature_End_Date__c;
            fce.allDay = true;
            fce.url = URL.getSalesforceBaseUrl().toExternalForm() + '/' + feature.Id;
            fce.backgroundColor = mapCategoryColour.containsKey(feature.Category__c) ? mapCategoryColour.get(feature.Category__c) : CSS_EVENT_DEFAULT_BACKGROUND_COLOR;
            fce.borderColor = CSS_EVENT_BORDER_COLOR;
            fce.textColor = CSS_EVENT_TEXT_COLOR;
            
            fce.product = feature.Product__c;
            fce.contactName = feature.Contact_Name__c;
            fce.contactEmail = feature.Contact_Email__c;
            fce.materialDeadline = feature.Material_Deadline__c;
            fce.category = feature.Category__c;

            fcEvents.add(fce);
        }
        String jsonFCE = JSON.serializePretty(fcEvents);
        
        return jsonFCE;
    }

    //TODO refactor filterOption
    public List<SelectOption> getProductFilterOptions(){
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('',''));
        
        Schema.DescribeFieldResult fieldResult = Feature__c.Product__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            
        for( Schema.PicklistEntry f : ple)
        {
          options.add(new SelectOption(f.getLabel(), f.getValue()));
        }

        return options;
    }

    //TODO refactor filterOption
    public List<SelectOption> getSectionFilterOptions(){
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('',''));
        
        Schema.DescribeFieldResult fieldResult = Feature__c.Section_in_Product__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            
        for( Schema.PicklistEntry f : ple)
        {
          options.add(new SelectOption(f.getLabel(), f.getValue()));
        }

        return options;
    }

    /**
     * Build the Checkbox filters for loop rendering
     */
    private void buildCheckboxFilters(){

        checkboxFilterMap = new Map<String, List<String>>();
        List<String> pickVals;
        Schema.DescribeFieldResult fieldResult;
        List<Schema.PicklistEntry> ple;
        
        //STATE picklist
        fieldResult = Feature__c.State__c.getDescribe();
        ple = fieldResult.getPicklistValues();
        
        pickVals = new List<String>();
            
        for( Schema.PicklistEntry f : ple)
        {
            pickVals.add(f.getValue());
        }
        checkboxFilterMap.put('State', pickVals);
        
        //TYPE picklist
        fieldResult = Feature__c.Type__c.getDescribe();
        ple = fieldResult.getPicklistValues();
        
        pickVals = new List<String>();
            
        for( Schema.PicklistEntry f : ple)
        {
            pickVals.add(f.getValue());
        }
        checkboxFilterMap.put('Type', pickVals);
        
        //CATEGORY picklist
        fieldResult = Feature__c.Category__c.getDescribe();
        ple = fieldResult.getPicklistValues();
        
        pickVals = new List<String>();
            
        for( Schema.PicklistEntry f : ple)
        {
            pickVals.add(f.getValue());
        }
        checkboxFilterMap.put('Category', pickVals);
        
        //AUDIENCE picklist
        fieldResult = Feature__c.Audience__c.getDescribe();
        ple = fieldResult.getPicklistValues();
        
        pickVals = new List<String>();
            
        for( Schema.PicklistEntry f : ple)
        {
            pickVals.add(f.getValue());
        }
        checkboxFilterMap.put('Audience', pickVals);
        
        //STATUS picklist
        fieldResult = Feature__c.Status__c.getDescribe();
        ple = fieldResult.getPicklistValues();
        
        pickVals = new List<String>();
            
        for( Schema.PicklistEntry f : ple)
        {
            pickVals.add(f.getValue());
        }
        checkboxFilterMap.put('Status', pickVals);
    }
    
    /**
     * Represents the FullCalendar's Event data model, assist in JSON and APEX Remoting
     */
    public class FullCalendarEvent {

        public FullCalendarEvent() {
            
        }

        // Properties for use in the Visualforce view
        public String title {get; set;}        
        public DateTime start {get; set;}
        public DateTime endDate {get; set;} //This preferably would be 'end' but it's an APEX keyword        
        public Boolean allDay{get; set;}        
        public String url{get; set;}        
        public String textColor{get; set;}        
        public String backgroundColor{get; set;}        
        public String borderColor{get; set;}
        
        //non-Full Calendar fields
        public String product{get; set;}
        public String contactName{get; set;}
        public String contactEmail{get; set;}
        public DateTime materialDeadline{get; set;}
        public String category{get; set;}
    }
       
    
}