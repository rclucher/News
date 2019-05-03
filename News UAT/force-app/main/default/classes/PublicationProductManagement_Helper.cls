/*---------------------------------------------------------
    Author: Bohao Chen
    Company: Salesforce.com
    Description: this is controller for trigger 'PublicationProductManagement' relates to requirement R-0822.
    History:
    2/09/2013   Bohao Chen  Created
---------------------------------------------------------*/
public with sharing class PublicationProductManagement_Helper
{
    // this function will update publications value on standard product object 
    public static void updatePublications(Map<String, List<String>> deletePublicationsByProductId,
                                                    Map<String, List<String>> insertPublicationsByProductId)
    {
        List<Product2> products = new List<Product2>();  
        
        // combine all product id together for single query
        Set<String> allProductIds = new Set<String>();
        
        if(deletePublicationsByProductId.size() > 0)
        {
            allProductIds.addAll(deletePublicationsByProductId.keySet());
        }

        if(insertPublicationsByProductId.size() > 0)
        {
            allProductIds.addAll(insertPublicationsByProductId.keySet());
        }       
        
        for(Product2 p : [Select p.PublicationList__c, p.Id From Product2 p Where p.Id IN: allProductIds])
        {
            system.debug('===BC: p==== ' + p.Id);
            
            
            // if deletePublicationsByProductId contains product id,
            // it means publication has to be deleted from current product
            if(deletePublicationsByProductId.containsKey(p.Id))
            {
                p.PublicationList__c = PublicationProductManagement_Helper.updatePublicationsValueOnProduct(p.PublicationList__c, deletePublicationsByProductId.get(p.Id), 'delete');
            }
            
            // if insertPublicationsByProductId contains product id,
            // it means publication has to be added to current product
            if(insertPublicationsByProductId.containsKey(p.Id))
            {
                p.PublicationList__c = PublicationProductManagement_Helper.updatePublicationsValueOnProduct(p.PublicationList__c, insertPublicationsByProductId.get(p.Id), 'insert');
            }
            
            if(deletePublicationsByProductId.containsKey(p.Id) || insertPublicationsByProductId.containsKey(p.Id))
            {
                products.add(p);
            }
        }
        
        system.debug('====updating products=== ' + products);
        update products;
    }
    
    private static String updatePublicationsValueOnProduct(String publicationsString, List<String> publicationList, String actionType)
    {
        system.debug('====BC: publicationsString==== ' + publicationsString);
        system.debug('====BC: publicationList==== ' + publicationList);
        system.debug('====BC: actionType==== ' + actionType);
        
        // if action type is 'insert'
        if(actionType == 'insert')
        {
            Set<String> currentPublicationSet = new Set<String>();
            
            if(String.isNotBlank(publicationsString))
            {
                currentPublicationSet.addAll(publicationsString.split(';'));
            }
            
            system.debug('====BC: currentPublicationSet==== ' + currentPublicationSet);
            
            for(String publication : publicationList)
            {
                // if new publication doesn't exist in current publications on product, add it to publications on product
               if(!currentPublicationSet.contains(publication))
               {
                   if(String.isBlank(publicationsString))
                   {
                       publicationsString = ';' + publication;
                   }
                   else
                   {
                       publicationsString += ';' + publication;
                   }
                   
                   currentPublicationSet.add(publication);
               }
            }
            
            system.debug('===insert publicationsString=== ' + publicationsString);
        }
        // if action type is 'delete'
        else if(actionType == 'delete')
        {
            List<String> currentPublicationList = new List<String>();
            
            if(String.isNotBlank(publicationsString))
            {
                currentPublicationList = publicationsString.split(';');
            }
            
            system.debug('====BC: currentPublicationList==== ' + currentPublicationList);
            
            Set<String> deletePublicationSet = new Set<String>();
            deletePublicationSet.addAll(publicationList);
            
            List<String> newPublicationList = new List<String>();
            
            for(String publication : currentPublicationList)
            {
                // if action type is delete and publication set contains this publication,
                // this publication has to be deleted from publication set
                if(!deletePublicationSet.contains(publication))
                {
                    newPublicationList.add(publication);
                }
            }
        
            publicationsString = String.join(newPublicationList, ';');
            
            system.debug('===delete publicationsString=== ' + publicationsString);
        }
        
        return publicationsString;
    }
}