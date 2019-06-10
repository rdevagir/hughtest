/*****************************************************************************************
Name              : GRAXSchedulerToDeleteBackedUpDataTest
Description       : 
Revision History  :
Created/Modified by   Created/Modified Date     Requested by        Related Task/Issue     
----------------------------------------------------------------------------------------
1. Leandro Brunner    05/23/2018                David Mackey        "Restore" Button for Backup/Archive (https://app.asana.com/0/326600806074978/665432711419635/f)
******************************************************************************************/
@isTest
public class GRAXSchedulerToDeleteBackedUpDataTest {
    static testmethod void GRAXSchedulerToDeleteBackedUpDataTest() {
        Test.startTest();
        
        Datetime dt = Datetime.now().addMinutes(1);
        String CRON_EXP = '0 '+ dt.minute() + ' * ' + dt.day() + ' ' + dt.month() + ' ? ' + dt.year();

        String jobId = System.schedule('GRAXSchedulerToDeleteBackedUpData', CRON_EXP, new GRAXSchedulerToDeleteBackedUpData());

        Test.stopTest();
    }
}