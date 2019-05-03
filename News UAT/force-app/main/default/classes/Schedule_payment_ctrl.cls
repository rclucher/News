public class Schedule_payment_ctrl {
    @Auraenabled
    public static string schedulePayment(Id OpportunityId){
      
      String result = Order_PaymentSchedulerController.checkActualStartDate(OpportunityId);
      if (result=='true')
      {
            result = Order_PaymentSchedulerController.updateOrder_Payment(OpportunityId);
      }
      /*
      else
      {
          result='ActualDateError';
      }
      */
      System.debug('***Schedule_payment_ctrl result=' + result);
      
      return result;

      
    }
}