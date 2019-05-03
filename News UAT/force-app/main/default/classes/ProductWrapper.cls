public class ProductWrapper 
{
    public Boolean isSelect { get; set; }
    public Product2 product { get; set; }
    public List<String> publicationList { get{ return publicationList = publicationList == null ? new List<String>() : publicationList; } set; }
    public String publicationsAbbr { get; set; }
    
    
    public ProductWrapper(Product2 productParam)
    {
        this.isSelect = false;
        this.product = productParam;
        
        if(String.isNotBlank(productParam.PublicationList__c))
        {
        	String publications = productParam.PublicationList__c.subString(1);
        	publicationList = publications.split(';');
        	publicationsAbbr = publications.abbreviate(15, 3);
        }
        
    }
}