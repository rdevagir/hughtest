/*****************************************************************************************
Name              : GRAXBatchToProcessSchedJob
Description       : This batch process executes a GRAX Schedule Process job, calling itself object by object as defined in the selected hierarchy
Revision History  :
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Ariel Yankelevich       04/26/2018           David Mackey        GRAX Audit Trail Process (https://app.asana.com/0/326600806074978/633149554508926/f)
2. Ariel Yankelevich       06/05/2018           David Mackey        Backup and Restore Notes & Attachments (https://app.asana.com/0/326600806074978/692982800286805/f)
3. Ariel Yankelevich       07/18/2018           David Mackey        Multi-Object Backup (https://app.asana.com/0/326600806074978/743044564916005/f)
4. Ariel Yankelevich       07/31/2018           David Mackey        Too many fields/too much to query errors (https://app.asana.com/0/326600806074978/763054542504017/f)
5. Leandro Brunner         08/07/2018           David Mackey        Agco Fixes (https://app.asana.com/0/326600806074978/770976244463043/f)
6. Leandro Brunner         08/22/2018           David Mackey        Initial Backup updates (https://app.asana.com/0/326600806074978/788118599521250/f)
7. Leandro Brunner         09/20/2018           David Mackey        Agco Fixes (https://app.asana.com/0/326600806074978/770976244463043/f)
8. Leandro Brunner         10/08/2018           David Mackey        Hierarchy Backup Updates (https://app.asana.com/0/326600806074978/853752416552300/f)
9. Ariel Yankelevich       10/11/2018           David Mackey        Minor Updates (https://app.asana.com/0/326600806074978/857103514581849/f)
10. Leandro Brunner        11/06/2018           David Mackey        Minor UI Enhancements (https://app.asana.com/0/326600806074978/880565726418326/f)
11. Ariel Yankelevich      11/27/2018           David Mackey        Updates for 11/27 (https://app.asana.com/0/326600806074978/923502192371298/f)
12. Ariel Yankelevich      12/05/2018           David Mackey        Mass Restore multiple records (https://app.asana.com/0/326600806074978/774373429525631)
13. Leandro Brunner        12/27/2018           David Mackey        Backup/Archive UI Updates (https://app.asana.com/0/326600806074978/950283827722121/f)
14. Ariel Yankelevich      01/03/2019           David Mackey        Chatter Backup (https://app.asana.com/0/326600806074978/958019584834204/f)
15. Ariel Yankelevich      01/14/2019           David Mackey        Enhance Scheduled Process Run Date (https://app.asana.com/0/326600806074978/982049496535989/f)
16. Ariel Yankelevich      01/21/2019           David Mackey        Backup of Tasks/Events older than 1 year (https://app.asana.com/0/326600806074978/996594710085394/f)
17. Ariel Yankelevich      01/25/2019           David Mackey        ContentDocument (objects) Restore (https://app.asana.com/0/326600806074978/985052780814601/f)
18. Ariel Yankelevich      02/08/2019           David Mackey        Ability to Archive Attachments, but not the Parent (https://app.asana.com/0/326600806074978/1108143662698786/f)
19. Ariel Yankelevich      02/15/2019           David Mackey        Show Scheduled Process Context User's Time Zone (https://app.asana.com/0/326600806074978/1105533057427277/f)
20. Leandro Brunner        02/26/2019           David Mackey        Update Backup Process (https://app.asana.com/0/326600806074978/1109887667389108/f)
21. Ariel Yankelevich      03/14/2019          	David Mackey        Oak North Issues (https://app.asana.com/0/326600806074978/1114340491893894/f)
22. Ariel Yankelevich      03/15/2019          	David Mackey        Oak North Updates #2 (https://app.asana.com/0/326600806074978/1114502823954369/f)
23. Ariel Yankelevich      04/04/2019          	David Mackey        Enhance Backup Query (https://app.asana.com/0/326600806074978/1117046362603245/f)
24. Ariel Yankelevich      04/09/2019          	David Mackey        GRAX Archive Error Message (https://app.asana.com/0/326600806074978/1117627231071642/f)
25. Ariel Yankelevich      04/23/2019          	David Mackey        Jobs with No Data Stuck in 'Pending' Status (https://app.asana.com/0/1118660079719642/1119642059935649/f)
26. Nicolas Ralero		   04/29/2019			David Mackey		Can we back up SetupAuditTrail Object (https://app.asana.com/0/326600806074978/1120147888058592/f)
27. Ariel Yankelevich	   05/13/2019			David Mackey		Optichains Prod Backup Issues (https://app.asana.com/0/326600806074978/1122687086503529/f)
28. Nicolas Ralero		   05/15/2019			David Mackey		Updating Object Progress % (https://app.asana.com/0/326600806074978/1122723602378290/f)
29. Ariel Yankelevich	   05/31/2019			David Mackey		Hourly Backup (https://app.asana.com/0/326600806074978/1125321540023340/f)
******************************************************************************************/
global class GRAXBatchToProcessSchedJob implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {
    public String query = '';
    public List<GRAXBackupCtrl.ObjRelStructure> objects2Process;
    public Integer currentElementIndex;
    public String currentJobId;
    public String currentSelectCriteria;
    public String currentObjRelStrucUniqueKey;
    public String currentArchiveProcessId;
    public Integer maxParentIds2ProcessByChildIteration = 5000;
    public List<Id> parentIds2ProcessForChild;
    public List<Id> graxDataRecIds2ProcessForChild;
    public Boolean isArchive = false;
    public Boolean isExecuteNow = false;
    public Boolean isMultiObjectRunning = false;
    public Set<String> customObjects2ProcessAdded;
    public Boolean isProgressive = false;
    public String executionUniqueKey;
    public DateTime lastStartTime;
    public Datetime lastRunDate;
    public Boolean addContentDocument;
    public Boolean hasMoreRecords2Process;
    public Set<String> filesParentSelectionList;
    public Boolean isFilesBackup;
    public DateTime overallSFObjectProcessStartTime;
    public Id lastGRAXDataRecordIdForCurrentSFObject;
    public Map<String, Object> progressiveStartDatetimeByObject;
    public DateTime currentSFObjectProgressiveStartTime;
    
    // These are static variables used in the Constructor method to get the value from the previous run
    public static Boolean isProgressiveStatic = false;
    public static String executionUniqueKeyStatic;
    public static DateTime lastStartTimeStatic;
    public static DateTime lastRunDateStatic;
    public static Boolean isFilesBackupStatic = false;
    public static DateTime overallSFObjectProcessStartTimeStatic = null;
    public static Map<String, Object> progressiveStartDatetimeByObjectStatic = new Map<String, Object>();
    public static DateTime currentSFObjectProgressiveStartTimeStatic = null;
	public static Integer maxParentIds2ProcessByChildIterationStatic = null;

	private Set<String> asyncObjects2ProcessByGRAX = new Set<String>{'Attachment', 'ContentVersion'};
    private Set<String> archivedObjects2QueryAllRows = new Set<String>{'Event', 'Task'};
    private static Map<String, List<String>> objectFieldsMapToExclude = new Map<String, List<String>>{
        'Account' => new List<String>{'ChannelProgramName', 'ChannelProgramLevelName'},
        'Case' => new List<String>{'Comments'},
        'Campaign' => new List<String>{'TotalLandingPageViews'},
        'WorkOrder' => new List<String>{'IsGeneratedFromMaintenancePlan'}
    };
    private Set<String> objectNames2SkipErrorLogging = new Set<String>{'FeedAttachment'};
    
    
    public GRAXBatchToProcessSchedJob(String jobId, List<GRAXBackupCtrl.ObjRelStructure> objects2Process, Integer elementIndex, String selectCriteria, Boolean isExecuteNow, Boolean isMultiObjectRunning){
        this.objects2Process = objects2Process;
        this.currentElementIndex = elementIndex;
        this.currentJobId = jobId;
        this.currentSelectCriteria = selectCriteria;
        this.parentIds2ProcessForChild = new List<Id>();
        this.graxDataRecIds2ProcessForChild = new List<Id>();
        this.isArchive = isArchive;
        this.isExecuteNow = isExecuteNow <> null ? isExecuteNow : false;
        this.customObjects2ProcessAdded = new Set<String>();
        this.isMultiObjectRunning = isMultiObjectRunning;
        this.addContentDocument = true;
        this.hasMoreRecords2Process = false;
        this.filesParentSelectionList = new Set<String>();
        this.isFilesBackup = false;
        this.overallSFObjectProcessStartTime = overallSFObjectProcessStartTimeStatic;
        this.progressiveStartDatetimeByObject = progressiveStartDatetimeByObjectStatic;
        this.currentSFObjectProgressiveStartTime = currentSFObjectProgressiveStartTimeStatic;

        Boolean skipSObject = true;

        String criteriaDateField;
        Datetime criteriaDateValue, criteriaEndDateValue;
        String criteriaDateOperator, criteriaEndDateOperator;
        String schedProcessSelectCriteria;

        if(objects2Process == null || (isMultiObjectRunning && this.objects2Process[this.currentElementIndex].relatedFieldName == null)){
            GRAX_Schedule_Process__c schedProcess = [SELECT Id, Object_Name__c, Select_Criteria__c, Target_Start_Datetime__c, Target_End_Datetime__c, Date_Field__c, Archive__c, Last_Run_Date__c, Last_Start_Time__c, Execution_Unique_Key__c, Progressive__c, Total_Objects_To_Process__c, Total_Objects_Processed__c, Total_Records_To_Send__c, Total_Records_Sent__c, (SELECT Id, Execution_Unique_Key__c FROM GRAX_Archive_Processes__r) FROM GRAX_Schedule_Process__c WHERE Id =: jobId];
            this.isProgressive = schedProcess.Progressive__c;
            this.executionUniqueKey = schedProcess.Execution_Unique_Key__c;
            this.lastStartTime = schedProcess.Last_Start_Time__c;
            this.lastRunDate = schedProcess.Last_Run_Date__c;
            this.isFilesBackup = schedProcess.Object_Name__c.equalsIgnoreCase('Attachment') || schedProcess.Object_Name__c.equalsIgnoreCase('ContentVersion');

            if(!isMultiObjectRunning){
                // If this is the first time the batch is firing for the current Schedule Process
                // calculate the selected object hierarchy and initial query
                String selectedObjectHierarchyJSON = GRAXUtils.getSelectionJSON(schedProcess.Id);
    
                // If this schedule job was set as an archive process, create the associted record and then also associate it to the GRAX Data Records
                if(schedProcess.Archive__c){
                	
                	// Verify if the "Archive" record already exists (in case the logic is called just to populate the public variables)
                	Boolean archiveRecordExists = false;
                	for(GRAX_Archive_Process__c gap : schedProcess.GRAX_Archive_Processes__r){
                		if(gap.Execution_Unique_Key__c == schedProcess.Execution_Unique_Key__c){
                			archiveRecordExists = true;
                			currentArchiveProcessId = gap.Id;
                			break;
                		}
                	}
                	
                	if(!archiveRecordExists){
	                    GRAX_Archive_Process__c archiveProc = new GRAX_Archive_Process__c();
	                    archiveProc.GRAX_Schedule_Process__c = schedProcess.Id;
	                    archiveProc.Execution_Unique_Key__c = schedProcess.Execution_Unique_Key__c;
	                    archiveProc.Async_Records_Successfully_Sent__c = 0;
	                    archiveProc.Async_Records_to_Process__c = 0;
	                    archiveProc.Records_Successfully_Sent__c = 0;
	                    archiveProc.Records_To_Process__c = 0;
	                    insert archiveProc;
	                    
	                    currentArchiveProcessId = archiveProc.Id;
                	}	                    
                }
                
                if(Test.isRunningTest() && String.isBlank(selectedObjectHierarchyJSON)) selectedObjectHierarchyJSON = '{}';

                // Get the JSON string and convert it to the object structure
                GRAXBackupCtrl.ObjRelStructure rootSObj = (GRAXBackupCtrl.ObjRelStructure)JSON.deserialize(selectedObjectHierarchyJSON, GRAXBackupCtrl.ObjRelStructure.class);
                
                // Now we have to make this structure flat, in order to process the objects one by one
                this.objects2Process = new List<GRAXBackupCtrl.ObjRelStructure>();
                this.objects2Process.add(rootSObj);
                
                Integer i = 0;
                while(this.objects2Process.size() > 0 && i < this.objects2Process.size()){
                    GRAXBackupCtrl.ObjRelStructure sObjRelStruc = this.objects2Process[i];
                    
                    // Add all the child relationships for this SObject 
                    if(sObjRelStruc.childObjRelStructure <> null) this.objects2Process.addAll(sObjRelStruc.childObjRelStructure);
                    
                    i++;
                }
                
                // Define the rest of the main variables
                this.currentObjRelStrucUniqueKey = rootSObj.uniqueKey;
                this.isArchive = schedProcess.Archive__c;
                
                criteriaDateField = 'CreatedDate';
                criteriaDateValue = Datetime.now().addYears(100);
                criteriaDateOperator = '<=';
                schedProcessSelectCriteria = schedProcess.Select_Criteria__c;
                
                if(schedProcess.Date_Field__c <> null){
                    criteriaDateField = schedProcess.Date_Field__c;
                }

                if(schedProcess.Target_Start_Datetime__c <> null) {
                    criteriaDateValue = schedProcess.Target_Start_Datetime__c;
                    criteriaDateOperator = '>=';
                }
                
                if(schedProcess.Target_End_Datetime__c <> null) {
                    criteriaEndDateValue = schedProcess.Target_End_Datetime__c;
                    criteriaEndDateOperator = '<';
                }
            }else{
                // If the Multi-Object process is executing and the Object structure has not been loaded
                if(objects2Process == null){
                    String selectedMultiObjectJSON = GRAXUtils.getSelectionJSON(jobId);
            
                    // Parse this JSON and generate a new list of objects to iterate
                    this.objects2Process = (List<GRAXBackupCtrl.ObjRelStructure>)JSON.deserialize(selectedMultiObjectJSON, List<GRAXBackupCtrl.ObjRelStructure>.class);
                }

                criteriaDateField = 'CreatedDate';
                criteriaDateValue = Datetime.now().addYears(100);
                //schedProcessSelectCriteria = 'Main Object not modified';
                criteriaDateOperator = '<=';

                if(schedProcess.Target_Start_Datetime__c <> null) {
                    criteriaDateField = this.objects2Process[this.currentElementIndex].name.equalsIgnoreCase('SetupAuditTrail') ? 'CreatedDate' : 'LastModifiedDate';
                    criteriaDateValue = schedProcess.Target_Start_Datetime__c;
                    criteriaDateOperator = '>=';
                }
            }
            
            // Verify if the current Object Name is a valid SObject
            if(GRAXUtils.sObjectExists(this.objects2Process[this.currentElementIndex].name)) {
                skipSObject = false;

                this.currentObjRelStrucUniqueKey = this.objects2Process[this.currentElementIndex].uniqueKey;
                    
                String rootObjSelectCriteria = '';
                this.currentSelectCriteria = '';
                
                String objName = this.objects2Process[this.currentElementIndex].name;
                
                // Verify that the "criteriaDateField" (CreatedDate or LastModifiedDate) exist on this Object
                if(!GRAXUtils.getDescribeFieldsResultForObject(objName).containsKey(criteriaDateField)){
                    // If it doesn't exist use the field SystemModstamp
                    criteriaDateField = 'SystemModstamp';
                    
                    // Verify that the "SystemModstamp" (CreatedDate or LastModifiedDate) exist on this Object
                    if(!GRAXUtils.getDescribeFieldsResultForObject(objName).containsKey(criteriaDateField)){
                        // Skip this object if it doesn't have any of these datetime fields
                        skipSObject = true;
                    }
                }
                                
                // Set up the date / datetime in the filter criteria
                String dateFieldType = getFieldType(objName, criteriaDateField);
                                
                //if(schedProcessSelectCriteria == 'Main Object not modified'){
                if(criteriaDateValue <> null) {
                	String dateFieldValue = criteriaDateValue.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.000\'Z\'');
                	if(dateFieldType.equalsIgnoreCase('Date')){
                		dateFieldValue = criteriaDateValue.formatGmt('yyyy-MM-dd');
                	}
                	
                    rootObjSelectCriteria = criteriaDateField + ' ' + criteriaDateOperator + ' ' + dateFieldValue;
                }

                if(criteriaEndDateValue <> null) {
                    String endDateFieldValue = criteriaEndDateValue.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.000\'Z\'');
                    if(dateFieldType.equalsIgnoreCase('Date')){
                		endDateFieldValue = criteriaEndDateValue.addDays(1).formatGmt('yyyy-MM-dd');
                	}
                    
                    if(String.isNotBlank(rootObjSelectCriteria)) {
                        rootObjSelectCriteria += ' AND ';
                    }
                    rootObjSelectCriteria += criteriaDateField + ' ' + criteriaEndDateOperator + ' ' + endDateFieldValue;
                }
                //}

                //else if(schedProcess.Select_Criteria__c == 'Main Object and Children not modified'){
                //    this.currentSelectCriteria = 'LastModifiedDate <= ' + schedProcess.Selected_Time_Frame__c;
                //}
                
                query = 'SELECT Id' + (objName.equalsIgnoreCase('ContentDocumentLink')? ', LinkedEntityId' : '') + (objName.endsWithIgnoreCase('__kav')? ', KnowledgeArticleId' : '') + (objName.endsWithIgnoreCase('Attachment')? ', Parent.Type' : '') + ' FROM ' + objName;

                if(String.isNotBlank(rootObjSelectCriteria)){
                    query += ' WHERE ' + rootObjSelectCriteria;
                }
                
                // If this object is possible archived, only query the non-deleted records
                if(archivedObjects2QueryAllRows.contains(objName)){
                    query += (query.contains(' WHERE ')? ' AND ' : ' WHERE ') + 'IsDeleted=false';
                }
                
                // Include the ContentDocumentLink as a main object, and get every "private" ContentDocument record
                if(objName.equalsIgnoreCase('ContentDocumentLink')){
                    query += (query.contains(' WHERE ')? ' AND ' : ' WHERE ') + 'LinkedEntityId IN (Select Id from User)';
                }
            }
        }else{
            // Get the variable values from the respective Static variable
            this.isProgressive = isProgressiveStatic;
            this.executionUniqueKey = executionUniqueKeyStatic;
            this.lastStartTime = lastStartTimeStatic;
            this.lastRunDate = lastRunDateStatic;
            this.isFilesBackup = isFilesBackupStatic;
			if(maxParentIds2ProcessByChildIterationStatic <> null){
				this.maxParentIds2ProcessByChildIteration = maxParentIds2ProcessByChildIterationStatic;
			}

			// Get the current child object structure
            GRAXBackupCtrl.ObjRelStructure sObjRelStruc = this.objects2Process[this.currentElementIndex];

            // Verify if the current Object Name is a valid SObject
            if(GRAXUtils.sObjectExists(sObjRelStruc.name)) {
                skipSObject = false;

                this.currentObjRelStrucUniqueKey = sObjRelStruc.uniqueKey;

                // Get the parent record Ids that still haven't been processed
                for(GRAX_Data_Record_Id__c grxDRId : [SELECT Id, SFDC_Id__c FROM GRAX_Data_Record_Id__c WHERE ((Processed_Child_Index__c <: this.currentElementIndex AND Execution_Unique_Key__c =: this.executionUniqueKey) OR (GRAX_Data_Record__r.GRAX_Schedule_Process__r.Progressive__c = true AND Execution_Unique_Key__c <> :this.executionUniqueKey)) AND GRAX_Data_Record__r.GRAX_Schedule_Process__c =: this.currentJobId AND GRAX_Data_Record__r.Sched_Proc_Hierarchy_Unique_Key__c =: sObjRelStruc.parentUniqueKey LIMIT :maxParentIds2ProcessByChildIteration]){
                    this.parentIds2ProcessForChild.add(grxDRId.SFDC_Id__c);
                    this.graxDataRecIds2ProcessForChild.add(grxDRId.Id);
                }
                
                // The condition on the SELECT statement is added to avoid hitting the filter error on ContentDocumentLink object
                // There is also a condition for KnowledgeArticleVersion to retrieve archived versions of an Article
                query = 'SELECT Id' + (sObjRelStruc.name.equalsIgnoreCase('ContentDocumentLink')? ', LinkedEntityId, LinkedEntity.Type' : '') + (sObjRelStruc.name.endsWithIgnoreCase('Attachment')? ', Parent.Type' : '') + ' FROM ' + sObjRelStruc.name;
                query += ' WHERE ' + sObjRelStruc.relatedFieldName + ' IN :parentIds2ProcessForChild' + (sObjRelStruc.name.endsWithIgnoreCase('__kav')? ' AND IsLatestVersion=false AND PublishStatus = \'Archived\'' : '') + (archivedObjects2QueryAllRows.contains(sObjRelStruc.name)? ' AND IsDeleted=false' : '');
                
                if(String.isNotBlank(this.currentSelectCriteria)){
                    query += ' AND ' + this.currentSelectCriteria;
                }
                
                // If the ContentDocumentLink table is being queried as a child of ContentDocument, then there is no need to add this extra table (ContentDocument) during the execution
                if((sObjRelStruc.name.equalsIgnoreCase('ContentDocumentLink') && sObjRelStruc.relatedFieldName.equalsIgnoreCase('ContentDocumentId') && !this.isFilesBackup) || (sObjRelStruc.name.equalsIgnoreCase('FeedAttachment') && sObjRelStruc.relatedFieldName.equalsIgnoreCase('RecordId')) || (sObjRelStruc.name.equalsIgnoreCase('FeedComment') && sObjRelStruc.relatedFieldName.equalsIgnoreCase('RelatedRecordId'))){
                    this.addContentDocument = false;
                }
                
                if(sObjRelStruc.name.equalsIgnoreCase('ContentDocumentLink') && this.parentIds2ProcessForChild.size() == 0){
                	skipSObject = true;
                }
            }
        }
        
        String objName = this.objects2Process[this.currentElementIndex].name;
        
        if(objName.equalsIgnoreCase('Attachment') || objName.equalsIgnoreCase('ContentDocumentLink')){
        	String parentsSelectionJSON = GRAXUtils.getSelectionJSON(GRAXUtils.getSelectionAttachment(jobId, 'ParentsSelectionJSON.txt'));
        	
        	if(!String.isBlank(parentsSelectionJSON) && parentsSelectionJSON <> '{}'){
        		for(Object parentObjName : (List<Object>)JSON.deserializeUntyped(parentsSelectionJSON)){
        			this.filesParentSelectionList.add((String)parentObjName);
        		}
        		
        		// This filter only works for Attachments. For ContentDocumentLink it is required to filter it in the code
        		if(objName.equalsIgnoreCase('Attachment')){
        			query += (query.contains(' WHERE ')? ' AND ' : ' WHERE ') + 'Parent.Type IN (\'' + String.join(new List<String>(this.filesParentSelectionList), '\',\'') + '\')';
        		}
        	}
        }

        if(!skipSObject && this.isProgressive) {
        	// Only set the progressive start time variable the first time this Object is processed
            if(currentSFObjectProgressiveStartTime == null){
            	currentSFObjectProgressiveStartTime = System.now();
            }
	            
        	if(this.lastRunDate <> null && this.lastStartTime <> null) {
	            String progressiveDateField = objName.equalsIgnoreCase('SetupAuditTrail') ? 'CreatedDate' : 'LastModifiedDate';
	            
	            // Verify that the "progressiveDateField" (LastModifiedDate) exist on this Object
	            if(!GRAXUtils.getDescribeFieldsResultForObject(objName).containsKey(progressiveDateField)){
	                // If it doesn't exist use the field SystemModstamp
	                progressiveDateField = 'SystemModstamp';
	            }
	            
	            // Get the stored Last Start Dates for each processed object from the file "ProgressiveDatesJSON.txt"
	            if(this.progressiveStartDatetimeByObject.size() == 0){
	            	String progressiveStartDatetimeByObjectJSON = GRAXUtils.getSelectionJSON(GRAXUtils.getSelectionAttachment(jobId, 'ProgressiveDatesJSON.txt'));
	            	if(!String.isBlank(progressiveStartDatetimeByObjectJSON) && progressiveStartDatetimeByObjectJSON <> '{}'){
	            		this.progressiveStartDatetimeByObject = (Map<String, Object>)JSON.deserializeUntyped(progressiveStartDatetimeByObjectJSON);
	            	}
	            }
	            
	            // Define the Last Start Date to use. It could be the one stored in the JSON or the overall process Last Start Time
	            Datetime progressiveDateValue = this.lastStartTime;
	            if(this.progressiveStartDatetimeByObject.containsKey(objName)){
	            	progressiveDateValue = Datetime.newInstance((Long)this.progressiveStartDatetimeByObject.get(objName));
	            }
	            
	            query += ' AND ' + progressiveDateField + ' >= ' + progressiveDateValue.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.000\'Z\'');
	        }
        }
        
        if(!skipSObject){
            try{
                // Test the query to verify if it's valid and check if it returns at least one record
                this.hasMoreRecords2Process = Database.query(query + ' LIMIT 1' + (archivedObjects2QueryAllRows.contains(objName)? ' ALL ROWS' : '')).size() > 0;
            }catch(Exception e){
                skipSObject = true;
                
                System.debug('Skipping object. The query is: ' + query);
                
                // Log this error to GRAX
                if(!Test.isRunningTest() && !objectNames2SkipErrorLogging.contains(objName)) GRAXLogs.addLogException(e, 'Skipping the backup for object ' + objName + '.');
            }
        }

        if(skipSObject) {
            query = 'SELECT Id FROM User WHERE Id = null';
        }
        
        // Add a keyword to the SOQL query, in order to retrieve archived records
        if(archivedObjects2QueryAllRows.contains(objName)){
            query += ' ALL ROWS';
        }
        
        System.debug('The object Query is: ' + query);
    }
    
    global Iterable<SObject> start(Database.BatchableContext BC) {
        return Database.query(query);
    }

    global void execute(Database.BatchableContext BC, List<SObject> scope) {
        executeMethod(BC, scope);
    }
    
    global void finish(Database.BatchableContext BC){
        finishMethod(BC);
    }
    
    public void executeMethod(Database.BatchableContext BC, List<SObject> scope){
        if(GRAXUtils.checkIfScheduleIsAborted(this.currentJobId)) {
            try {
                System.abortJob(BC.getJobId());
            } catch (Exception e) {}

            return;
        }
        
        // Set the Overall SFObject Process Start Time if it's empty
        if(this.overallSFObjectProcessStartTime == null){
        	this.overallSFObjectProcessStartTime = System.now();
        }
        
        // Get the current object structure
        GRAXBackupCtrl.ObjRelStructure sObjStruc = this.objects2Process[this.currentElementIndex];
		
		try{
	        // Get the SObject Name of the current object
	        String sobjectName = sObjStruc.name;
	        
	        List<Id> scopeIds = new List<Id>();
	        
	        // Evaluate the field that will be used in the queries based on the current object and settings
	        String queryField = sobjectName.equalsIgnoreCase('ContentDocumentLink') && addContentDocument? 'LinkedEntityId' : 'Id';
	        
	        for(SObject s : scope){
	            // Ignore any Attachment related to the GRAX SObjects
	            // Filter the ContentDocumentLink by the selected parent list (if selected)
	            Boolean addElement = Test.isRunningTest();
	            addElement |= (sobjectName.equalsIgnoreCase('Attachment') ? 
	            	(s.getSObject('Parent') == null || s.getSObject('Parent').get('Type') == null || !String.valueOf(s.getSObject('Parent').get('Type')).startsWithIgnoreCase('GRAX')) 
	            	: 
	            	sobjectName.equalsIgnoreCase('ContentDocumentLink') ? 
	            		this.filesParentSelectionList.size() == 0 || (s.getSObject('LinkedEntity') == null || s.getSObject('LinkedEntity').get('Type') == null || this.filesParentSelectionList.contains(String.valueOf(s.getSObject('LinkedEntity').get('Type'))))
	            		:
	            		true);
	            
	            if(addElement){
	                scopeIds.add((Id)s.get(queryField));
	            }
	        }
	
			if(scopeIds.size() > 0){
		        List<String> fieldSelection = GRAXBatchToProcessSchedJob.getSObjectFields(sobjectName, false, false);
		        
		        // Get all the non-formula fields and build the query
		        String query = 'SELECT ' + String.join(fieldSelection, ', ');
		        
		        // If the current object is 'ContentDocumentLink', then add every field associated to the related Content Document, 
		        // as this is a special scenario of a junction object
		        if(sobjectName.equalsIgnoreCase('ContentDocumentLink') && addContentDocument){
		            query += ', ContentDocument.' + String.join(GRAXBatchToProcessSchedJob.getSObjectFields('ContentDocument', true, false), ', ContentDocument.');
		        }
		        
		        // The condition on the WHERE clause is added to avoid hitting the filter error on ContentDocumentLink object
		        // System.QueryException: Implementation restriction: ContentDocumentLink requires a filter by a single Id on ContentDocumentId or LinkedEntityId using the equals operator or multiple Id's using the IN operator.
		        query += ' FROM ' + sobjectName;
		        query += ' WHERE ' + queryField + ' IN :scopeIds';
		        
		        // Add a keyword to the SOQL query, in order to retrieve archived records
		        if(archivedObjects2QueryAllRows.contains(sObjStruc.name)){
		            query += ' ALL ROWS';
		        }
		        
		        System.debug('The object Query with Non-Calculated Fields is: ' + query);
		        
		        Map<Id, String> recsJSONById = new Map<Id, String>();
		        
		        // Perform the main query trying to optimize the heap size usage
		        // Iterate through each "queryMore" and get the JSON string representation for each of these records
		        for(List<SObject> recs : Database.query(query)){
		            for(SObject rec : recs){
		                recsJSONById.put(rec.Id, JSON.serialize(rec, true));
		            }
		        }
		
		        // Now, get the formula fields on this Object
		        List<String> objCalculatedFields = GRAXBatchToProcessSchedJob.getSObjectFields(sobjectName, false, true);
		        
		        if(objCalculatedFields.size() > 0){
		            
		            // If there are formula fields on this object, split the list into several queries to avoid the limit 'QUERY_TOO_COMPLICATED'
		            for(List<Object> calculatedFields : GRAXUtils.splitList(objCalculatedFields, 20)){                
		                // The condition on the WHERE clause is added to avoid hitting the filter error on ContentDocumentLink object
		                query = 'SELECT ' + String.join(calculatedFields, ', ');
		                query += ' FROM ' + sobjectName;
		                query += ' WHERE ' + queryField + ' IN :scopeIds';
		                
		                // Add a keyword to the SOQL query, in order to retrieve archived records
		                if(archivedObjects2QueryAllRows.contains(sObjStruc.name)){
		                    query += ' ALL ROWS';
		                }
		                
		                System.debug('The object Query with Calculated Fields is: ' + query);
		                
		                // Run the query for these Calculated fields optimizing the heap size usage
		                for(List<SObject> recs : Database.query(query)){
		                    for(SObject rec : recs){
		                        // Get the matching record for the generated JSON in its Object version, in order to add the missing formula field values
		                        Map<String, Object> m = (Map<String, Object>)JSON.deserializeUntyped(recsJSONById.get(rec.Id));
		                        
		                        // Get the current record's (including Calculated field) JSON representation, without including null field values
		                        String recWithCalcFldsJSON = JSON.serialize(rec, true);
		                        
		                        // Convert the JSON string to its Object representation
		                        Map<String, Object> recWithCalcFldsMap = (Map<String, Object>)JSON.deserializeUntyped(recWithCalcFldsJSON);
		                        
		                        // Use the Map's "putAll" method to merge all the fields retrieved into a single Map
		                        m.putAll(recWithCalcFldsMap);
		                        
		                        // Serialize the record again and store it in the Map
		                        recsJSONById.put(rec.Id, JSON.serialize(m, true));
		                    }
		                }
		            }
		        }
		        
		        if(isCustomObject2Process(sObjStruc, false)){
		            Map<Id, String> customObjects2ProcessJSONById = new Map<Id, String>();
		            String sObjName;
		            String sObjRelStrucName;
		            String sObjRelStrucParentUniqueKey;
		            String sObjRelStrucUniqueKey;
		            String sObjRelStrucRelatedFieldName;
		            
		            // Check if the current object is 'ContentDocumentLink'
		            if(sobjectName.equalsIgnoreCase('ContentDocumentLink') && addContentDocument){
		                // Iterate through each JSON string representing a record
		                // Get and remove the relationship to 'ContentDocument' from each JSON string
		                for(Id recId : recsJSONById.keySet()){
		                    
		                    // Get the record for the generated JSON in its Object version
		                    Map<String, Object> m = (Map<String, Object>)JSON.deserializeUntyped(recsJSONById.get(recId));
		                    Map<String, Object> contentDocObj = (Map<String, Object>)m.remove('ContentDocument');
		                    
		                    customObjects2ProcessJSONById.put(String.valueOf(contentDocObj.get('Id')), JSON.serialize(contentDocObj, true));
		                    
		                    // Serialize the record again and store it in the Map
		                    recsJSONById.put(recId, JSON.serialize(m, true));
		                }
		                
		                sObjName = 'ContentDocument';
		                sObjRelStrucName = 'ContentVersion';
		                sObjRelStrucParentUniqueKey = 'ContentDocument';
		                sObjRelStrucUniqueKey = 'ContentVersion';
		                sObjRelStrucRelatedFieldName = 'ContentDocumentId';
		            }else if((sobjectName.equalsIgnoreCase('FeedAttachment') || sobjectName.equalsIgnoreCase('FeedComment')) && addContentDocument){
		                // If the current object is a 'FeedAttachment', make sure to add the parent ContentDocument records
		                // in order to be able to query all the Content Version records for these FeedAttachments
		                
		                String contentDocumentFieldName = 'RecordId';
		                String contentDocumentRelationship = 'FeedAttachment';
		                
		                if(sobjectName.equalsIgnoreCase('FeedComment')){
		                    contentDocumentFieldName = 'RelatedRecordId';
		                    contentDocumentRelationship = 'FeedComment';
		                }                               
		                
		                // Iterate through each JSON string representing a record
		                // Get the 'RecordId' from each JSON string and generate a new 'ContentVersion' record
		                for(Id recId : recsJSONById.keySet()){
		                    
		                    // Get the record for the generated JSON in its Object version
		                    Map<String, Object> feedAttObj = (Map<String, Object>)JSON.deserializeUntyped(recsJSONById.get(recId));
		                    
		                    if(feedAttObj.get(contentDocumentFieldName) <> null && ((Id)feedAttObj.get(contentDocumentFieldName)).getSObjectType() == ContentVersion.sObjectType){
		                        customObjects2ProcessJSONById.put(String.valueOf(feedAttObj.get(contentDocumentFieldName)), '{"Id":"' + feedAttObj.get(contentDocumentFieldName) + '", "attributes":{"url":"/services/data/v44.0/sobjects/ContentVersion/'+feedAttObj.get(contentDocumentFieldName)+'","type":"ContentVersion"}}');
		                    }
		                }
		                
		                sObjName = 'ContentVersion';
		                sObjRelStrucName = 'ContentVersion';
		                sObjRelStrucParentUniqueKey = 'ContentVersion' + '_' + contentDocumentRelationship;
		                sObjRelStrucUniqueKey = 'ContentVersion_Feed' + '_' + contentDocumentRelationship;
		                sObjRelStrucRelatedFieldName = 'Id';
		            }else if(sobjectName.endsWithIgnoreCase('__kav') && sObjStruc.relatedFieldName == null){
		                // If the current object is a 'KnowledgeArticleVersion', make sure to add the parent KnowledgeArticle records
		                // in order to be able to query all the archived versions for these KnowledgeArticles
		                
		                // Iterate through each JSON string representing a record
		                // Get the 'KnowledgeArticleId' from each JSON string and generate a new 'KnowledgeArticle' record
		                for(Id recId : recsJSONById.keySet()){
		                    
		                    // Get the record for the generated JSON in its Object version
		                    Map<String, Object> kAVObj = (Map<String, Object>)JSON.deserializeUntyped(recsJSONById.get(recId));
		                    
		                    customObjects2ProcessJSONById.put(String.valueOf(kAVObj.get('KnowledgeArticleId')), '{"Id":"' + kAVObj.get('KnowledgeArticleId') + '", "attributes":{"url":"/services/data/v44.0/sobjects/'+sobjectName.removeEnd('v')+'/'+kAVObj.get('KnowledgeArticleId')+'","type":"'+sobjectName.removeEnd('v')+'"}}');
		                }
		                
		                sObjName = sobjectName;
		                sObjRelStrucName = sobjectName;
		                sObjRelStrucParentUniqueKey = 'KnowledgeArticle_' + sobjectName;
		                sObjRelStrucUniqueKey = sobjectName + '_Archived';
		                sObjRelStrucRelatedFieldName = 'KnowledgeArticleId';
		            }
		            
		            if(customObjects2ProcessJSONById.size() > 0){
			            // Call the generate GRAX Data Record method for this middle object
			            generateGRAXDataRecord(sObjName, sObjRelStrucParentUniqueKey, customObjects2ProcessJSONById, true);
		            }
		            
		            // If it wasn't added on a previous iteration, add the custom object to the end of the objects to process list to be evaluated last
		            if(!this.customObjects2ProcessAdded.contains(sObjRelStrucParentUniqueKey)){
		                this.customObjects2ProcessAdded.add(sObjRelStrucParentUniqueKey);
		                
		                String clonedStructure = JSON.serialize(sObjStruc);
		                GRAXBackupCtrl.ObjRelStructure sObjRelStruc = (GRAXBackupCtrl.ObjRelStructure)JSON.deserialize(clonedStructure, GRAXBackupCtrl.ObjRelStructure.class);
		                sObjRelStruc.name = sObjRelStrucName;
		                sObjRelStruc.parentUniqueKey = sObjRelStrucParentUniqueKey;
		                sObjRelStruc.uniqueKey = sObjRelStrucUniqueKey;
		                sObjRelStruc.relatedFieldName = sObjRelStrucRelatedFieldName;
		                
		                this.objects2Process.add(sObjRelStruc);
		            }
		        }
		        
		        // Call the generate GRAX Data Record method for this object
		        generateGRAXDataRecord(sobjectName, this.currentObjRelStrucUniqueKey, recsJSONById, sObjStruc.tmpRecord == null? true : !sObjStruc.tmpRecord);
			}
		}catch(Exception e){
			GRAXLogs.addLogException(e, 'APEX Class: GRAXBatchToProcessSchedJob, Method: execute, Current Object being processed information: ' + JSON.serialize(sObjStruc));
			
			// Commented out the following line as we don't want the message to be displayed in the Setup -> APEX Jobs
            //throw new GRAXException(e.getMessage(), 0);
		}
    }
    
    private void generateGRAXDataRecord(String sobjectName, String objRelStrucUniqueKey, Map<Id, String> recsJSONById, Boolean send2GRAX){
    	// Generate the list of Ids with line breaks every 10 Ids
    	String sfdcIds = '';
    	Integer recIdsPerLine = 0;
    	for(Id recId : recsJSONById.keySet()){
    		sfdcIds += recId + ';';
    		recIdsPerLine++;
    		if(recIdsPerLine == 8){
    			sfdcIds += '\n';
    			recIdsPerLine = 0;	
    		}
    	}
    	
    	GRAX_Data_Record__c dr = new GRAX_Data_Record__c();
        dr.Salesforce_ID__c = sfdcIds; //String.join(new List<Id>(recsJSONById.keySet()), ';'); // list of Ids being processed 
        dr.Salesforce_Object__c = sobjectName;
        dr.Status__c = 'Processing';
        dr.of_Times_Sent__c = 0;
        dr.Error_Message__c = null;
        dr.GRAX_Schedule_Process__c = this.currentJobId;
        dr.Sched_Proc_Hierarchy_Unique_Key__c = objRelStrucUniqueKey;
        dr.GRAX_Archive_Process__c = this.currentArchiveProcessId;
        dr.Execution_Unique_Key__c = this.executionUniqueKey;
        dr.Process_Object_Index__c = this.currentElementIndex;
        insert dr;
        
        // Store the Id of this GRAX Data Record to save the overall time for this SF Object
        lastGRAXDataRecordIdForCurrentSFObject = dr.Id;

        String dataRecIdStatus;
        if(this.isArchive){
            dataRecIdStatus = 'To be Deleted';
        }
        
        // Iterate through the list of records to create a GRAX_Data_Record_Id__c instance for each one of them
        Map<Id, GRAX_Data_Record_Id__c> dataRecIds2InsBySObjId = new Map<Id, GRAX_Data_Record_Id__c>();
        for(Id recId : recsJSONById.keySet()){
            GRAX_Data_Record_Id__c dataRecId = new GRAX_Data_Record_Id__c();
            dataRecId.SFDC_Id__c = recId;
            dataRecId.GRAX_Data_Record__c = dr.Id;
            dataRecId.Status__c = dataRecIdStatus;
            dataRecId.Processed_Child_Index__c = 0;
            dataRecId.Execution_Unique_Key__c = this.executionUniqueKey;
            
            dataRecIds2InsBySObjId.put(recId, dataRecId);
        }
        
        insert dataRecIds2InsBySObjId.values();
        
        Boolean isAttachmentOrFile = this.isArchive && asyncObjects2ProcessByGRAX.contains(sobjectName);
        for(Id recId : recsJSONById.keySet()){
            // Get the record for the generated JSON in its Object version
            Map<String, Object> m = (Map<String, Object>)JSON.deserializeUntyped(recsJSONById.get(recId));

            m.put('GRAX_Execution_Unique_Key', this.executionUniqueKey);
        
            // If the current object is "Attachment" or "Salesforce File", then add the GRAX_Data_Record_Id__c Id to the JSON
            if(isAttachmentOrFile){
                m.put('GRAX_Data_Record_Id', dataRecIds2InsBySObjId.get(recId).Id);
                m.put('GRAX_Status', 'Ready to Process');
            }
            
            // Serialize the record again and store it in the Map
            recsJSONById.put(recId, JSON.serialize(m, true));
        }
        
        // Generate the JSON Content for these records
        String jsonContent = GRAXApi.jsonContentArchive(sobjectName, recsJSONById);
        
        // Save the Attachment with the JSON content associated to the GRAX_Data_Record__c
        Attachment req_att = new Attachment();
        req_att.Name = 'request.txt';
        req_att.Body = Blob.valueOf(jsonContent);
        req_att.ParentId = dr.Id;
        insert req_att;
		
		// avoid processing this element in GRAX as it is only used to get the ParentIds of a child object
        dr.Status__c = send2GRAX ? 'Not Sent' : 'Sent Successful';
        update dr;
    }
    
    public void finishMethod(Database.BatchableContext BC){
        // Save the current value of the currentElementIndex
        Integer currentSFObjectIndex = this.currentElementIndex;
        
        if(GRAXUtils.checkIfScheduleIsAborted(this.currentJobId)) {
            try {
                System.abortJob(BC.getJobId());
            } catch (Exception e) {}

            return;
        }
        
        try{
	        // Check if this is a Child object being evaluated
	        if(this.currentElementIndex > 0 && !this.isMultiObjectRunning && this.parentIds2ProcessForChild.size() < maxParentIds2ProcessByChildIteration){
	            List<GRAX_Data_Record_Id__c> graxDataRecs2Up = new List<GRAX_Data_Record_Id__c>();
	            
	            // Flag all the parent Ids that have been processed during this execution
	            for(Id graxDataRecId : this.graxDataRecIds2ProcessForChild){
	                GRAX_Data_Record_Id__c grxDRId2Up = new GRAX_Data_Record_Id__c(Id = graxDataRecId);
	                grxDRId2Up.Processed_Child_Index__c = this.currentElementIndex;
	                grxDRId2Up.Execution_Unique_Key__c = this.executionUniqueKey;
	                graxDataRecs2Up.add(grxDRId2Up);
	            }
	            
	            if(graxDataRecs2Up.size() > 0){
	                update graxDataRecs2Up;
	            }
	        }
	        
	        // If the Schedule is for Multi-Object we need to move on to the next Object
	        if(this.isMultiObjectRunning || this.currentElementIndex == 0){
	            this.currentElementIndex = this.currentElementIndex + 1;
	        }
	        
	        // Before evaluating the next object, set a new Last Start Date for this current object
			if(this.isProgressive && this.currentSFObjectProgressiveStartTime <> null && currentSFObjectIndex <> this.currentElementIndex){
				progressiveStartDatetimeByObject.put(this.objects2Process[currentSFObjectIndex].name, this.currentSFObjectProgressiveStartTime.getTime());
				currentSFObjectProgressiveStartTimeStatic = null;
			}
	        
	        Boolean isBatchCompleted = this.currentElementIndex >= this.objects2Process.size();
	        GRAXBatchToProcessSchedJob b;
	        
	        if(!isBatchCompleted){
	            // Set the Static variable values to be used in the Constructor
	            isProgressiveStatic = this.isProgressive;
	            executionUniqueKeyStatic = this.executionUniqueKey;
	            lastStartTimeStatic = this.lastStartTime;
	            lastRunDateStatic = this.lastRunDate;
	            isFilesBackupStatic = this.isFilesBackup;
	            progressiveStartDatetimeByObjectStatic = this.progressiveStartDatetimeByObject;
	            
	            // Now we have to call the batch again based on the current parameters
	            b = new GRAXBatchToProcessSchedJob(this.currentJobId, this.objects2Process, this.currentElementIndex, this.currentSelectCriteria, this.isExecuteNow, this.isMultiObjectRunning);
	            
	            Boolean skip2NextObjectCondition = true;    
	                
	            // Check if there are parentIds identified to process for the following Child object
	            // Only iterate up to 100 times for Hierarchy Backup, and 50 times for multi-object
	            Integer maxNumberOfIterations = 50;
	            if(this.isMultiObjectRunning){
	                maxNumberOfIterations = 50;
	            }
	            
	            for(Integer i = 0; skip2NextObjectCondition; i++){
	                skip2NextObjectCondition = !isBatchCompleted && (i < maxNumberOfIterations || !GRAXUtils.sObjectExists(this.objects2Process[this.currentElementIndex].name));
	                skip2NextObjectCondition &= b.parentIds2ProcessForChild.size() == 0 || (b.parentIds2ProcessForChild.size() < maxParentIds2ProcessByChildIteration && !b.hasMoreRecords2Process); // Verify that there is at least one more parent record Id that still hasn't been processed
	                if(this.isMultiObjectRunning && skip2NextObjectCondition){                    
	                    skip2NextObjectCondition = !GRAXUtils.sObjectExists(this.objects2Process[this.currentElementIndex].name);
	                    skip2NextObjectCondition |= !b.hasMoreRecords2Process;
	                }
	                
	                if(skip2NextObjectCondition){
	                    // Before evaluating the next object, set a new Last Start Date for this current object
	            		if(this.isProgressive && b.currentSFObjectProgressiveStartTime <> null){
	            			progressiveStartDatetimeByObject.put(this.objects2Process[this.currentElementIndex].name, b.currentSFObjectProgressiveStartTime.getTime());
	            			currentSFObjectProgressiveStartTimeStatic = null;
	            		}
	                    
	                    
	                    // Increase the object index and continue with the next child object in the hierarchy list, when:
	                    // - The root object has completed processing
	                    // - There are no more parent record Ids to process
	                    // - The Schedule is for Multi-Object and there are no records on the current index
	                    this.currentElementIndex = this.currentElementIndex + 1;
	                    
	                    isBatchCompleted = this.currentElementIndex >= this.objects2Process.size();
	                    
	                    if(!isBatchCompleted){
	                        // Create a new instance of the batch for this Child object
	                        b = new GRAXBatchToProcessSchedJob(this.currentJobId, this.objects2Process, this.currentElementIndex, this.currentSelectCriteria, this.isExecuteNow, this.isMultiObjectRunning);
	                    }
	                }
	            }
	        }
	        
	        // Verify if the current object has changed or the batch process has completed
	        overallSFObjectProcessStartTimeStatic = this.overallSFObjectProcessStartTime;
	        if(currentSFObjectIndex <> this.currentElementIndex || isBatchCompleted){
	        	overallSFObjectProcessStartTimeStatic = null;
	        	
	        	if(this.lastGRAXDataRecordIdForCurrentSFObject <> null){
		        	// Store the overall time elapsed that took processing of this SFObject
		        	GRAX_Data_Record__c dr = new GRAX_Data_Record__c(Id = this.lastGRAXDataRecordIdForCurrentSFObject, Overall_SFObject_Process_Start_Time__c = this.overallSFObjectProcessStartTime, Overall_SFObject_Process_End_Time__c = System.now());
		        	update dr;
		        	
		        	this.lastGRAXDataRecordIdForCurrentSFObject = null;
	        	}
	        	
	        	if(this.isProgressive){
	        		// Store all Progressive Start Times in an Attachment
		        	Attachment progressiveDatesJSONAtt = GRAXUtils.getSelectionAttachment(this.currentJobId, 'ProgressiveDatesJSON.txt');
		        	if(progressiveDatesJSONAtt <> null){
		        		GRAXUtils.setSelectionJSON(progressiveDatesJSONAtt, JSON.serialize(progressiveStartDatetimeByObject));
		        	}else{
		        		GRAXUtils.setSelectionJSON(this.currentJobId, JSON.serialize(progressiveStartDatetimeByObject), 'ProgressiveDatesJSON.txt');
		        	}
	        	}
	        }
	        
	        if(!isBatchCompleted && !Test.isRunningTest()){
	            b.executionUniqueKey = this.executionUniqueKey;
	            b.lastStartTime = this.lastStartTime;
	            b.isProgressive = this.isProgressive;
	            b.isArchive = this.isArchive;
	            b.currentArchiveProcessId = this.currentArchiveProcessId;
	            b.isExecuteNow = this.isExecuteNow;
	            b.customObjects2ProcessAdded = this.customObjects2ProcessAdded;
	            b.currentElementIndex = this.currentElementIndex;
	            b.lastGRAXDataRecordIdForCurrentSFObject = this.lastGRAXDataRecordIdForCurrentSFObject;
	            b.progressiveStartDatetimeByObject = this.progressiveStartDatetimeByObject;
	            
	            String nextJobId;
	            
	            // Temporary solution to deactivate the GRAXBatchToGetSchedJobParentRecords functionality when the field MaxNumberOfParentsOnHierarchyBackup__c is blank
	            Boolean useUpdatedParentIdFunctionality = GRAXUtils.getGRAXSettings() == null || GRAXUtils.getGRAXSettings().MaxNumberOfParentsOnHierarchyBackup__c == null;
	            
	            if(useUpdatedParentIdFunctionality && !this.isMultiObjectRunning && b.parentIds2ProcessForChild.size() >= maxParentIds2ProcessByChildIteration){
	            	// If this is a Hierachy process and there are more than maxParentIds2ProcessByChildIteration identified Parent Ids, then get all these Parent Ids in a new Batch execution
	            	nextJobId = Database.executeBatch(new GRAXBatchToGetSchedJobParentRecords(b), 2000);

					GRAX_Schedule_Process__c schedProcess = new GRAX_Schedule_Process__c(Id = b.currentJobId, JobId__c = nextJobId);
					update schedProcess;
				}else{
		            nextJobId = executeNextBatchRun(b);
	            }
	            
	            if(GRAXSchedulerToProcessSchedJobs.isEmptyId(nextJobId)) {
        			// Add a GRAX Log in case the batch job cannot get into the Queue
        			throw new GRAXException('This SF environment has reached its maximum number of concurrent records in the APEX Flex Queue. Please try scheduling again. GRAX Schedule Process Id: \'' + this.currentJobId + '\'', 0);
    			}
	        }else{
	            // Update the Last Run Date and Next Run Date on the current Schedule Process record
	            GRAX_Schedule_Process__c schedProcess = [SELECT Id, Schedule_Type__c, Next_Run_Date__c, Rolling_Date__c, Target_Start_Datetime__c, Target_End_Datetime__c, Frequency_Type__c, Frequency_Value__c, (Select Id From GRAX_Data_Records__r WHERE Execution_Unique_Key__c =: this.executionUniqueKey Limit 1) FROM GRAX_Schedule_Process__c WHERE Id =: this.currentJobId];
	            if(schedProcess.Schedule_Type__c == 'Once') {// || schedProcess.Schedule_Start_Date__c < Date.today()) {
	                schedProcess.Next_Run_Date__c = null;
	            } else {
	                // This GRAX Schedule Process is running based on a frequency
	                // Update the next date when this process has to be executed
	                schedProcess.Next_Run_Date__c = getNextRunDate(schedProcess.Next_Run_Date__c, schedProcess.Schedule_Type__c, schedProcess.Frequency_Type__c, schedProcess.Frequency_Value__c <> null ? schedProcess.Frequency_Value__c.intValue() : 0);
	                
	                if(schedProcess.Rolling_Date__c) {
			            schedProcess.Target_Start_Datetime__c = schedProcess.Target_Start_Datetime__c <> null ? addFrequency(schedProcess.Target_Start_Datetime__c, schedProcess.Schedule_Type__c, schedProcess.Frequency_Type__c, schedProcess.Frequency_Value__c <> null ? schedProcess.Frequency_Value__c.intValue() : 0) : null;
			            schedProcess.Target_End_Datetime__c = schedProcess.Target_End_Datetime__c <> null ? addFrequency(schedProcess.Target_End_Datetime__c, schedProcess.Schedule_Type__c, schedProcess.Frequency_Type__c, schedProcess.Frequency_Value__c <> null ? schedProcess.Frequency_Value__c.intValue() : 0) : null;
			        }
	            }
	            schedProcess.Last_Run_Date__c = System.now();
	            schedProcess.Status__c = schedProcess.GRAX_Data_Records__r.size() > 0 ? 'Pending send data to GRAX' : 'Completed';
	            schedProcess.Total_Objects_To_Process__c = null;
	            schedProcess.Total_Objects_Processed__c = null;
	            schedProcess.JobId__c = null;
	            schedProcess.currentElementIndex__c = null;
	            update schedProcess;
				
				// Check that there is at least one GRAX Data Record generated on this job
	            if(this.isExecuteNow && schedProcess.GRAX_Data_Records__r.size() > 0) {
	                // Execute the GRAXSchedulerToResendDataRecords in order to send the GRAX Data Records just generated
	                GRAXSchedulerToResendDataRecords.executeGRAXBatchToResendDataRecords();
	            }
	        }
        }catch(Exception e){
			GRAXLogs.addLogException(e, 'APEX Class: GRAXBatchToProcessSchedJob, Method: finish, Current processes information: ' + JSON.serialize(this));
			
			// Commented out the following line as we don't want the message to be displayed in the Setup -> APEX Jobs
            //throw new GRAXException(e.getMessage(), 0);
		}
    }
    
    public String executeNextBatchRun(GRAXBatchToProcessSchedJob b){
    	GRAX_Schedule_Process__c schedProcess = new GRAX_Schedule_Process__c(Id = b.currentJobId);
        schedProcess.Total_Objects_Processed__c = b.currentElementIndex + 1;
        schedProcess.currentElementIndex__c = b.currentElementIndex;
	            
    	// Get the current object structure
        GRAXBackupCtrl.ObjRelStructure sObjStruc = b.objects2Process[b.currentElementIndex];
        
        Integer maxExecutionNumber = GRAXUtils.getBatchMaxExecutionNumber(sObjStruc.name);

        if(isCustomObject2Process(sObjStruc, true)){
            schedProcess.JobId__c = Database.executeBatch(b, maxExecutionNumber);               
        } else {
            GRAXBatchToProcessSchedJobMainObject bMainObj = new GRAXBatchToProcessSchedJobMainObject(b);
            bMainObj.parentIds2ProcessForChild = b.parentIds2ProcessForChild;
            
            schedProcess.JobId__c = Database.executeBatch(bMainObj, maxExecutionNumber);
        }

        update schedProcess;
        
        return schedProcess.JobId__c;
    }
    
    public static List<String> getSObjectFields(String objName, Boolean retrieveAllFields, Boolean retrieveCalculatedFields){
        List<String> selectFields = new List<String>();

        // Loop through all field describe
        for(Schema.DescribeFieldResult fd : GRAXUtils.getDescribeFieldsResultForObject(objName).values()){
            if(!fd.getType().name().equalsIgnoreCase('base64') && (retrieveAllFields || retrieveCalculatedFields == fd.isCalculated())){
                if(!objectFieldsMapToExclude.containsKey(objName) || !objectFieldsMapToExclude.get(objName).contains(fd.getName())) {
                    selectFields.add(fd.getName());
                }
            }
        }
        
        return selectFields;
    }
    
    private String getFieldType(String objName, String fieldName){
        String result = 'Date';
        
        // Get a map of field name and field describe info
        Map<String, Schema.DescribeFieldResult> fldDescMap = GRAXUtils.getDescribeFieldsResultForObject(objName);
        
        if(fldDescMap <> null && fldDescMap.containsKey(fieldName)){
            result = fldDescMap.get(fieldName).getType().name();
        }
        
        return result;
    }
    
    private Datetime getNextRunDate(Datetime previousRunDate, String frequency, String customFrequencyType, Integer customFrequencyValue){
        Datetime result = previousRunDate;
        Datetime currentDatetime = System.now();
        
        while(result < currentDatetime){
            // Calculate the Next Run Date based on the selected frequency 
            // Iterate through the method until the Next Run Date is in the future
            result = addFrequency(result, frequency, customFrequencyType, customFrequencyValue);
        }
        
        return result;
    }

    private Datetime addFrequency(Datetime previousDate, String frequency, String customFrequencyType, Integer customFrequencyValue) {
        Datetime result = previousDate;
		
		if(customFrequencyType == 'Hours'){
			result = result.addHours(customFrequencyValue);
		}else if(frequency == 'Daily' || frequency == 'Weekly' || customFrequencyType == 'Days' || customFrequencyType == 'Weeks'){
            Integer freqVal = frequency == 'Daily' ? 1 : (frequency == 'Weekly' ? 7 : customFrequencyValue * (customFrequencyType == 'Weeks' ? 7 : 1));
            
            result = result.addDays(freqVal);
        }else if(frequency == 'Monthly' || frequency == 'Quarterly' || frequency == 'Semi-Annually' || frequency == 'Annually' || customFrequencyType == 'Months' || customFrequencyType == 'Years'){
            Integer freqVal = frequency == 'Monthly' ? 1 : (frequency == 'Quarterly' ? 3 : (frequency == 'Semi-Annually' ? 6 : (frequency == 'Annually' ? 12 : customFrequencyValue * (customFrequencyType == 'Years' ? 12 : 1))));
            
            result = isLastDayOfMonth(result.dateGmt()) ? Datetime.newInstanceGmt(result.addMonths(freqVal + 1).dateGmt().toStartOfMonth().addDays(-1), result.timeGmt()) : result.addMonths(freqVal);
        }

        return result;
    }
    
    private Boolean isLastDayOfMonth(Date currentDate) {
    	return currentDate == currentDate.addMonths(1).toStartOfMonth().addDays(-1);
    }
    
    private Boolean isCustomObject2Process(GRAXBackupCtrl.ObjRelStructure sObjStruc, Boolean checkHierarchyRelationship){
        Boolean result = sObjStruc.name.equalsIgnoreCase('ContentDocumentLink') && addContentDocument;
        result |= sObjStruc.name.equalsIgnoreCase('FeedAttachment') && addContentDocument;
        result |= sObjStruc.name.equalsIgnoreCase('FeedComment') && addContentDocument;
        result |= sObjStruc.name.endsWithIgnoreCase('__kav') && ((checkHierarchyRelationship && sObjStruc.relatedFieldName <> null) || (!checkHierarchyRelationship && sObjStruc.relatedFieldName == null));
        
        return result;
    }
}