/*
 * 15-11-2018: 
 * This idea and implementation was done by Pratyush and it worked fine in AdSalesUAT. Putting this back in all environments.
 * Writing this Dummy Class to cater Do Nothing For Process Builder. Refer to email chain about the issue of Changing Stage of An Opportunity from Closed Won to Confirmed / Awaiting Booking
*/
public class AT_DummyClass {
    @InvocableMethod(label='Do Nothing')
    public static void doNothing(List<Id> ids) {
        // Do nothing
    }
}