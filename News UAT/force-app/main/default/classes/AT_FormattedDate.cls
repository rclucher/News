/*
* Writing this Controller to cater the timezone issue of Escalation DateTime in Email Body
* @Author: Mohsin Ali
* 28-10-2018
*/
public class AT_FormattedDate {
 public DateTime date_time {
  get;
  set;
 } //property that reads the datetime value from component attribute tag
 public String defined_format {
  get;
  set;
 } //property that reads the string value from component attribute tag
 public String getFormattedDatetime() {
  if (date_time == null) {   return '';
  } else {
   if (defined_format == null) {
    return date_time.format(); //return the full date/time in user's locale and time zone
   } else {
    return date_time.format(defined_format, 'Australia/Sydney');
   }
  }
 }
}