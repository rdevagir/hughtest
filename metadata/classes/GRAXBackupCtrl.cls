/*****************************************************************************************
Name              : GRAXBackupCtrl
Description       : Implementation of the tab "Back Up" in GRAXSetupUI.
Revision History  :
Created/Modified by   Created/Modified Date     Requested by        Related Task/Issue     
----------------------------------------------------------------------------------------
1. Leandro Brunner         04/27/2018             David Mackey        GRAX Audit Trail Process (https://app.asana.com/0/326600806074978/633149554508926/f)
2. Ariel Yankelevich       07/18/2018             David Mackey        Multi-Object Backup (https://app.asana.com/0/326600806074978/743044564916005/f)
3. Leandro Brunner         08/02/2018             David Mackey        Too many fields/too much to query errors (https://app.asana.com/0/326600806074978/763054542504017/f)
4. Leandro Brunner         08/14/2018             David Mackey        Agco Fixes (https://app.asana.com/0/326600806074978/770976244463043/f)
5. Leandro Brunner         09/24/2018             David Mackey        Assign a Backup/Scheduled Process Name & Minor UI Changes (https://app.asana.com/0/326600806074978/835222380833095/f)
6. Leandro Brunner         10/08/2018             David Mackey        Hierarchy Backup Updates (https://app.asana.com/0/326600806074978/853752416552300/f)
7. Ariel Yankelevich       10/11/2018             David Mackey        Minor Updates (https://app.asana.com/0/326600806074978/857103514581849/f)
8. Leandro Brunner         11/06/2018             David Mackey        Minor UI Enhancements (https://app.asana.com/0/326600806074978/880565726418326/f)
9. Leandro Brunner         12/26/2018             David Mackey        Backup/Archive UI Updates (https://app.asana.com/0/326600806074978/950283827722121/f)
10. Ariel Yankelevich      01/03/2019             David Mackey        Chatter Backup (https://app.asana.com/0/326600806074978/958019584834204/f)
11. Leandro Brunner        01/07/2019             David Mackey        Chatter Backup (https://app.asana.com/0/326600806074978/958019584834204/f)
12. Ariel Yankelevich      01/25/2019             David Mackey        ContentDocument (objects) Restore (https://app.asana.com/0/326600806074978/985052780814601/f)
13. Leandro Brunner        02/18/2019             David Mackey        Rolling Date on Scheduled Process (https://app.asana.com/0/326600806074978/1108496218666250/f)
14. Leandro Brunner        02/26/2019             David Mackey        Update Backup Process (https://app.asana.com/0/326600806074978/1109887667389108/f)
15. Ariel Yankelevich      03/14/2019             David Mackey        Oak North Issues (https://app.asana.com/0/326600806074978/1114340491893894/f)
16. Nicolas Ralero         04/29/2019             David Mackey        Can we back up SetupAuditTrail Object (https://app.asana.com/0/326600806074978/1120147888058592/f)
17. Leandro Brunner        05/08/2019             David Mackey        "Override Child Objects for Archive" Permission (https://app.asana.com/0/326600806074978/1120957110975898/f)
18. Leandro Brunner        05/13/2019             David Mackey        Deactivate/Activate Scheduled Process (https://app.asana.com/0/326600806074978/1122644080179927/f)
19. Nicolas Ralero         05/15/2019             David Mackey        Updating Object Progress % (https://app.asana.com/0/326600806074978/1122723602378290/f)
20. Ariel Yankelevich      05/20/2019             David Mackey        Create Scheduled Jobs Upon Package Install (https://app.asana.com/0/1118660079719641/1105533057427274/f)
21. Nicolas Ralero         05/27/2019             David Mackey        Sortable Hierarchy Process/Object Backup Job Columns (https://app.asana.com/0/326600806074978/1124254801692781/f)
22. Leandro Brunner        05/31/2019             David Mackey        Date Format should be based on user locale (https://app.asana.com/0/326600806074978/1125157851523067/f)
******************************************************************************************/

global with sharing class GRAXBackupCtrl {
    public String userTimeZone {get;set;}
    public String selectedObject {get;set;}
    public String selectedObjectDefault {get;set;}
    public String sObjectDateField {get;set;}
    public String sObjectDateFieldDefault {get;set;}

    private static Set<String> excludedStandardObjects = new Set<String>{
        'AccountCleanInfo', 'ContentDistribution', 'ContentAsset','DuplicateRecordItem', 'EntitySubscription',
        'ProcessInstance', 'TopicAssignment', 'AccountPartner', 'ContactCleanInfo',
        'EmailMessageRelation', 'EventRelation', 'OpportunityPartner', 'Partner',
        'CollaborationGroupRecord', 'CaseTeamMember', 'CaseTeamTemplateRecord', 'FlowRecordRelation',
        'NetworkUserHistoryRecent', 'UserFieldAccess', 'UserEntityAccess','OutgoingEmail',
        'OutgoingEmailRelation', 'AgentWork', 'NetworkUserHistoryRecent', 'PendingServiceRouting',
        'ApexPageInfo', 'ContentUserSubscription', 'ContentTagSubscription', 'ContentFolderMember',
        'ContentFolderItem', 'AccountUserTerritory2View', 'IdeaComment',
        'NotificationMember', 'ChatterMessageThread', 'EntityDefinition', 'FieldDefinition', 
        'FieldPermissions', 'PlatformAction', 'SearchLayout', 'Vote',
        'AuraDefinitionInfo', 'AuraDefinitionBundle', 'AuraDefinitionBundleInfo',
        'AuraDefinition', 'AuthConfig', 'AuthConfigProviders', 'AuthProvider',
        'AuthSession', 'SetupEntityAccess', 'FieldHistoryArchive', 'FiscalYearSettings',
        'FlexQueueItem', 'FlowInterview', 'CronTrigger', 'ContentDocumentLink', 'RecordRecommendation', 'NetworkUserHistoryRecentToFeedItem', 'OauthToken',
        'ClientBrowser', 'CronJobDetail','CollaborationGroup','CollaborationGroupMember','CorsWhitelistEntry','Community','BusinessHours','NetworkSelfRegistration',
        'UserPermissionAccess','ObjectPermissions','ProcessInstanceWorkitem','WebLinkLocalization','VisualforceAccessMetrics','Site','SamlSsoConfig','ProcessDefinition',
        'PermissionSetLicense','PermissionSetAssignment','PackageLicense','OrgWideEmailAddress','Organization',
        'TopicUserEvent', 'NetworkModeration', 'LoginIp', 'FeedPollChoice', 'DocumentAttachmentMap', 'ClientBrowse', 'AsyncApexJob', 
        'ContentHubItem', 'GroupSubscription', 'ContentNotification', 'TenantUsageEntitlement', 'TwoFactorInfo', 'UserAppInfo', 
        'UserLicense', 'VisualforceAccessMetrics', 'LoginGeo', 'LoginEvent', 'BackgroundOperationResult'
    };
    private static Set<String> excludedStandardObjectSufixes = new Set<String>{'Share','History','Feed', '__x', '__Tag', 'Tag', '__VoteStat', '__ViewStat'};
    private static Set<String> excludedStandardObjectPrefixes = new Set<String>{'GRAX'};      

    // private static Set<String> forcedIncludedStandardObjects = new Set<String>{'User', 'PricebookEntry'};

    private static Map<String, Set<String>> includedObjectsByScheduledProcessType = new Map<String, Set<String>>{
        'Hierarchy' => new Set<String>{'ContentDocumentLink'},
        'Multi-Object' => new Set<String>{'RecordType', 'Attachment', 'ContentDocumentLink'}
    };

    private static Set<String> forcedStandardObjectsToIncludeRelationships = new Set<String>{'FeedItem'};
    
    private static Set<String> parentsSelectionObjects = new Set<String>{'Attachment', 'ContentVersion'};

    public String spName {get;set;}
    public String filterCriteriaType {get;set;}
    public String targetDate {get;set;}
    public String targetTime {get;set;}
    public String targetEndDate {get;set;}
    public String targetEndTime {get;set;}
    public String targetReport {get;set;}
    public String criteria {get;set;}
    public String schedule {get;set;}
    public String scheduleStartDate {get;set;}
    public String scheduleStartTime {get;set;}
    public String objectJSON {get;set;}
    public Boolean archive {get;set;}
    public Boolean overrideArchive {get;set;}
    public Boolean progressive {get;set;}
    public Boolean isReadOnly {get;set;}
    public Boolean isSendNotifications {get;set;}
    public Boolean isRollingDate {get;set;}
    public Boolean active {get;set;}
    public String parentsSelection {get;set;}
    public String usersSelection {get;set;}
    public String extraEmails {get;set;}
    public String frequencyType {get;set;}
    public String frequencyValue {get;set;}

    public Attachment selectionAttachment {get;set;}
    public Attachment parentsSelectionAttachment {get;set;}
    public Attachment usersSelectionAttachment {get;set;}
    public Attachment extraEmailsAttachment {get;set;}

    global class ScheduledProcess {
        public Id cronId {get;set;}
        public String name {get;set;}
        public String createdBy {get;set;}
        public String createdDate {get;set;}
        public String lastRunDate {get;set;}
        public String nextRunDate {get;set;}
        public String parentObject {get;set;}
        public String archive {get;set;}
        public String status {get;set;}
        public String progress {get;set;}
        public Decimal jobProgress {get;set;}
        public Boolean isReadOnly {get;set;}
        public Boolean isRunning {get;set;}
        public Boolean isActive {get;set;}
        public String dateFieldType {get;set;}
        public Boolean preventEdit {get;set;}
        public Integer objectsProcessed {get; set;}
        public String currentChildObjectName {get; set;}
        public Boolean requireAdditionalParentIdsToRetrieve {get; set;}

        public GRAX_Schedule_Process__c GRAXScheduleProcess {get;set;}
    }

    public GRAX_Schedule_Process__c gsp {get;set;}
    public Map<Id, ScheduledProcess> scheduledProcessMap {get;set;}
    public Map<Id, ScheduledProcess> multiObjectBackupMap {get;set;}

    public String scheduledProcessType {get;set;}

    transient String pageAlertMessage {get;set;}
    private List<ScheduledProcess> scheduledProcesses;
    public List<ScheduledProcess> multiObjectBackup {get; set;}
    public List<ScheduledProcess> currentPageHierarchyList {get; set;}
    public List<ScheduledProcess> currentPageMultiObjectList {get; set;}

    public String orderByMultiObject {get; set;}
    public String sortOrderMultiObject {get; set;}
    public String previousOrderByMultiObject {get; set;}
    public String orderByHierarchy {get; set;}
    public String sortOrderHierarchy {get; set;}
    public String previousOrderByHierarchy {get; set;}
    public Integer rowsPerPage {get; set;}
    public Integer currentPageHierarchy {get; set;}
    public Integer currentPageMultiObject {get; set;}
    public Integer totalRowsHierarchy {get; set;}
    public Integer totalRowsMultiObject {get; set;}

    public static GRAXPermissions gp {
        get {
            return new GRAXPermissions(UserInfo.getUserId());
        }
    }

    public GRAXBackupCtrl() {
        userTimeZone = UserInfo.getTimeZone().getID();
        selectedObject = '';
        targetReport = '';
        sObjectDateFieldDefault = 'LastModifiedDate';
        criteria = 'Main Object not modified';
        filterCriteriaType = 'Date';
        archive = false;
        overrideArchive = false;
        progressive = false;
        isReadOnly = false;
        isSendNotifications = false;
        isRollingDate = false;
        active = true;
        gsp = new GRAX_Schedule_Process__c();
        scheduledProcessMap = new Map<Id, ScheduledProcess>();
        multiObjectBackupMap = new Map<Id, ScheduledProcess>();
        scheduledProcesses = new List<ScheduledProcess>();
        multiObjectBackup = new List<ScheduledProcess>();
        currentPageHierarchyList = new List<ScheduledProcess>();
        currentPageMultiObjectList = new List<ScheduledProcess>();

        scheduledProcessType = '';

        orderByMultiObject = 'name';
        sortOrderMultiObject = 'asc';
        previousOrderByMultiObject = '';
        orderByHierarchy = 'name';
        sortOrderHierarchy = 'asc';
        previousOrderByHierarchy = '';
        rowsPerPage = 20;
        currentPageHierarchy = 0;
        currentPageMultiObject = 0;

        updateScheduledProcessMap();
    }

    public String getPageAlertMessage() {
        return this.pageAlertMessage;
    }

    public static List<SelectOption> getItems() {
        return getItems(null);
    }

    public static List<SelectOption> getItems(String scheduleType) {
        List<SelectOption> options = new List<SelectOption>();

        options.add(new SelectOption('' ,'-- SELECT SALESFORCE OBJECT --', true));

        String objectname;
        Boolean includeObject;
        for(Schema.SObjectType soType : Schema.getGlobalDescribe().values()) {
            Schema.DescribeSObjectResult soDesc = soType.getDescribe();

            includeObject = true;

            objectname = soDesc.getName();
            //includeObject = (soDesc.getRecordTypeInfosByName().size() > 0 || forcedIncludedStandardObjects.contains(objectname)) && !excludedStandardObjects.contains(objectname);
            includeObject = !excludedStandardObjects.contains(objectname);

            if(includeObject) {
                for(String sufix : excludedStandardObjectSufixes) {
                    if(objectname.endsWithIgnoreCase(sufix)) {
                        includeObject = false;
                        break;
                    }
                }
            }

            if(includeObject) {
                for(String prefix : excludedStandardObjectPrefixes) {
                    if(objectname.startsWithIgnoreCase(prefix)) {
                        includeObject = false;
                        break;
                    }
                }
            }

            if((objectname.startsWithIgnoreCase('Apex') || objectname.startsWithIgnoreCase('PartnerNetwork')) && !soDesc.isCustom()) {
                includeObject = false;
            }

            if(scheduleType <> null && includedObjectsByScheduledProcessType.containsKey(scheduleType)) {
                includeObject |= includedObjectsByScheduledProcessType.get(scheduleType).contains(objectname);
            }

            if(includeObject) {
                options.add(new SelectOption(objectname, objectname, !soDesc.isQueryable()));
            }
        }

        options.sort();
        
        return options;
    }

    public Pagereference changeSelectedObject() {
        selectedObject = Apexpages.currentPage().getParameters().get('selectedObjectValue');
        sObjectDateField = sObjectDateFieldDefault;

        return null;
    }
    
    // This structure is used to encapsulate the object relationship structure
    public class ObjRelStructure {
        public String uniqueKey {get; set;}
        public String name {get; set;}
        public String label {get; set;}
        public String parentUniqueKey {get; set;}
        public String relationshipName {get; set;}
        public String relatedFieldName {get; set;}
        public Boolean isCascadeDelete {get; set;}
        public Boolean tmpRecord {get; set;}
        public List<ObjRelStructure> childObjRelStructure {get; set;}
        
        public ObjRelStructure(Schema.DescribeSObjectResult objDesc, Schema.ChildRelationship childRel){
            this.name = objDesc.getName();
            this.label = objDesc.getLabel();
            this.tmpRecord = false;
            if(childRel <> null){
                this.relationshipName = childRel.getRelationshipName();
                this.isCascadeDelete = childRel.isCascadeDelete();
                this.relatedFieldName = String.valueOf(childRel.getField());
            }
            
            childObjRelStructure = new List<ObjRelStructure>();
        }

        public ObjRelStructure() {}
    }

    private static void addAllChildRelationships(ObjRelStructure sObjRelStruc, List<ObjRelStructure> allObjRelStructure, Set<String> childsToBeVisitedUniqueKey){
        addAllChildRelationships(sObjRelStruc, allObjRelStructure, childsToBeVisitedUniqueKey, false);
    }

    private static void addAllChildRelationships(ObjRelStructure sObjRelStruc, List<ObjRelStructure> allObjRelStructure, Set<String> childsToBeVisitedUniqueKey, Boolean onlyStandard){
        // Get the object description
        if(GRAXUtils.sObjectExists(sObjRelStruc.name)){
            Schema.DescribeSObjectResult sObjDesc = GRAXUtils.getObjectDescribe(sObjRelStruc.name);
            
            if(sObjDesc.getChildRelationships().size() > 0){
                //Visit all the Child Relationships of this SObject
                for(Schema.ChildRelationship childRel : sObjDesc.getChildRelationships()){
                    if(String.isNotBlank(childRel.getRelationshipName()) || forcedStandardObjectsToIncludeRelationships.contains(String.valueOf(childRel.getChildSObject()))){
                        String uniqueKey = (sObjRelStruc.name == 'FeedItem' && childRel.getChildSObject() == FeedComment.sObjectType ? sObjRelStruc.uniqueKey : sObjRelStruc.name) + '_' + (childRel.getRelationshipName() <> null ? childRel.getRelationshipName() : String.valueOf(childRel.getChildSObject()));
                        
                        Boolean conditionToAdd = !childsToBeVisitedUniqueKey.contains(uniqueKey); 
                        conditionToAdd &= !(sObjRelStruc.name == 'FeedComment' && childRel.getChildSObject() == FeedAttachment.sObjectType);
                        conditionToAdd &= !((sObjRelStruc.name.startsWithIgnoreCase('Feed') || sObjRelStruc.name.equalsIgnoreCase('WorkThanks')) && !sObjDesc.isCustom() && childRel.getChildSObject() == FeedItem.sObjectType);
                        
                        if(conditionToAdd){
                            childsToBeVisitedUniqueKey.add(uniqueKey);

                            Schema.DescribeSObjectResult childSObjDesc = childRel.getChildSObject().getDescribe();
                            String objName = childSObjDesc.getName();
                            
                            // Verify that this Child Object is accessible, queryeable, etc
                            if((!excludedStandardObjects.contains(objName) || includedObjectsByScheduledProcessType.get('Hierarchy').contains(objName)) && childSObjDesc.isAccessible() && childSObjDesc.isQueryable()){
                                // Check that this object name does not end with any of the excluded sufixes
                                Boolean endsWithExcludedStdSuffix = false;
                                for(String stdObjSuffix : excludedStandardObjectSufixes){
                                    if(objName.endsWith(stdObjSuffix)){
                                        endsWithExcludedStdSuffix = true;
                                        break;
                                    }
                                }

                                if(!endsWithExcludedStdSuffix && !(onlyStandard && childSObjDesc.isCustom())){
                                    ObjRelStructure childSObjRelStruc = new ObjRelStructure(childSObjDesc, childRel);
                                    childSObjRelStruc.uniqueKey = uniqueKey;
                                    childSObjRelStruc.parentUniqueKey = sObjRelStruc.uniqueKey;

                                    // Add this Child SObject to the current SObject related Childs
                                    sObjRelStruc.childObjRelStructure.add(childSObjRelStruc);

                                    // Also add it to the Flat structure in order to process it in a future iteration
                                    allObjRelStructure.add(childSObjRelStruc);
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    public String getRelStructure() {
        if(String.isNotBlank(selectedObject)) {
            // Flat structure of nodes to be visited
            List<ObjRelStructure> allObjRelStructure = new List<ObjRelStructure>();
            Set<String> childsToBeVisitedUniqueKey = new Set<String>();

            Schema.DescribeSObjectResult rootSObjDesc = GRAXUtils.getObjectDescribe(selectedObject);

            // Initiate the structure on the current SObject
            ObjRelStructure rootSObj = new ObjRelStructure(rootSObjDesc, null);
            rootSObj.uniqueKey = rootSObjDesc.getName();
            rootSObj.isCascadeDelete = true;


            // Add all the child relationships for this SObject 
            addAllChildRelationships(rootSObj, allObjRelStructure, childsToBeVisitedUniqueKey);

                            
            Integer i = 0;
            Set<String> childsVisitedUniqueKey = new Set<String>();

            while(allObjRelStructure.size() > 0 && i < allObjRelStructure.size() && !childsVisitedUniqueKey.contains(allObjRelStructure[i].uniqueKey)){
                ObjRelStructure sObjRelStruc = allObjRelStructure[i];
                
                // Add all the child relationships for this SObject 
                // addAllChildRelationships(sObjRelStruc, allObjRelStructure, childsToBeVisitedUniqueKey);
                
                i++;
                childsVisitedUniqueKey.add(sObjRelStruc.uniqueKey);
            }
            
            return JSON.serializePretty(rootSObj);
        } else {
            return '{}';
        }
    }

    private static ObjRelStructure feedItemStruc = null;

    public static void addForcedIncludedRelationships(ObjRelStructure sObjRelStruc, List<ObjRelStructure> allObjRelStructure, Set<String> childsVisitedUniqueKey) {
        if(feedItemStruc <> null && forcedStandardObjectsToIncludeRelationships.contains(sObjRelStruc.name)) {
            sObjRelStruc = feedItemStruc;

            return;
        }

        Boolean isAFeedItem = forcedStandardObjectsToIncludeRelationships.contains(sObjRelStruc.name);
        Boolean isChildAFeedItem = false;
        
        for(ObjRelStructure childSObjRelStruc : sObjRelStruc.childObjRelStructure) {
            isChildAFeedItem = forcedStandardObjectsToIncludeRelationships.contains(childSObjRelStruc.name);
            
            if(isAFeedItem || isChildAFeedItem) {
                if(feedItemStruc <> null && isChildAFeedItem) {
                    childSObjRelStruc = feedItemStruc;

                    break;
                }
                
                childSObjRelStruc.childObjRelStructure = new List<ObjRelStructure>();

                addAllChildRelationships(childSObjRelStruc, allObjRelStructure, childsVisitedUniqueKey, true);
                addForcedIncludedRelationships(childSObjRelStruc, allObjRelStructure, childsVisitedUniqueKey);
            }
        }

        if(isChildAFeedItem) {
            feedItemStruc = sObjRelStruc;
        }
    }

    @RemoteAction
    public static List<ObjRelStructure> addChildsToRelStructure(List<ObjRelStructure> sObjRelStrucList, List<String> childsVisitedUniqueKey) {    
        List<ObjRelStructure> allObjRelStructure = new List<ObjRelStructure>();
        
        for(ObjRelStructure sObjRelStruc : sObjRelStrucList) {
            sObjRelStruc.childObjRelStructure = new List<ObjRelStructure>();

            addAllChildRelationships(sObjRelStruc, allObjRelStructure, new Set<String>(childsVisitedUniqueKey), false);
            addForcedIncludedRelationships(sObjRelStruc, allObjRelStructure, new Set<String>(childsVisitedUniqueKey));
        }

        return sObjRelStrucList;
    }
    
    // Save the GRAX_Schedule_Process__c record based on the form data.
    public Pagereference saveScheduledProcess() {
        Boolean condition = false;
        
        if(active) {
            condition = condition && scheduleStartDate <> null;
            condition = condition && scheduleStartTime <> null;
        }

        if(scheduledProcessType == 'Multi-Object') {
            condition = objectJSON <> null;
            condition = condition && schedule <> null;
            condition = condition && objectJSON <> '[]';
            condition = condition && progressive <> null;

            if(condition) {
                gsp.Select_Criteria__c = criteria;

                List<ObjRelStructure> selection = (List<ObjRelStructure>)JSON.deserialize(objectJSON, List<ObjRelStructure>.class);
                if(selection.size() > 0) {
                    gsp.Object_Name__c = selection.get(0).uniqueKey;
                }

                if(String.isNotBlank(targetDate)) {
                    gsp.Target_Start_Datetime__c = GRAXUtils.createDateTime(targetDate, targetTime);
                }

                if(String.isNotBlank(targetEndDate)) {
                    gsp.Target_End_Datetime__c = GRAXUtils.createDateTime(targetEndDate, targetEndTime);
                }
            }
        }
        
        if(scheduledProcessType == 'Hierarchy') {
            condition = selectedObject <> null;
            condition = condition && sObjectDateField <> null;
            condition = condition && (targetDate <> null || targetEndDate <> null || targetReport <> null);
            condition = condition && (filterCriteriaType == 'Date' || filterCriteriaType == 'Report');
            condition = condition && criteria <> null;
            condition = condition && schedule <> null;
            condition = condition && objectJSON <> null;
            condition = condition && (archive <> null || progressive <> null);
            condition = condition && isSendNotifications <> null;
            condition = condition && isRollingDate <> null;

            if(condition) {
                gsp.Object_Name__c = selectedObject;
                gsp.Date_Field__c = sObjectDateField;
                if(filterCriteriaType == 'Date') {
                    if(String.isNotBlank(targetDate)) {
                        gsp.Target_Start_Datetime__c = GRAXUtils.createDateTime(targetDate, targetTime);
                    } else {
                        gsp.Target_Start_Datetime__c = null;
                    }
                    if(String.isNotBlank(targetEndDate)) {
                        gsp.Target_End_Datetime__c = GRAXUtils.createDateTime(targetEndDate, targetEndTime);
                    } else {
                        gsp.Target_End_Datetime__c = null;
                    }
                    gsp.Select_Criteria__c = criteria;
                    gsp.Target_Report__c = null;
                }
                if(filterCriteriaType == 'Report') {
                    gsp.Target_Report__c = targetReport;
                    gsp.Select_Criteria__c = null;
                    gsp.Target_Start_Datetime__c = null;
                    gsp.Target_End_Datetime__c = null;
                }

                gsp.Archive__c = archive;
                
                gsp.Archive_Override_Approved_By__c = archive && overrideArchive ? UserInfo.getName() : null;
            }
        }

        if(condition) {
            gsp.Name__c = spName;
            gsp.type__c = scheduledProcessType;
            gsp.Schedule_Type__c = schedule;

            /*Datetime nextRunDate = GRAXUtils.createDateTime(scheduleStartDate, scheduleStartTime);
            if(gsp.Schedule_Type__c <> 'Once' || nextRunDate > Datetime.now()) {*/
                gsp.Next_Run_Date__c = active ? GRAXUtils.createDateTime(scheduleStartDate, scheduleStartTime) : null;
            /*} else {
                gsp.Next_Run_Date__c = null;
            }*/

            gsp.Progressive__c = progressive;
            gsp.Send_Notifications__c = isSendNotifications;
            gsp.Rolling_Date__c = isRollingDate;

            gsp.Frequency_Type__c = null;
            gsp.Frequency_Value__c = null;

            gsp.Active__c = active;

            if(schedule == 'Custom') {
                gsp.Frequency_Type__c = frequencyType;

                if(String.isNotBlank(frequencyValue)) {
                    gsp.Frequency_Value__c = Integer.valueOf(frequencyValue);
                }
            }

            // Insert or update the record.
            upsert gsp;

            if(selectionAttachment <> null) {
                GRAXUtils.setSelectionJSON(selectionAttachment, objectJSON);
            } else {
                GRAXUtils.setSelectionJSON(gsp.Id, objectJSON);
            }

            if(scheduledProcessType == 'Hierarchy' && parentsSelection <> null && parentsSelectionObjects.contains(selectedObject)) {
                if(parentsSelectionAttachment <> null) {
                    GRAXUtils.setSelectionJSON(parentsSelectionAttachment, parentsSelection);
                } else {
                    GRAXUtils.setSelectionJSON(gsp.Id, parentsSelection, 'ParentsSelectionJSON.txt');
                }
            }

            if(String.isNotBlank(usersSelection)) {
                if(usersSelectionAttachment <> null) {
                    GRAXUtils.setSelectionJSON(usersSelectionAttachment, usersSelection);
                } else {
                    GRAXUtils.setSelectionJSON(gsp.Id, usersSelection, 'usersSelectionJSON.txt');
                }
            }

            if(String.isNotBlank(extraEmails)) {
                if(extraEmailsAttachment <> null) {
                    GRAXUtils.setSelectionJSON(extraEmailsAttachment, extraEmails);
                } else {
                    GRAXUtils.setSelectionJSON(gsp.Id, extraEmails, 'extraEmails.txt');
                }
            }

            /*
            String graxSchedulerToProcessSchedJobs = 'GRAXSchedulerToProcessSchedJobs';
            String graxSchedulerToDeleteBackedUpData = 'GRAXSchedulerToDeleteBackedUpData';

            Set<String> crons = new Set<String>();

            for(CronTrigger ct : [
                SELECT CronJobDetail.Name
                FROM CronTrigger
                WHERE CronJobDetail.Name IN :new List<String>{ graxSchedulerToProcessSchedJobs, graxSchedulerToDeleteBackedUpData }
            ]) {
                crons.add(ct.CronJobDetail.Name);
            }

            // Check if the Scheduled not exist.
            if(!crons.contains(graxSchedulerToProcessSchedJobs)) {
                // RUN HOURLY
                if(!GRAXBackupCtrlTest.skipSchedules) String jobId = System.schedule(graxSchedulerToProcessSchedJobs, '0 0 * * * ?', new GRAXSchedulerToProcessSchedJobs());
            }

            // Check if the Scheduled not exist and is archive = true
            if(!crons.contains(graxSchedulerToDeleteBackedUpData) && archive) {
                // RUN HOURLY
                if(!GRAXBackupCtrlTest.skipSchedules) String jobId = System.schedule(graxSchedulerToDeleteBackedUpData, '0 0 * * * ?', new GRAXSchedulerToDeleteBackedUpData());
            }
            */

            cleanFormData();

            // Update the Map of Scheduled Process
            updateScheduledProcessMap();
        } else {
            System.debug(LoggingLevel.Error, 'THE DATA OF THE FORM IS NOT COMPLETE');
        }

        return null;
    }

    public void cleanFormData() {
        gsp = new GRAX_Schedule_Process__c();
        scheduledProcessType = '';
        selectedObject = '';
        filterCriteriaType = 'Date';
        targetDate = null;
        targetEndDate = null;
        targetReport = '';
        criteria = 'Main Object not modified';
        schedule = null;
        scheduleStartDate = null;
        scheduleStartTime = null;
        objectJSON = null;
        archive = false;
        overrideArchive = false;
        progressive = false;
        isReadOnly = false;
        selectionAttachment = null;
        spName = null;
        isSendNotifications = false;
        isRollingDate = false;
        active = true;
        parentsSelectionAttachment = null;
        parentsSelection = null;
        usersSelectionAttachment = null;
        usersSelection = null;
        extraEmails = null;
        frequencyType = null;
        frequencyValue = null;
    }

    public Pagereference cleanFormDataHandler() {
        cleanFormData();

        return null;
    }

    public List<String> notRunningStatus = new List<String>{'Aborted', 'Error'};

    public Boolean isScheduledProcessRunning(GRAX_Schedule_Process__c gsp, String message) {
        if(gsp.Is_Running__c) {
            if(message <> null) {
                pageAlertMessage = message;
            }

            return true;
        }

        return false;
    }

    public Boolean isScheduledProcessRunning(Id spId, String message) {
        GRAX_Schedule_Process__c sp = [SELECT Is_Running__c FROM GRAX_Schedule_Process__c WHERE Id = :spId];

        return isScheduledProcessRunning(sp, message);
    }

    // Select a ScheduledProcess to edit.
    public Pagereference selectScheduledProcess() {
        // Get Id of the selected Scheduled Process.
        Id spId = Apexpages.currentPage().getParameters().get('spId');

        if(isScheduledProcessRunning(spId, 'The Schedule Process "' + spId + '" is currently running.')) {
            return null;
        }

        cleanFormData();
        
        Boolean scheduleProcessExist = scheduledProcessMap.containsKey(spId);
        Boolean multiObjectExist = multiObjectBackupMap.containsKey(spId);

        // Check if the Scheduled Process exist.
        if(scheduleProcessExist || multiObjectExist) {
            updateScheduledProcessMap();

            ScheduledProcess sp;

            // Set the selection.
            if(scheduleProcessExist) {
                sp = scheduledProcessMap.get(spId);
            }

            if(multiObjectExist) {
                sp = multiObjectBackupMap.get(spId);
            }

            gsp = sp.GRAXScheduleProcess;

            scheduledProcessType = gsp.type__c;
            selectedObject = gsp.Object_Name__c;
            sObjectDateField = gsp.Date_Field__c;

            String formatTimeZone = userTimeZone;

            if(sp.dateFieldType == 'date') {
                formatTimeZone = 'GMT';
            }

            if(gsp.Target_Start_Datetime__c <> null) {
                targetDate = gsp.Target_Start_Datetime__c.format('MM/dd/yyyy', formatTimeZone);
                targetTime = gsp.Target_Start_Datetime__c.format('HH', formatTimeZone);
            }

            if(gsp.Target_End_Datetime__c <> null) {
                targetEndDate = gsp.Target_End_Datetime__c.format('MM/dd/yyyy', formatTimeZone);
                targetEndTime = gsp.Target_End_Datetime__c.format('HH', formatTimeZone);
            }

            if(sp.dateFieldType == 'date') {
                targetTime = null;
                targetEndTime = null;
            }

            targetReport = gsp.Target_Report__c;
            criteria = gsp.Select_Criteria__c;
            if(targetDate <> null || targetEndDate <> null) {
                filterCriteriaType = 'Date';
            }
            if(targetReport <> null) {
                filterCriteriaType = 'Report';
                criteria = 'Main Object not modified';
            }else{
                filterCriteriaType = 'Date';
            }
            schedule = gsp.Schedule_Type__c;
            isSendNotifications = gsp.Send_Notifications__c;
            isRollingDate = gsp.Rolling_Date__c;
            active = gsp.Active__c;

            if(gsp.Next_Run_Date__c <> null) {
                scheduleStartDate = gsp.Next_Run_Date__c.format('MM/dd/yyyy', userTimeZone);
                scheduleStartTime = gsp.Next_Run_Date__c.format('HH', userTimeZone);
            } else {
                scheduleStartTime = '00';
            }

            //objectJSON = gsp.Selected_Object_Hierarchy_JSON__c;
            selectionAttachment = GRAXUtils.getSelectionAttachment(gsp.Id);
            objectJSON = GRAXUtils.getSelectionJSON(selectionAttachment);

            archive = gsp.Archive__c;

            overrideArchive = archive && String.isNotBlank(gsp.Archive_Override_Approved_By__c);

            if(scheduledProcessType == 'Hierarchy' && parentsSelectionObjects.contains(selectedObject)) {
                parentsSelectionAttachment = GRAXUtils.getSelectionAttachment(gsp.Id, 'ParentsSelectionJSON.txt');
                parentsSelection = GRAXUtils.getSelectionJSON(parentsSelectionAttachment, '[]');
            }

            usersSelectionAttachment = GRAXUtils.getSelectionAttachment(gsp.Id, 'usersSelectionJSON.txt');
            usersSelection = GRAXUtils.getSelectionJSON(usersSelectionAttachment, '[]');

            extraEmailsAttachment = GRAXUtils.getSelectionAttachment(gsp.Id, 'extraEmails.txt');
            extraEmails = GRAXUtils.getSelectionJSON(extraEmailsAttachment, null);

            if(extraEmails <> null) {
                extraEmails = extraEmails.replace('\n', '\\n');
            }

            progressive = gsp.Progressive__c;
            isReadOnly = progressive && (gsp.Last_Start_Time__c <> null || gsp.Last_Run_Date__c <> null);
            spName = gsp.Name__c;

            if(schedule == 'Custom' && gsp.Frequency_Type__c <> null) {
                frequencyType = gsp.Frequency_Type__c;

                if(gsp.Frequency_Value__c <> null) {
                    frequencyValue = String.valueOf(gsp.Frequency_Value__c);
                }
            }
        }

        return null;
    }

    // Delete a ScheduledProcess.
    public Pagereference deleteScheduledProcess() {
        // Get Id of the Scheduled Process to delete.
        Id spId = Apexpages.currentPage().getParameters().get('spId');

        if(isScheduledProcessRunning(spId, 'The Schedule Process "' + spId + '" is currently running.')) {
            return null;
        }

        Boolean scheduleProcessExist = scheduledProcessMap.containsKey(spId);
        Boolean multiObjectExist = multiObjectBackupMap.containsKey(spId);

        // Check if the Scheduled Process exist.
        if(scheduleProcessExist || multiObjectExist) {
            ScheduledProcess sp;

            if(scheduleProcessExist) {
                sp = scheduledProcessMap.get(spId);

                scheduledProcessMap.remove(spId);
            }

            if(multiObjectExist) {
                sp = multiObjectBackupMap.get(spId);

                multiObjectBackupMap.remove(spId);
            }

            delete sp.GRAXScheduleProcess;

            updateScheduledProcessMap();
        }

        return null;
    }

    public Pagereference updateScheduleProcessTable() {
        updateScheduledProcessMap();

        return null;
    }

    // Update scheduledProcessMap with the latest data.
    public void updateScheduledProcessMap() {
        // Get the Map of GRAX_Schedule_Process__c
        Map<ID, GRAX_Schedule_Process__c> GRAXScheduledProcessMap = new Map<ID, GRAX_Schedule_Process__c>([SELECT Id, JobId__c, Name, Name__c, type__c, Select_Criteria__c, Object_Name__c, Target_Start_Datetime__c, Target_End_Datetime__c , Target_Report__c, Last_Start_Time__c, Last_Run_Date__c, Next_Run_Date__c, Date_Field__c, Schedule_Type__c, Archive__c, Archive_Override_Approved_By__c, Status__c, Progressive__c, Total_Objects_To_Process__c, Total_Objects_Processed__c, Total_Records_To_Send__c, Total_Records_Sent__c, Send_Notifications__c, Rolling_Date__c, Frequency_Type__c, Frequency_Value__c, Active__c, Is_Running__c, CreatedDate, Execution_Unique_Key__c, currentElementIndex__c, CreatedBy.Name FROM GRAX_Schedule_Process__c WHERE isDeleted = false ORDER BY Object_Name__c, Last_Run_Date__c]);

        Map<String, Decimal> GRAXScheduledProcessProgressByJobId = new Map<String, Decimal>();
        Set<String> executionUniqueKeysOfRunningArchiveProcesses = new Set<String>();
        for(GRAX_Schedule_Process__c gsp : GRAXScheduledProcessMap.values()) {
            GRAXScheduledProcessProgressByJobId.put(gsp.JobId__c, (Decimal)0);

            if(gsp.Status__c == 'Deleting Salesforce records' && gsp.Execution_Unique_Key__c <> null){
                executionUniqueKeysOfRunningArchiveProcesses.add(gsp.Execution_Unique_Key__c);
            }
        }

        for(AsyncApexJob aaj : [SELECT JobItemsProcessed, TotalJobItems FROM AsyncApexJob WHERE Id IN :GRAXScheduledProcessProgressByJobId.keySet() AND TotalJobItems > 0 AND Status NOT IN ('Aborted', 'Completed', 'Failed')]) {
            GRAXScheduledProcessProgressByJobId.put(String.valueOf(aaj.Id).substring(0,15), Math.ceil(((Decimal)aaj.JobItemsProcessed * 100) / (Decimal)aaj.TotalJobItems));
        }

        Map<Id, GRAX_Archive_Process__c> runningArchiveProcessByScheduleProcessId = new Map<Id, GRAX_Archive_Process__c>();
        if(!executionUniqueKeysOfRunningArchiveProcesses.isEmpty()){
            for(GRAX_Archive_Process__c gap : [SELECT Id, GRAX_Schedule_Process__c, Total_SFDC_Records_Deleted__c, Total_SFDC_Records__c FROM GRAX_Archive_Process__c WHERE Execution_Unique_Key__c IN : executionUniqueKeysOfRunningArchiveProcesses]){
                runningArchiveProcessByScheduleProcessId.put(gap.GRAX_Schedule_Process__c, gap);
            }
        }

        scheduledProcessMap.clear();

        if(GRAXScheduledProcessMap.size() > 0) {
            // Walk the filtered list of CronTriggers.
            for(GRAX_Schedule_Process__c gsp : GRAXScheduledProcessMap.values()) {
                ScheduledProcess sp = new ScheduledProcess();

                sp.name = gsp.Name__c;
                if(String.isBlank(sp.name) && String.isNotBlank(gsp.Name)) {
                    sp.name = getDefaultSpName(gsp);
                }
                sp.createdBy = gsp.CreatedBy.Name;
                sp.createdDate = GRAXUtils.formatDateTime(gsp.CreatedDate, userTimeZone);
                if(gsp.Last_Run_Date__c <> null) {
                    sp.lastRunDate = GRAXUtils.formatDateTime(gsp.Last_Run_Date__c, userTimeZone);
                }
                if(gsp.Next_Run_Date__c <> null) {// && gsp.Next_Run_Date__c > Datetime.now()) {
                    sp.nextRunDate = GRAXUtils.formatDateTime(gsp.Next_Run_Date__c, userTimeZone);
                }
                sp.parentObject = gsp.Object_Name__c;
                sp.archive = gsp.Archive__c ? 'Yes' : 'No';
                sp.status = gsp.Status__c;
                sp.isReadOnly = gsp.Progressive__c && gsp.Last_Start_Time__c <> null;
                sp.isActive = gsp.Active__c;
                sp.isRunning = isScheduledProcessRunning(gsp, null);
                sp.objectsProcessed = gsp.Total_Objects_Processed__c == null ? 0 : Integer.valueOf(gsp.Total_Objects_Processed__c);

                if(sp.status == 'Running' && gsp.Total_Objects_To_Process__c > 0){
                    sp.progress = 'Processing Object ' + (gsp.Total_Objects_Processed__c == gsp.Total_Objects_To_Process__c ? gsp.Total_Objects_Processed__c : gsp.Total_Objects_Processed__c + 1)  + ' of ' + gsp.Total_Objects_To_Process__c;

                    if(gsp.Target_Report__c == null || gsp.currentElementIndex__c > 0){
                    sp.progress += ' - ' + GRAXScheduledProcessProgressByJobId.get(gsp.JobId__c) + '%';

                        if(gsp.type__c == 'Hierarchy' && gsp.currentElementIndex__c > 0){
                            GRAXBatchToProcessSchedJob batch1 = new GRAXBatchToProcessSchedJob(gsp.Id, null, Integer.valueOf(gsp.currentElementIndex__c), null, false, false);

                            GRAXBatchToProcessSchedJob.maxParentIds2ProcessByChildIterationStatic = 1;
                            GRAXBatchToProcessSchedJob batch2 = new GRAXBatchToProcessSchedJob(gsp.Id, batch1.objects2Process, Integer.valueOf(gsp.currentElementIndex__c), null, false, false);

                            sp.currentChildObjectName = batch2.objects2Process[Integer.valueOf(gsp.currentElementIndex__c)].name;
                            sp.requireAdditionalParentIdsToRetrieve = batch2.parentIds2ProcessForChild.size() > 0;
                        }
                    }else if(gsp.Target_Report__c <> null){
                        sp.progress += ' - ' + 'N/A';
                    }
                }

                if(sp.status == 'Sending data to GRAX' && gsp.Total_Records_To_Send__c > 0){
                    sp.progress = Math.ceil(((Decimal)gsp.Total_Records_Sent__c * 100) / (Decimal)gsp.Total_Records_To_Send__c) + '%';
                }

                if(sp.status == 'Deleting Salesforce records' && runningArchiveProcessByScheduleProcessId.containsKey(gsp.Id) && runningArchiveProcessByScheduleProcessId.get(gsp.Id).Total_SFDC_Records__c > 0){
                    sp.progress = Math.ceil(((Decimal)runningArchiveProcessByScheduleProcessId.get(gsp.Id).Total_SFDC_Records_Deleted__c * 100) / (Decimal)runningArchiveProcessByScheduleProcessId.get(gsp.Id).Total_SFDC_Records__c) + '%';
                }

                sp.GRAXScheduleProcess = GRAXScheduledProcessMap.get(gsp.Id);
                
                if( GRAXUtils.sObjectExists( sp.parentObject ) ){
                    updateDateFieldsVsTypeMap(sp.parentObject);
                }else{
                    sp.status = 'Error';
                    sp.preventEdit = true;
                    GRAXLogs.addLogException( new GRAXException('The API Name of the main object has been changed. Please create a new Scheduled Process to backup/archive this object. GRAX Schedule Process Id: "' + gsp.Id + '"', 0), false);
                }

                updateDateFieldsVsTypeMap(sp.parentObject);

                sp.dateFieldType = dateFieldVsTypeMap.get(sp.GRAXScheduleProcess.Date_Field__c);

                // Add the ScheduledProcess object to the map.
                if(gsp.type__c == 'Hierarchy') {
                    scheduledProcessMap.put(gsp.Id, sp);
                }

                if(gsp.type__c == 'Multi-Object') {
                    multiObjectBackupMap.put(gsp.Id, sp);
                }
            }

            scheduledProcesses = doSortRows(scheduledProcessMap.values(), orderByHierarchy, sortOrderHierarchy, 'DummyOrder');
            totalRowsHierarchy = scheduledProcesses.size();
            goToHierarchyPage();
            
            multiObjectBackup = doSortRows(multiObjectBackupMap.values(), orderByMultiObject, sortOrderMultiObject, 'DummyOrder');
            totalRowsMultiObject = multiObjectBackup.size();
            goToMultiObjectPage();
        }
    }

    public void sortMultiObjectList(){
        multiObjectBackup = doSortRows(multiObjectBackup, orderByMultiObject, sortOrderMultiObject, previousOrderByMultiObject);

        if(previousOrderByMultiObject <> 'DummyOrder'){
            if(previousOrderByMultiObject.equals(orderByMultiObject)){
                sortOrderMultiObject = sortOrderMultiObject.equals('asc') ? 'desc' : 'asc';
            }else{
                sortOrderMultiObject = 'asc';
                previousOrderByMultiObject = orderByMultiObject;
            }
        }

        currentPageMultiObject = 0;
        goToMultiObjectPage();
    }

    public void sortHierarchyList(){
        scheduledProcesses = doSortRows(scheduledProcesses, orderByHierarchy, sortOrderHierarchy, previousOrderByHierarchy);

        if(previousOrderByHierarchy <> 'DummyOrder'){
            if(previousOrderByHierarchy.equals(orderByHierarchy)){               
                sortOrderHierarchy = sortOrderHierarchy.equals('asc') ? 'desc' : 'asc';
            }else{
                sortOrderHierarchy = 'asc';
                previousOrderByHierarchy = orderByHierarchy;
            }
        }

        currentPageHierarchy = 0;
        goToHierarchyPage();
    }

    private List<ScheduledProcess> doSortRows(List<ScheduledProcess> currentList, String orderBy, String sortOrder, String previousOrderBy){
        List<ScheduledProcess> resultList = new List<ScheduledProcess>();
        System.debug('here1');
        try{
            if(!previousOrderBy.equals(orderBy)){
                
                //Get the keys for sorting
                Map<String, List<ScheduledProcess>> rowsByKeysMap = new Map<String, List<ScheduledProcess>>();
                
                Set<Object> keySet = new Set<Object>();
                
                
                for(ScheduledProcess row : currentList){
                    List<String> objFields = orderBy.split('\\.');
                    
                    String key = '';
                    
                    if(orderBy <> 'name'){
                        SObject dynObj = (SObject)row.GRAXScheduleProcess;

                        for(Integer i = 0; i < objFields.size() - 1; i++){
                            if(dynObj <> null){
                                dynObj = dynObj.getSObject(objFields[i]);
                            }    
                        }
                        String orderByField = objFields[objFields.size()-1];
                                                                  
                        if(dynObj <> null){
                            Object keyValue = dynObj.get(orderByField);
                            if(keyValue <> null && keyValue instanceOf String){
                                keyValue = (Object)String.valueOf(keyValue).toLowerCase();
                            }
                            keySet.add(keyValue);
                            key = String.valueOf(keyValue);
                        }
                    }else{
                        System.debug('here');
                        Object keyValue = (Object)String.valueOf(row.name).toLowerCase();
                        keySet.add(keyValue);
                        key = String.valueOf(keyValue);
                    }
                    
                    if(!rowsByKeysMap.containsKey(key)){
                        rowsByKeysMap.put(key, new List<ScheduledProcess>());
                    }
                    rowsByKeysMap.get(key).add(row);
                }
                
                List<Object> keys = new List<Object>(keySet);                
                keys.sort();

                for(Object key : keys){
                    resultList.addAll(rowsByKeysMap.get(String.valueOf(key)));
                }
            }else{
                //We assume that the list is already sorted
                List<ScheduledProcess> tempList = currentList.clone();

                for(Integer i = tempList.size()-1; i >= 0; i--){
                   resultList.add(tempList[i]);
                }
            }                        
        }catch(Exception e){            
               
        }
        return resultList;
    }

    public void goToHierarchyPage(){
        currentPageHierarchyList = getCurrentPageElements(scheduledProcesses, currentPageHierarchy);
    }

    public void goToMultiObjectPage(){
        currentPageMultiObjectList = getCurrentPageElements(multiObjectBackup, currentPageMultiObject);
    }

    private List<ScheduledProcess> getCurrentPageElements(List<ScheduledProcess> currentList, Integer pageNumber){
        List<ScheduledProcess> currentPageList = new List<ScheduledProcess>();
        
        
        Integer firstElementIndex = pageNumber * rowsPerPage;
        Integer lastElementIndex = (firstElementIndex + rowsPerPage) > currentList.size() ? currentList.size() : (firstElementIndex + rowsPerPage);

        for(Integer i = firstElementIndex; i < lastElementIndex; i++){
            currentPageList.add(currentList[i]);
        }

        return currentPageList;
    }

    public Pagereference execScheduledProcess() {
        // Get Id of the Scheduled Process to execute.
        Id spId = Apexpages.currentPage().getParameters().get('spId');

        if(isScheduledProcessRunning(spId, 'The Schedule Process "' + spId + '" is currently running.')) {
            return null;
        }
        
        Boolean scheduleProcessExist = scheduledProcessMap.containsKey(spId);
        Boolean multiObjectExist = multiObjectBackupMap.containsKey(spId);

        // Check if the Scheduled Process exist.
        if(scheduleProcessExist || multiObjectExist) {
            GRAX_Schedule_Process__c gsp;

            if(scheduleProcessExist) {
                gsp = scheduledProcessMap.get(spId).GRAXScheduleProcess;
            }

            if(multiObjectExist) {
                gsp = multiObjectBackupMap.get(spId).GRAXScheduleProcess;
            }

            //gsp.Status__c = 'Running';
            //update gsp;

            GRAXSchedulerToProcessSchedJobs.enqueueSchedule(gsp, true);

            updateScheduledProcessMap();
        }

        return null;
    }

    public Pagereference abortScheduledProcess() {
        // Get Id of the Scheduled Process to abort.
        Id spId = Apexpages.currentPage().getParameters().get('spId');

        if(isScheduledProcessRunning(spId, null)) {
            Boolean scheduleProcessExist = scheduledProcessMap.containsKey(spId);
            Boolean multiObjectExist = multiObjectBackupMap.containsKey(spId);

            // Check if the Scheduled Process exist.
            if(scheduleProcessExist || multiObjectExist) {
                GRAX_Schedule_Process__c gsp;

                if(scheduleProcessExist) {
                    gsp = scheduledProcessMap.get(spId).GRAXScheduleProcess;
                }

                if(multiObjectExist) {
                    gsp = multiObjectBackupMap.get(spId).GRAXScheduleProcess;
                }

                gsp.Status__c = 'Aborted';
                update gsp;

                updateScheduledProcessMap();
            }
        }

        return null;
    }

    public Pagereference deactivateScheduledProcess() {
        // Get Id of the Scheduled Process to deactivate.
        Id spId = Apexpages.currentPage().getParameters().get('spId');

        if(!isScheduledProcessRunning(spId, null)) {
            Boolean scheduleProcessExist = scheduledProcessMap.containsKey(spId);
            Boolean multiObjectExist = multiObjectBackupMap.containsKey(spId);

            // Check if the Scheduled Process exist.
            if(scheduleProcessExist || multiObjectExist) {
                GRAX_Schedule_Process__c gsp;

                if(scheduleProcessExist) {
                    gsp = scheduledProcessMap.get(spId).GRAXScheduleProcess;
                }

                if(multiObjectExist) {
                    gsp = multiObjectBackupMap.get(spId).GRAXScheduleProcess;
                }

                gsp.Active__c = false;
                update gsp;
            }
        }

        return null;
    }
    
    // Whenever the user selects 'Re-try sending data' option, the method will execute
    // the GRAXBatchToReTrySendingDataRecords batch.
    public PageReference retrySendingData() {
        Id spId = Apexpages.currentPage().getParameters().get('spId');
        GRAXBatchToReTrySendingDataRecords batch = new GRAXBatchToReTrySendingDataRecords(spId);
        Database.executeBatch(batch);
        
        return null;
    }
    
    private Map<String, String> dateFieldVsTypeMap = new Map<String, String>();
    public void updateDateFieldsVsTypeMap(String selectedObject){
        dateFieldVsTypeMap.clear();

        if(String.isNotBlank(selectedObject)) {
            
            if( GRAXUtils.sObjectExists( selectedObject ) ){
                Set<String> dateTypes = new Set<String>{'date','datetime'};
                    
                for(Schema.DescribeFieldResult fd : GRAXUtils.getDescribeFieldsResultForObject(selectedObject).values()) {
                    String fieldType = fd.getType().name().toLowerCase();
                    
                    if(dateTypes.contains(fieldType)){
                        dateFieldVsTypeMap.put(fd.getName(), fieldType);
                    }
                }
            }else{
                // sObject was not found.                
            }
        }
    }

    public String getDateFieldsVsTypeJSON(){
        updateDateFieldsVsTypeMap(selectedObject);

        return JSON.serialize(dateFieldVsTypeMap);
    }
    
    public List<SelectOption> getSObjectDateFields(){
        List<SelectOption> options = new List<SelectOption>();

        if(String.isNotBlank(selectedObject)) {
            Set<String> dateTypes = new Set<String>{'date','datetime'};
            
            for(Schema.DescribeFieldResult fd : GRAXUtils.getDescribeFieldsResultForObject(selectedObject).values()) {
                String fieldType = fd.getType().name().toLowerCase();
                
                if(dateTypes.contains(fieldType)){
                    options.add(new SelectOption(fd.getName(), fd.getLabel()));
                }
            }
        }

        options.sort();
        
        return options;
    }

    public String getReportsJSON() {
        List<Object> rList = new List<Object>();
        Map<String, Object> rMap;

        for (Report r : [SELECT Id, Name FROM Report WHERE Format = 'Tabular' AND (FolderName Like '%GRAX%' OR Name Like '%GRAX%') ORDER BY CreatedDate DESC]) {
            rMap = new Map<String, Object>();
            rMap.put('id', r.Id);
            rMap.put('name', r.Name);

            rList.add(rMap);
        }
        
        return JSON.serialize(rList);
    }

    public String getBackupItemsJSON(String scheduledProcessType) {
        List<ObjRelStructure> objs = new List<ObjRelStructure>();
        ObjRelStructure obj;

        for(SelectOption op : getItems(scheduledProcessType)) {
            if(!op.getDisabled()) {
                obj = new ObjRelStructure();
                obj.uniqueKey = op.getValue();
                obj.name = op.getLabel();

                objs.add(obj);
            }
        }

        return JSON.serialize(objs);
    }

    public String getBackupItemsJSON() {
        return this.getBackupItemsJSON('Hierarchy');
    }

    public String getItemsMultiObjectJSON() {
        return this.getBackupItemsJSON('Multi-Object');
    }

    public static String getDefaultSpName(GRAX_Schedule_Process__c gsp) {
        return gsp.type__c + ' Backup ' + (Integer.valueOf(gsp.Name.split('GRAX-Proc-').get(1)) + 1);
    }

    public String getUsersJSON() {
        List<Map<String, String>> objs = new List<Map<String, String>>();
        Map<String, String> obj;

        for(User u : [SELECT Id, Name, Email FROM User WHERE IsActive = true]) {
            obj = new Map<String, String>();
            obj.put('id', u.Id);
            obj.put('label', u.Name + ' (' + u.Email + ')');

            objs.add(obj);
        }

        return JSON.serialize(objs);
    }

}