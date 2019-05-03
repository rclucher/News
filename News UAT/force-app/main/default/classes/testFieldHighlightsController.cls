/*---------------------------------------------------------
 * Author: Logabalakrishnan (LBK) Muthukrishnan
 * Company: News
 * Description: 
 * 1. This test class is for requirement: R-NNNN.
 *              The purpose of this test class is to code cover the trigger FieldHighlightsController. 
 * History:
 * 2018-03-23	LBK		Created (Code coverage achieved - 100%)
 ---------------------------------------------------------*/
@IsTest (SeeAllData=true)
public class testFieldHighlightsController {
    static testmethod void testGetFieldSet() {
        List<String> sFieldSet = FieldHighlightsController.getFieldSet('Account', 'business_customer_create');
    }
}