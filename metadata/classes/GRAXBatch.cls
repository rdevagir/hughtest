/* --------------------------------------------------------------------------
 * This file is subject to the terms and conditions defined in
 * file https://github.com/HardingPoint/GRAXForSFDC/blob/master/LICENSE,
 * which is part of this source code package.
 * --------------------------------------------------------------------------
 *          Copyright (c) 2017-2018 Harding Point
 *                  All rights reserved
 * --------------------------------------------------------------------------
 * Support:	Support@Grax.io
 * Website:	https://grax.io
 * Github:	https://github.com/HardingPoint/GRAXForSFDC
 * License:	https://github.com/HardingPoint/GRAXForSFDC/blob/master/LICENSE
 * --------------------------------------------------------------------------*/
 
 /*****************************************************************************************
Name              : GRAXBatch
Description       : THIS CLASS IS DEPRECATED
Revision History  :
Created/Modified by   Created/Modified Date     Requested by        Related Task/Issue     
----------------------------------------------------------------------------------------
1. Ariel Yankelevich     	05/07/2019          David Mackey        Remove Reference to GRAX Query Object (https://app.asana.com/0/326600806074978/1121760476564626/f)
2. Nahuel Leiva       		05/17/2019			David Mackey		Optichain Issues 5/7 (https://app.asana.com/0/326600806074978/1123545225466433/f)
3. Ariel Yankelevich    	05/31/2019          David Mackey        Constellation Prod Backup Issues (https://app.asana.com/0/326600806074978/1124574665749273/f)
4. Ariel Yankelevich     	06/05/2019          David Mackey        Optichain Issues 5/7 (https://app.asana.com/0/326600806074978/1123545225466433/f)
******************************************************************************************/

global class GRAXBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    global Integer recordsProcessed = 0;
    global Integer recordLimit = 200;
    
    global String Query = '';
    global String CurrentObjectName = '';
    
    global GRAXSettings gxcSettings = null;
    
    global GRAXBatch(String ObjectName){
        
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('Select Id From User Limit 1');
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope){
        
    }

    global void finish(Database.BatchableContext bc){
        
    }

	/*****************************************************************************************
	Name              : executeGRAXBatches
	Description       : Implent a backdoor method to execute the batches (Cleanup for any object, Delete, Resend) in "GRAXCloud" APEX Class
	Revision History  :
	Created/Modified by   Created/Modified Date     Requested by		Related Task/Issue     
	----------------------------------------------------------------------------------------
	1. Nahuel Leiva       		05/17/2019			David Mackey		Optichain Issues 5/7 (https://app.asana.com/0/326600806074978/1123545225466433/f)
	2. Ariel Yankelevich    	05/31/2019          David Mackey        Constellation Prod Backup Issues (https://app.asana.com/0/326600806074978/1124574665749273/f)
	3. Ariel Yankelevich     	06/05/2019          David Mackey        Optichain Issues 5/7 (https://app.asana.com/0/326600806074978/1123545225466433/f)
	******************************************************************************************/
    global static void executeGRAXBatches(String dataJSON) {
        String batchName = '';
        String jobId = null;
        String cleanObjectName = '';
        String query;
        Integer batchExecutionSize = 200;
        
        try {
            Map<String, Object> dataMap = (Map<String, Object>)JSON.deserializeUntyped(dataJSON);
            batchName = (String)dataMap.get('batchName');
            if (dataMap.containsKey('jobId')) {
                jobId = (String)dataMap.get('jobId');
            }
            if (dataMap.containsKey('cleanObjectName')) {
                cleanObjectName = (String)dataMap.get('cleanObjectName'); 
            }
            if(dataMap.containsKey('chunkSize')){
                Integer customSize = (Integer)dataMap.get('chunkSize');
                if(customSize > 0 && customSize <= 2000){
                	batchExecutionSize = customSize;
                } 
            }            
            if (dataMap.containsKey('query')) {
                query = (String)dataMap.get('query'); 
            }
            
            if (!String.isBlank(batchName)) {
                if (batchName == 'DeleteBackedUpData') {
                    GRAXBatchToDeleteBackedUpData batchToDelete = new GRAXBatchToDeleteBackedUpData();
                    batchToDelete.currentJobId = String.isEmpty(jobId) ? null : jobId;
                    batchToDelete.isExecuteNow = batchToDelete.currentJobId <> null ? true : false;
                    if(query <> null) batchToDelete.query = query;
                    if(batchToDelete.startToDeleteBackedUpData){
                    	database.executeBatch(batchToDelete, batchExecutionSize);
                    }
                }
                else if (batchName == 'ResendDataRecords') {
                    GRAXBatchToResendDataRecords batchToResend = new GRAXBatchToResendDataRecords();
                    batchToResend.currentJobId = String.isEmpty(jobId) ? null : jobId;
                    batchToResend.isExecuteNow = batchToResend.currentJobId <> null ? true : false;
                    if(query <> null) batchToResend.query = query;
                    database.executeBatch(batchToResend, 10);
                }
                else if (batchName == 'CleanDataRecords'){
                	Boolean useIdChunking = true;
                	if(dataMap.containsKey('useIdChunking')){
                		useIdChunking = (Boolean)dataMap.get('useIdChunking');
                	}
                	GRAXBatchToCleanDataRecords.useChunkingIdRangesStatic = useIdChunking;
                	
                	if(dataMap.containsKey('chunkIdRangeSize')){
                		GRAXBatchToCleanDataRecords.chunkIdRangeSizeStatic = (Integer)dataMap.get('chunkIdRangeSize');
                	}
                	
                    Integer indexOf = GRAXBatchToCleanDataRecords.objects2Execute.indexOf(cleanObjectName);
                    GRAXBatchToCleanDataRecords batchToClean = new GRAXBatchToCleanDataRecords((indexOf <> -1 ? indexOf : 0), (String.isEmpty(jobId) ? null : jobId), null);
                    if(query <> null) batchToClean.query = query;
                    database.executeBatch(batchToClean, batchExecutionSize);
                }
            } else {
                throw new GRAXException('JSON object is invalid');
            }
        }
        catch (Exception jsonNotValid) {
            throw jsonNotValid;
        }
    }
}