/*---------------------------------------------------------
 * Author: Bohao Chen
 * Company: Salesforce.com
 * Description: This is helper class for OpportunityProductSearch_ControllerX
 * History:
 * 6/06/2013  Bohao Chen  Created
 * 2016-02-16  Atul Gupta  Updated
 ---------------------------------------------------------*/
public with sharing class OpportunityProductSearch_Helper 
{
    public static final String ERROR_REQUIRED_FIELD_MSG = 'This field is required';
    
    public static Map<String, Revenue_Schedule_Pattern__c> patternInstanceMap 
    {
        get{ 
            return patternInstanceMap = patternInstanceMap == null ? Revenue_Schedule_Pattern__c.getAll() : patternInstanceMap; 
        } set; 
    }
    
    public static Boolean validateFieldValues(OpportunityLineItem o)
    {
        Boolean isValid = true;
        
        if(o.of_Periods__c == null)
            o.of_Periods__c.addError(OpportunityProductSearch_Helper.ERROR_REQUIRED_FIELD_MSG);

        if(o.Period__c == null)
            o.Period__c.addError(OpportunityProductSearch_Helper.ERROR_REQUIRED_FIELD_MSG);
        
        if(o.ServiceDate == null)
            o.ServiceDate.addError(OpportunityProductSearch_Helper.ERROR_REQUIRED_FIELD_MSG);
        
        if(o.Pattern__c == null)
            o.Pattern__c.addError(OpportunityProductSearch_Helper.ERROR_REQUIRED_FIELD_MSG);

        if(o.UnitPrice == null)
            o.UnitPrice.addError(OpportunityProductSearch_Helper.ERROR_REQUIRED_FIELD_MSG);
        
        if(o.of_Periods__c == null || o.Period__c == null || o.ServiceDate == null || o.Pattern__c == null || o.UnitPrice == null)
           isValid = false;

        return isValid;
    }
    
    
    public class ProductListWrapper {
        public List<ProductWrapper> prodList {get; set;}
        
        public ProductListWrapper (List<ProductWrapper> prodWrapList) {
            this.prodList = prodWrapList;
        }
        
        public ProductListWrapper (List<Product2> productList) {
            this.prodList = new List<ProductWrapper>();
            for (Product2 p : productList) {
                this.prodList.add(new ProductWrapper(p));
            }
        }
        
        public List<ProductWrapper> filterList(String keyword, String family, String prodCategory, String region) 
        {
            List<ProductWrapper> newList = new List<ProductWrapper>();
                
            for (ProductWrapper p : this.prodList) 
            {
                Boolean include = true;
                
                system.debug('=====p.product.Name=== ' + p.product.Name);
                
                if ((String.isBlank(p.product.Name) || (String.isNotBlank(keyword) && String.isNotBlank(p.product.Name) && !p.product.Name.containsIgnoreCase(keyword))) 
                    //&& (String.isBlank(p.product.Description) || (String.isNotBlank(keyword) && String.isNotBlank(p.product.Description) && !p.product.Description.containsIgnoreCase(keyword))) 
                    && (String.isBlank(p.product.PublicationList__c) || (String.isNotBlank(keyword) && String.isNotBlank(p.product.PublicationList__c) && !p.product.PublicationList__c.containsIgnoreCase(keyword)))
                    )
                {
                    include = false;
                }
                
                if ((String.isNotBlank(family) && String.isBlank(p.product.Family)) 
                    || (String.isNotBlank(family) && String.isNotBlank(p.product.Family) && !p.product.Family.equalsIgnoreCase(family)))
                {
                    include = false;    
                }
                
                if ((String.isNotBlank(prodCategory) && String.isBlank(p.product.Category__c))
                    || (String.isNotBlank(prodCategory) && String.isNotBlank(p.product.Category__c) && !p.product.Category__c.equalsIgnoreCase(prodCategory))) 
                {
                    include = false;    
                }
                
                if ((String.isNotBlank(region) && String.isBlank(p.product.Region__c)) 
                    || (String.isNotBlank(region) && String.isNotBlank(p.product.Region__c) && !p.product.Region__c.equalsIgnoreCase(region))) 
                {
                    include = false;    
                }

                if (include) newList.add(p);
            }
            
            return newList;
        }
    }
}