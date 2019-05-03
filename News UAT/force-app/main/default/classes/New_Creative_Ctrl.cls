public class New_Creative_Ctrl {

    public New_Creative_Ctrl(ApexPages.StandardController controller) {

    }

 
    Public pagereference New_Creative_Method(){
        Id ProductordId = ApexPages.currentPage().getParameters().get('id');
        Id UserId = Userinfo.getuserId();
      Id CreativeId =  GenericWebServices.createCreativeForProductOrder(ProductordId, UserId);  
               pagereference p = new pagereference('/'+CreativeId);
                  p.setredirect(true);
                  return p;
                
    }

}