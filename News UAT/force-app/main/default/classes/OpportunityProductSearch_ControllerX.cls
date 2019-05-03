/*---------------------------------------------------------
Author: Bohao Chen
Company: Salesforce.com
Description: This controller is used by VF OpportunityProductSearch and OpportunityProductRevenueSchedule. // R-572
Two main functions in this controller:
1. Search and add products for an opportunity
2. Create revenue schedules for each opportunity line item
History:
4/06/2013   Bohao Chen  Created
18/07/2013  Bohao Chen  Updated
2016-02-16  Atul Gupta  Updated
2016-10-07  louis.wang@bluewolf.com - Item-00141 - remove Item-00027 (SFE-608) from all environments
---------------------------------------------------------*/
public with sharing class OpportunityProductSearch_ControllerX 
{
    public String opportunityName {get; set;}
    public List<ProductWrapper> productSearchResultsList { get; set; }
    public List<OpportunityLineItemWrapper> opportunityLineItemsList { get; set; }
    public String keyword { get; set;}
    public String productFamily { get; set;}
    public String productCategory { get; set;}
    public String productRegion { get; set;}
	
    public List<SelectOption> familySelectOptions 
    { 
        get
        { 
            if(familySelectOptions == null)
            {
                familySelectOptions = new List<SelectOption>();
                
                familySelectOptions.add(new SelectOption('', '--None--'));
                
                for(Schema.PicklistEntry p : Product2.Family.getDescribe().getPicklistValues())
                {
                    familySelectOptions.add(new SelectOption(p.getValue(), p.getLabel()));
                }
            }
            return familySelectOptions;
        } 
        private set;
    }
    
    public List<SelectOption> categorySelectOptions 
    { 
        get
        { 
            if(categorySelectOptions == null)
            {
                categorySelectOptions = new List<SelectOption>();
                
                categorySelectOptions.add(new SelectOption('', '--None--'));
                
                for(Schema.PicklistEntry p : Product2.Category__c.getDescribe().getPicklistValues())
                {
                    categorySelectOptions.add(new SelectOption(p.getValue(), p.getLabel()));
                }
            }
            return categorySelectOptions;
        } 
        private set;
    }
    
    public List<SelectOption> regionSelectOptions 
    { 
        get
        { 
            if(regionSelectOptions == null)
            {
                regionSelectOptions = new List<SelectOption>();
                
                regionSelectOptions.add(new SelectOption('', '--None--'));
                
                for(Schema.PicklistEntry p : Product2.Region__c.getDescribe().getPicklistValues())
                {
                    regionSelectOptions.add(new SelectOption(p.getValue(), p.getLabel()));
                }
            }
            return regionSelectOptions;
        }  
        private set;
    }
    
    private final OpportunityProductSearch_Helper.ProductListWrapper fullProdList;
    private Boolean isEditMode {get; set;}
    private String opportunityId;
    
    public OpportunityProductSearch_ControllerX(ApexPages.StandardController controller) 
    {		
        opportunityId = apexpages.currentPage().getParameters().get('oppId');
        opportunityName = apexpages.currentPage().getParameters().get('oppName');
        
        this.opportunityLineItemsList = new List<OpportunityLineItemWrapper>();
        this.productSearchResultsList = new List<ProductWrapper>();
        
        if(Test.isRunningTest())
        {
            this.fullProdList = new OpportunityProductSearch_Helper.ProductListWrapper (
                [Select Name, Family, Category__c, Region__c, Description, PublicationList__c 
                 From Product2 Where IsActive = true And IsTest__c = true 
                 order by Name ASC 
                 LIMIT 1000]);
        }
        else
        {
            // added by Tim Fabros 05 / 06 / 2014 - SFE-517
            // added extra where clause where name does not include 'Walk-in'
            // BEGIN:
            this.fullProdList = new OpportunityProductSearch_Helper.ProductListWrapper (
                [Select Name, Family, Category__c, Region__c, Description, PublicationList__c  
                 From Product2 Where (NOT Name  LIKE 'Walk-in%') AND IsActive = true And IsTest__c = false  
                 order by Name ASC 
                 LIMIT 1000]);
            // END:
        }
        
        this.productSearchResultsList = this.fullProdList.prodList;
        
        if(apexpages.currentPage().getParameters().get('mode') == 'edit')
        {
            this.isEditMode = true;
        }
        else
        {
            this.isEditMode = false;
        }
    }
    
    /***** BEGIN: methods used by buttons on VF pages *****/
    public PageReference searchBtn()
    {
        this.doFilter();
        return null;
    }
    
    public PageReference selectBtn()
    {
        List<Product2> productList = this.getSelectedProducts(productSearchResultsList);
        
        if(productList.isEmpty())
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Warning, 'No products have been selected, please select an item'));
            return null;
        }
        
        PageReference opportunityLineItemsPage = Page.OpportunityProductRevenueSchedule;
        return opportunityLineItemsPage;
    }
    
    public PageReference saveBtn()
    {
        if(this.doSave())
        {
            PageReference opportunityPage = new PageReference('/' + opportunityId);
            return opportunityPage;
        }
        else
            return null;
    }
    
    public PageReference saveAndMoreBtn()
    {
        if(this.doSave())
        {
            PageReference searchPage = Page.OpportunityProductSearch;
            searchPage.getParameters().put('retURL', opportunityId);
            searchPage.getParameters().put('oppId', opportunityId);
            searchPage.getParameters().put('oppName', opportunityName);
            searchPage.setRedirect(true);
            return searchPage;
        }
        else
            return null;
    }
    
    // added by Tim Fabros 15 / 07 / 2014 - SFE-516
    // added new function to clone selected products.
    // BEGIN:
    public PageReference cloneProducts()
    {
        List<OpportunityLineItemWrapper> wrapperList = new List<OpportunityLineItemWrapper>();
        for (OpportunityLineItemWrapper oliWrapper : opportunityLineItemsList)
        {
            if (oliWrapper.isSelect)
            {
                oliWrapper.isSelect = false;
                
                OpportunityLineItemWrapper newOliWrapper = new OpportunityLineItemWrapper(oliWrapper.productName, oliWrapper.opportunityLineItem.clone());
                                
                wrapperList.add(newOliWrapper);
            }
        }
        
        opportunityLineItemsList.addAll(wrapperList);
        
        return null;
    }
    // END:
    /***** END: methods used by buttons on VF pages *****/
    
    public Boolean doSave()
    {
        // create opportunity line items if they are new
        List<OpportunityLineItem> opportunityLineItems = new List<OpportunityLineItem>();
        
        // added by Tim Fabros 11 / 07 / 2014 - SFE-373
        // set a save point to undo all changes if errors occur.
        // BEGIN:
        System.Savepoint savePoint = Database.setSavepoint();
        // END:
        
        try
        {
            Boolean isValid = true;
            
            List<OpportunityLineItemWrapper> newOpportunityLineItemsList = new List<OpportunityLineItemWrapper>();
            List<OpportunityLineItem> oldOpportunityLineItemsList = new List<OpportunityLineItem>();
            
            system.debug(logginglevel.error, '@opportunityLineItemsList: ' + opportunityLineItemsList);
            
            for(OpportunityLineItemWrapper opportLineItem : opportunityLineItemsList)
            {
                opportLineItem.opportunityLineItem.Quantity = 1;
                
                /*if(!this.isEditMode)
opportLineItem.opportunityLineItem.OpportunityId = opportunityId;*/
                
                // validate opportunityLineItems;
                isValid = OpportunityProductSearch_Helper.validateFieldValues(opportLineItem.opportunityLineItem);
                
                opportunityLineItems.add(opportLineItem.opportunityLineItem);
                
                // the rest of code in this block is used when user tries to update/insert opportunity line item
                // 1. delete opportunity line item schedules if user tries to update opportunity line item
                // 2. create opportunity line item schedules if user tries to update/insert opportunity line item
                if(opportLineItem.opportunityLineItem.Id != null) // update opportunity line item
                {
                    system.debug('@OpportunityProductSearch_ControllerX doSave opportLineItem.opportunityLineItem: ' + opportLineItem.opportunityLineItem);
                    
                    newOpportunityLineItemsList.add(opportLineItem);
                    oldOpportunityLineItemsList.add(opportLineItem.opportunityLineItem);
                }
                else //insert opportunity line item
                {
                    if(opportLineItem.opportunityLineItem.Pattern__c != null && opportLineItem.opportunityLineItem.Pattern__c != '')
                        newOpportunityLineItemsList.add(opportLineItem);
                }
            }
            
            
            /**** Updated by Bohao Chen on 17/03/2014 for JIRA SFE-104 *****/
            if(isValid)
            {
                // to set this to true so it doesn't run opportunityLineManagementTrigger.
                // This is solution for JIRA SFE-104. 
                // Because it's likely to run opportunity trigger, opportunity line item trigger
                // and workflow rules at the same time, it could trigger infinite loop among these triggers 
                // which could throw error eventually
                OpportunityLineItem_Helper.isOpportunityLineManagementTriggerEnabled = false;
                
                if(!oldOpportunityLineItemsList.isEmpty())
                    OpportunityLineItem_Helper.deleteOpportunityLineItemSchedules(oldOpportunityLineItemsList);
                
                System.debug('@OpportunityProductSearch_ControllerX doSave opportunityLineItems: ' + opportunityLineItems);
                // insert or update opportunity line items
                
                // Updated by Bohao Chen on 14/July/2014 For JIRA SFE-37                // this update is to improve better UI with meaningful error message
                // Begin
                List<Database.upsertResult> uResults = Database.upsert(opportunityLineItems,false);
                
                Integer i = 0;
                String exceptionMessage = '';
                
                for(Database.upsertResult result : uResults) 
                {
                    
                    if (!result.isSuccess())
                    {
                        for(Database.Error error : result.getErrors()) 
                        {
                            if (error.getMessage().containsIgnoreCase('field integrity exception: PricebookEntryId'))
                            {
                                exceptionMessage += 'Unable to add ' + opportunityLineItemsList[i].productName + ' product. Please ensure that the product contains a Standard Price.<br/>';
                            }
                            else
                            {
                                exceptionMessage += error.getMessage();
                            }
                        }
                    }
                    
                    i++;
                }
                
                if(String.isNotBlank(exceptionMessage))
                {
                    system.debug('@exceptionMessage from helper: ' + exceptionMessage);            
                    throw new OpportunityLineItem_Helper.OpportunityLineItem_Helper_Exception(exceptionMessage);
                }
                
                if(!newOpportunityLineItemsList.isEmpty())
                    OpportunityLineItem_Helper.createOpportunityLineItemSchedules(newOpportunityLineItemsList);
                
                // End
            }
            // updated by Tim Fabros - SFE-373
            // added 'else' to validation rule
            // fixes incorrect redirection
            // BEGIN:
            else
            {
                return false;
            }
            // END:
            /**** Updated by Bohao Chen *****/
            
            
        } 
        catch(Exception e) 
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error, e.getMessage()));
            
            // added by Tim Fabros 11 / 07 / 2014 - SFE-373
            // rolls back changes if errors exist.
            // BEGIN:
            Database.rollback(savePoint);
            // END:
            
            return false;
        }
        return true;
    }
    
    public void doFilter() {
        
        this.productSearchResultsList = this.fullProdList.filterList(
            this.keyword,
            this.productFamily,
            this.productCategory, 
            this.productRegion);
    }
    
    public PageReference createSelectedOpportunityLineItems()
    {
        List<String> noPriceProductList = new List<String>();
        
        if(this.isEditMode)
        {
            try
            {
                // we can ONLY edit opportunity line item no assoicate with any sales orders
                if(!Test.isRunningTest())
                {
                    for(OpportunityLineItem oppt : [Select o.of_Periods__c, 
													o.UnitPrice, o.Period__c, o.Pattern__c, o.Id, 
                                                    o.ServiceDate, o.PricebookEntry.Name, o.HasSchedule, o.OpportunityId, 
                                                    o.HasRevenueSchedule, o.HasQuantitySchedule, o.Description 
                                                    From OpportunityLineItem o
                                                    Where o.OpportunityId =: this.opportunityId
                                                    And o.Sales_Order__c = null 
                                                    And o.Is_Test__c = false])
                    {
                        opportunityLineItemsList.add(new OpportunityLineItemWrapper(oppt.PricebookEntry.Name, oppt));
                    }
                }
                else
                {
                    for(OpportunityLineItem oppt : [Select o.of_Periods__c, 
													o.UnitPrice, o.Period__c, o.Pattern__c, o.Id, 
                                                    o.ServiceDate, o.PricebookEntry.Name, o.HasSchedule, o.OpportunityId, 
                                                    o.HasRevenueSchedule, o.HasQuantitySchedule, o.Description 
                                                    From OpportunityLineItem o
                                                    Where o.OpportunityId =: this.opportunityId
                                                    And o.Sales_Order__c = null
                                                    And o.Is_Test__c = true])
                    {
                        opportunityLineItemsList.add(new OpportunityLineItemWrapper(oppt.PricebookEntry.Name, oppt));
                    }                   
                }
                
                system.debug('@OpportunityProductSearch_ControllerX createSelectedOpportunityLineItems opportunityLineItemsList: ' + opportunityLineItemsList);
            }catch(Exception e){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error, e.getMessage()));
                return null;
            }
        }
        else
        {
            List<Product2> productList = this.getSelectedProducts(productSearchResultsList);
            
            Map<String, String> priceBookEntryIdMapByProductId = this.getPriceBookEntryIdMapByProductId(productList);
            
            Date startDate;
            try
            {
                startDate = [Select Campaign_Start_Date__c From Opportunity Where Id =: OpportunityId limit 1].Campaign_Start_Date__c;
            }
            catch(Exception e)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error, 'Please provide Campaingn Start Date on Opportunity'));
                return null;
            }
            
            for(Product2 p : productList)
            {
                OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = this.opportunityId, 
                                                                  PricebookEntryId = priceBookEntryIdMapByProductId.get(p.Id),
                                                                  ServiceDate = startDate);
                
                if(Test.isRunningTest()) oli.Is_Test__c = true;
                
                opportunityLineItemsList.add(new OpportunityLineItemWrapper(p.Name, oli));
                
                
                // Updated by Bohao Chen on 14/July/2014 For JIRA SFE-                // this update is to improve better UI with meaningful error message
                // Begin
                if(oli.PricebookEntryId == null)
                    noPriceProductList.add(p.Name);
                // End
            }
            
            system.debug('@opportunityLineItemsList: ' + opportunityLineItemsList);
        }
        
        if(opportunityLineItemsList.isEmpty())
        {
            PageReference productSearchPage = Page.OpportunityProductSearch;
            productSearchPage.getParameters().put('oppId', OpportunityId);
            productSearchPage.getParameters().put('retURL', OpportunityId);
            productSearchPage.getParameters().put('oppName', opportunityName);
            return productSearchPage;
        }
        
        // Updated by Bohao Chen on 14/July/2014 For JIRA SFE-373
        // this update is to improve better UI with meaningful error message
        // Begin
        else if(!noPriceProductList.isEmpty())
        {
            for(String productName : noPriceProductList)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error, productName + ' does not contain a Standard Price. Please go to product page and add standard price'));
            }
        }
        // End
        
        return null;
    }
    
    private List<Product2> getSelectedProducts(List<ProductWrapper> productWrappersList)
    {
        List<Product2> productList = new List<Product2>();
        
        for(ProductWrapper p : productWrappersList)
        {
            if(p.isSelect)
                productList.add(p.product);
        }
        
        return productList;
    }
    
    private Map<String, String> getPriceBookEntryIdMapByProductId(List<Product2> productList)
    {
        Map<String, String> priceBookEntryIdMapByProductId = new Map<String, String>();
        
        try
        {
            for(PricebookEntry p : [Select p.Product2Id From PricebookEntry p Where p.Product2Id IN: productList])
            {
                priceBookEntryIdMapByProductId.put(p.Product2Id, p.Id);
            }
        } catch(exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error, e.getMessage()));
        }
        
        
        return priceBookEntryIdMapByProductId;
    }
}