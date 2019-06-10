/*****************************************************************************************
Name              : GRAXScheduleProcessTrigger
Description       : -
Revision History  :
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Leandro Brunner       06/06/2018           David Mackey        Backup and Restore Notes & Attachments (https://app.asana.com/0/326600806074978/692982800286805/f)
******************************************************************************************/
trigger GRAXScheduleProcessTrigger on GRAX_Schedule_Process__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
	GRAXScheduleProcessTriggerHandler.triggerExecute();
}