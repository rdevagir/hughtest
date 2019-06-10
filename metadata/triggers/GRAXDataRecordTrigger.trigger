/*****************************************************************************************
Name              : GRAXDataRecordTrigger
Description       : -
Revision History  :
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Ariel Yankelevich       06/06/2018           David Mackey        Backup and Restore Notes & Attachments (https://app.asana.com/0/326600806074978/692982800286805/f)
******************************************************************************************/

trigger GRAXDataRecordTrigger on GRAX_Data_Record__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
	GRAXDataRecordTriggerHandler.triggerExecute();
}