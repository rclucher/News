/*---------------------------------------------------------
 * Author: David Dawson
 * Company: Bluewolf
 * Description: This trigger has been created to facilitate a shared single function to generate 
                external ids, to ensure that the same external id is generated everytime no matter 
                how often it is referenced within code.
 * History: Trigger Created.
            Generate monthid functionality added (as this is also generated in several places in code and needs to be universal)
 ---------------------------------------------------------*/

public class ExternalIdUtility {
    public static String SalesSummaryExternalId(String UserExtId, String UserRole, String Type, String RevType, String TimeId){
        String ExternalId = '';
        
        ExternalId = UserExtId;

        //removed the role from external id due to requirement changing

        if(Type != null){
            ExternalId += ';' + Type;
        }

        ExternalId += ';' + RevType;

        if(TimeId != null){
            ExternalId += ';' + TimeId;
        }

        return ExternalId;
    }

    /*public static String generateMonthId(Date genDate){
        String monthId = '';
        
        if(genDate != null){
            //generate the monthId
            String textMonth = '';
            Integer month = genDate.month();
            if(String.valueOf(month).length() < 2){
                textMonth = '0' + String.valueOf(month);
            }else{
                textMonth = String.valueOf(month);
            }
            monthId = String.valueOf(genDate.year()) + textMonth;
        }
        
        return monthId;
    }*/
}