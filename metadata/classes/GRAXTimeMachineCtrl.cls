/*****************************************************************************************
Name              : GRAXTimeMachineCtrl
Description       : 
Revision History  :
Created/Modified by   Created/Modified Date     Requested by        Related Task/Issue     
----------------------------------------------------------------------------------------
1. Leandro Brunner          07/02/2018
2. Leandro Brunner          09/17/2018          David Mackey        Agco Fixes (https://app.asana.com/0/326600806074978/770976244463043/f)
3. Leandro Brunner          01/11/2019          David Mackey        AGCO/Grax Object Time Machine Issues (https://app.asana.com/0/326600806074978/968580178906301/f)
4. Leandro Brunner          01/14/2019          David Mackey        Clear field values for ObjectTimeMachine (https://app.asana.com/0/326600806074978/979549583600888/f)
5. Leandro Brunner          03/07/2019          David Mackey        New Issues (https://app.asana.com/0/326600806074978/1112342626420899/f)
6. N Leiva/N Ralero	 		05/22/2019			David Mackey		UI Updates (https://app.asana.com/0/326600806074978/1123206281327080/f)
7. Leandro Brunner          05/31/2019          David Mackey        Date Format should be based on user locale (https://app.asana.com/0/326600806074978/1125157851523067/f)
******************************************************************************************/
public with sharing class GRAXTimeMachineCtrl {
    public Id parentId {get;set;}
	public String userTimeZone {get;set;}
    public String parentType {get;set;}
    public GRAXSettings__c graxConfig {get;set;}
    public String timeMachine {get;set;}
    public List<FileSelectOption> fileSelect {get;set;}
    String fileSelected = null;
    public String fileContents {get;set;}
    String strParentId;
	public FileSelectOption olderBackup {get;set;}
	public Boolean showRestoreToOldVersionButton {get;set;}
    public Boolean isTest = false;
    public String GRAXFileDataTest;

    public Object noVisibleValue = '***';

	private List<Object> oldState {get;set;}
	private List<Object> newState {get;set;}

	public class Field {
        public String name {get;set;}
        public String label {get;set;}
        public String type {get;set;}

        public Boolean isCreateable {get;set;}
        public Boolean isUpdateable {get;set;}
        public Boolean isNillable {get;set;}

        public Field(Schema.DescribeFieldResult fd) {
            this.name = fd.getName();
            this.label = CleanFieldLabel(fd, true);
            this.type = fd.getType().name();

			this.isCreateable = fd.isCreateable();
            this.isUpdateable = fd.isUpdateable();
            this.isNillable = fd.isNillable();
        }

		public String CleanFieldLabel(Schema.DescribeFieldResult sField, Boolean escapeForVF){
            String fieldLabel = sField.getLabel();
            
            if(!sField.isCustom() && sField.getType().name() == 'REFERENCE' && fieldLabel.endsWith(' ID')){
                fieldLabel = fieldLabel.removeEnd(' ID');
            } 
            
            if(escapeForVF){
                fieldLabel = fieldLabel.escapeHtml4();
            }
            
            return fieldLabel;
        }
    }

    public transient GRAXRestoreCtrl gr;
    public String selectedFields {get;set;}
    public transient List<String> selectedFieldsList {get;set;}
    public Boolean isRetrieved {get;set;}

    public Integer resultsLimit {get;set;}
    public Integer totalRetrieved {get;set;}
    public Boolean excludeVersionsWithoutChanges {get;set;}

    public static GRAXPermissions gp {
        get {
            return new GRAXPermissions(UserInfo.getUserId());
        }
    }
    
    public GRAXTimeMachineCtrl() {
        isTest = Test.isRunningTest();
        isRetrieved = false;

        resultsLimit = 200;

        excludeVersionsWithoutChanges = false;
        
		userTimeZone = UserInfo.getTimeZone().getID();
        graxConfig = GRAXSettings__c.getOrgDefaults();
        strParentId = Apexpages.currentPage().getParameters().get('Id');
        
        if(String.isNotBlank(strParentId)) {
            parentId = (Id)strParentId;
            parentType = parentId.getSObjectType().getDescribe().getName();
            
            getHistory(null, null);
        }
    }

    public void getHistory(String selectedFields, String marker) {
        if(marker <> null) {
            marker = marker.split('/')[marker.split('/').size()-1];
        }

        timeMachine = GRAXAuditTrail.GetTimeMachine(parentType, parentId, selectedFields, marker, null, resultsLimit, true, excludeVersionsWithoutChanges);
        fileSelect = ParseJSON(timeMachine);

        isRetrieved = true;
    }
    
    public String getfileSelected() {
        return fileSelected;
    }

	public Boolean getHasBackups() {
		return fileSelect <> null && fileSelect.size() > 0;
	}

	public Boolean getIsFileSelected() {
		return fileSelected <> null;
	}
    
    
    // TODO : We should parse the JSON display the differences between NEW and OLD in JSON                
    public void setfileSelected(String currentFile, String filePrev) {
		this.fileSelected = currentFile; 
		String fileName = currentFile.split('/')[currentFile.split('/').size()-1];
        String GRAXFileData;
        if(this.isTest) {
            GRAXFileData = this.GRAXFileDataTest;
        } else if(filePrev <> null) {
            String filePrevName = filePrev.split('/')[filePrev.split('/').size()-1];
            GRAXFileData = GRAXAuditTrail.GetTimeMachineFile(parentType, parentId, fileName, filePrevName);
        } else {
            GRAXFileData = GRAXAuditTrail.GetTimeMachineFile(parentType, parentId, fileName);
        }
        Map<String, Object> o = (Map<String, Object>)JSON.deserializeUntyped(GRAXFileData);
		Map<String, Object> data = (Map<String, Object>)(o.get('data'));

		oldState = (List<Object>)(data.get('old'));
		newState = (List<Object>)(data.get('new'));

		//showRestoreToOldVersionButton = olderBackup.file == currentFile;
		showRestoreToOldVersionButton = oldState <> null;
		showRestoreToOldVersionButton &= !oldState.isEmpty();

		this.fileContents = JSON.serializePretty(o);
	}

    class FileSelectOption {
        public String file {get;set;}
        public String lastModifiedDate {get;set;}
        public String lastModifiedBy {get;set;}
        public List<Object> extraFieldsValues {get;set;}
    }
    
    public List<FileSelectOption> ParseJSON(String graxconfig){
        String FieldName = '';
        String FieldValue = '';
        String S3Key = '';
        fileSelect = new List<FileSelectOption>();

        Map<String, List<FileSelectOption>> fileSelectMap = new Map<String, List<FileSelectOption>>();

        if(this.isTest) {
        
            for(Integer i=10; i <= 14; i++) {
                String datetimeString = '2018-06-' + i + 'T18:57:24.000Z';
                Datetime updatedDate = (Datetime)GRAXUtils.castGenericObjectToType(datetimeString, 'datetime');
                
                if(!fileSelectMap.containsKey(datetimeString)) {
                    fileSelectMap.put(datetimeString, new List<FileSelectOption>());
                }
                
                FileSelectOption fso = new FileSelectOption();
                fso.file = 'grax/audittrail/salesforce/00D1I000003nRMaUAM/Case/5001I000003yey4QAA/2018-06-' + i + 'T18-57-24-000-0000.json';
                fso.lastModifiedDate = updatedDate.format('MM/dd/yyyy HH:mm', userTimeZone);
                fso.lastModifiedBy = ' - ';

                fileSelectMap.get(datetimeString).add(fso);
            }

        } else {
            try{
                if (String.isNotBlank(graxconfig)){
                    Map<String, Object> versionsData = (Map<String, Object>)((Map<String, Object>)JSON.deserializeUntyped(graxconfig)).get('data');

                    for(Object o : (List<Object>)versionsData.get('Contents')) {
                        Map<String, Object> versionMap = (Map<String, Object>)o;
                        
                        FileSelectOption fileVersion = new FileSelectOption();
                        fileVersion.file = (String)versionMap.get('Key');

                        String lastModified = (String)versionMap.get('LastModified');
                        Datetime updateDate = (Datetime)GRAXUtils.castGenericObjectToType(lastModified, 'datetime');
                        fileVersion.lastModifiedDate = GRAXUtils.formatDateTime(updateDate, userTimeZone);

                        fileVersion.lastModifiedBy = (String)versionMap.get('grax_LastModifiedBy_Name');

                        if(!selectedFieldsList.isEmpty()) {

                            System.debug(JSON.serializePretty(versionMap));

                            fileVersion.extraFieldsValues = new List<Object>();

                            Map<String, Field> fieldMap = getFieldsMapBySObjectName(this.parentType, true);

                            for (String f : selectedFieldsList) {
                                if(GRAXSecurityUtils.checkAccess(this.parentType, f, GRAXSecurityUtils.FLSEnums.READ)) {
                                    fileVersion.extraFieldsValues.add(versionMap.get('_' + f));
                                } else {
                                    fileVersion.extraFieldsValues.add(noVisibleValue);
                                }
                            }
                        }

                        if(!fileSelectMap.containsKey(lastModified)) {
                            fileSelectMap.put(lastModified, new List<FileSelectOption>());
                        }

                        fileSelectMap.get(lastModified).add(fileVersion);
                    }
                }
    
            } catch (Exception e) {
                System.debug(e);
            } finally {
                //optional finally block
                //code to run whether there is an exception or not
            }
        }

        List<String> keyList = new List<String>(fileSelectMap.keySet());
        keyList.sort();

        for(Integer i = keyList.size() - 1; i >= 0; i--) {
            fileSelect.addAll(fileSelectMap.get(keyList[i]));
        }

		if(fileSelect.size() > 0) {
			olderBackup = fileSelect.get(0);
		}

        totalRetrieved = fileSelect.size();

        return fileSelect;
    }

    public String getAllHistoryUrl() {
        String allHistoryUrl = '#';

        GRAXSettings gxs = new GRAXSettings();

        String userId = UserInfo.getUserId();
        String orgid = UserInfo.getOrganizationId();
        String url = gxs.graxConfig.GRAX_Flow_URL__c + '/grax-app/public/grax-react/index.html';
        String sessionid = userinfo.getSessionId();
        String endpoint = EncodingUtil.urlencode(System.URL.getSalesforceBaseUrl().toExternalForm(),'utf-8');
  
        GRAXCloud.CallOutResponse callOutRes = GRAXCloud.calloutnow(
        gxs.graxConfig.GRAX_Flow_URL__c + '/jwt', '{"url": "' + url + '"}');

        System.debug(callOutRes);
        if(callOutRes.success) {
            Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(callOutRes.response);
            String token = (String)responseMap.get('token');
        
            allHistoryUrl = url;
            allHistoryUrl += '?orgid=' + orgid;
            allHistoryUrl += '&sessionid=' + sessionid;
            allHistoryUrl += '&endpoint=' + endpoint;
            allHistoryUrl += '&token=' + token;
            allHistoryUrl += '&userid=' + userid;
            allHistoryUrl += '&objecttype=' + this.parentType;
            allHistoryUrl += '&objectid=' + this.parentId;
            allHistoryUrl += '#timemachine';
        }

        return allHistoryUrl;
    }

    public String getFileSelectJson() {
        List<Object> sopList = new List<Object>();

        if(fileSelect <> null) {
            for (FileSelectOption sop : fileSelect) {
                sopList.add(sop);
            }
        }
        
        return JSON.serialize(sopList);
    }
    
    public Pagereference changeFileSelected() {
        String fileSelected = Apexpages.currentPage().getParameters().get('fileSelected');
        String filePrev = Apexpages.currentPage().getParameters().get('filePrev');

		if(String.isNotBlank(fileSelected)) {
			setfileSelected(fileSelected, String.isNotBlank(filePrev) ? filePrev : null);
		}

		return null;
	}

	public static Map<String, Object> getObjectMapById(Id sId) {
        String sobjectName = GRAXUtils.getSObjectNameById(sId);
        List<String> sObjectFields = getFilteredCalculatedFieldsByOBjectName(sobjectName, false);

        String query = 'SELECT ' + String.join(sObjectFields, ', ') + ' FROM ' + sobjectName + ' WHERE Id = :sId LIMIT 1';

        Map<String, Object> objectMap = new Map<String, Object>();
        for(SObject rec : Database.query(query)) {
            for(String f: sObjectFields) {
                objectMap.put(f, rec.get(f));
            }
        }

        List<String> objCalculatedFields = getFilteredCalculatedFieldsByOBjectName(sobjectName, true);

        if(objCalculatedFields.size() > 0) {
            for(List<Object> calculatedFields : GRAXUtils.splitList(objCalculatedFields, 20)) { 
                query = 'SELECT ' + String.join(calculatedFields, ', ') + ' FROM ' + sobjectName + ' WHERE Id = :sId LIMIT 1';

                for(SObject rec : Database.query(query)) {
                    for(Object f: calculatedFields) {
                        objectMap.put((String)f, rec.get((String)f));
                    }
                }
            }
        }

        return objectMap;
    }

    public static Map<String, Field> getFieldsMapBySObjectName(String sObjectName, Boolean retrieveAllFields) {
        Map<String, Field> fieldsMap = new Map<String, Field>();

        for(Schema.DescribeFieldResult fd : GRAXUtils.getDescribeFieldsResultForObject(sObjectName).values()) {
            Field f = new Field(fd);
            
            if(f.isUpdateable || retrieveAllFields) {
                fieldsMap.put(f.name, f);
            }
        }
        return fieldsMap;
    }

    public static List<String> getUpdateableFieldsByOBjectName(String sObjectName) {
        List<String> updateableFields = new List<String>();

        for(Schema.DescribeFieldResult fd : GRAXUtils.getDescribeFieldsResultForObject(sObjectName).values()) {
            if(fd.isUpdateable()) {
                updateableFields.add(fd.getName());
            }
        }

        return updateableFields;
    }

    public static List<String> getFilteredCalculatedFieldsByOBjectName(String sObjectName, Boolean retrieveCalculatedFields) {
        List<String> filteredFields = new List<String>();

        for(Schema.DescribeFieldResult fd : GRAXUtils.getDescribeFieldsResultForObject(sObjectName).values()) {
            if(retrieveCalculatedFields == fd.isCalculated()) {
                filteredFields.add(fd.getName());
            }
        }

        return filteredFields;
    }

    public void updateSObject(Id soId, Map<String, Object> mo) {
        updateSObject(soId, mo, false);
    }

    public void updateSObject(Id soId, Map<String, Object> mo, Boolean setBlankValues) {
        boolean personaccount = false;
        List<String> objfieldlist = getUpdateableFieldsByOBjectName(this.parentType);

        if (this.parentType=='Account'){
            personaccount = mo.get('IsPersonAccount') <> null && Boolean.valueOf(mo.get('IsPersonAccount'));
            if (!personaccount){
                List<String> filteredList = new List<String>();
                for(String f : objfieldlist){
                    if (f.indexOf('__pc')==-1) {
                       filteredList.add(f);
                    }
                }
                objfieldlist = filteredList;
            } else {
                Integer nameIndex = objfieldlist.indexOf('Name');

                if(nameIndex <> -1) {
                    objfieldlist.remove(nameIndex);
                }
            }
        }     

        SObject so = Database.query('SELECT ' + String.join(objfieldlist, ', ') + ' FROM ' + this.parentType + ' WHERE Id = :soId LIMIT 1');
		SObject so2 = Schema.getGlobalDescribe().get(this.parentType).newSObject(soId);

        Map<String, Field> fieldMap = getFieldsMapBySObjectName(this.parentType, false);
        // system.debug('parentType: ' + this.parentType + ' IsPersonAccount: ' + personaccount);    
        for(Field f : fieldMap.values()) {
            try {
                if(f.isUpdateable && GRAXSecurityUtils.checkAccess(this.parentType, f.name, GRAXSecurityUtils.FLSEnums.MODIFY)) {
                    if(setBlankValues && f.isNillable && so.get(f.name) <> null && (!mo.containsKey(f.name) || mo.get(f.name) == null)) {
                        so2.put(f.name, null);
                    }

                    if(mo.containsKey(f.name) && (f.name.indexOf('__pc')==-1 || (f.name.indexOf('__pc')!=-1) && personaccount==true)) {
                        // system.debug('fieldname: ' + f.name + ' parentType: ' + this.parentType + ' IsPersonAccount: ' + personaccount); 
                        so2.put(f.name, GRAXUtils.castGenericObjectToType(mo.get(f.name), f.type));
                    }
                }
            } catch(Exception e) {
                GRAXLogs.addLogException(e);

                System.debug(LoggingLevel.WARN, e.getMessage() + ' on field ' + f.label);
            }
        }
        update so2;
    }

	public Pagereference restoreToOldVersion() {
        Boolean setBlankValues = Apexpages.currentPage().getParameters().get('setBlankValues') == 'true';

		for(Object o : oldState) {
			updateSObject(parentId, (Map<String, Object>)o, setBlankValues);
		}

		return null;
	}

	public Pagereference updateToThisVersion() {
        Boolean setBlankValues = Apexpages.currentPage().getParameters().get('setBlankValues') == 'true';

        for(Object o : newState) {
			updateSObject(parentId, (Map<String, Object>)o, setBlankValues);
		}

		return null;
	}

	public class MapFieldDiff {
        public Object oldValue {get;set;}
        public Object newValue {get;set;}
        public Object currentValue {get;set;}

        public Boolean isDifferent {get;set;}

        public MapFieldDiff(Object oldValue, Object newValue, Object currentValue) {
			this.oldValue = oldValue;
			this.newValue = newValue;
            this.currentValue = currentValue;

            this.isDifferent = oldValue <> newValue;
		}

        public String getStyleClass() {
            return this.isDifferent ? 'isDifferent' : '';
        }
	}

	public Object getMapValue(Map<String, Object> m, String key) {
		if(m <> null && key <> null && m.containsKey(key)) {
			return m.get(key);
		}

		return null;
	}

    private Set<String> excludedDiffSystemFields = new Set<String>{'SystemModstamp'};

	public Map<String, MapFieldDiff> getDiff() {
		Map<String, MapFieldDiff> diff = new Map<String, MapFieldDiff>();

		Map<String, Field> fieldMap = getFieldsMapBySObjectName(this.parentType,true);

		Map<String, Object> oldMap = (Map<String, Object>)(oldState.get(0));
		Map<String, Object> newMap = (Map<String, Object>)(newState.get(0));
        Map<String, Object> currentObject = getObjectMapById(parentId);

        for(Field f : fieldMap.values()) {
			//if(f.isUpdateable) {
                MapFieldDiff mfd;
                
                mfd = new MapFieldDiff(getMapValue(oldMap, f.name), getMapValue(newMap, f.name), getMapValue(currentObject, f.name));

                if(!GRAXSecurityUtils.checkAccess(this.parentType, f.name, GRAXSecurityUtils.FLSEnums.READ)) {
                    mfd.currentValue = noVisibleValue;
                    mfd.oldValue = noVisibleValue;
                    mfd.newValue = noVisibleValue;
                }

                if(mfd.currentValue instanceof Date || mfd.currentValue instanceof Datetime) {
                    mfd.currentValue = GRAXUtils.formatDateTime(mfd.currentValue, userTimeZone);
                    mfd.oldValue = GRAXUtils.formatDateTimeString((String)mfd.oldValue, userTimeZone);
                    mfd.newValue = GRAXUtils.formatDateTimeString((String)mfd.newValue, userTimeZone);
                }

                if(excludedDiffSystemFields.contains(f.name)) {
                    mfd.isDifferent = false;
                }

                diff.put(f.Name, mfd);
			//}
        }

		return diff;
	}

    public String getFieldsJSON() {
        gr = new GRAXRestoreCtrl();
        gr.fieldMap = null;

        return gr.getFieldsJSON(parentType);
    }
    
    public Pagereference retrieveHistory() {
        String marker = GRAXUtils.getPageParameter('marker');

        if(String.isBlank(marker)) {
            selectedFields = GRAXUtils.getPageParameter('selectedFields');
        }
		
        selectedFieldsList = new List<String>();
        
        if(String.isNotBlank(selectedFields)) {
            if(String.isBlank(marker)) {
                selectedFieldsList = (List<String>)JSON.deserialize(selectedFields, List<String>.class);
            }
        }
       
        excludeVersionsWithoutChanges = GRAXUtils.getPageParameter('excludeVersionsWithoutChanges') == 'true';
		
        getHistory(String.join(selectedFieldsList, ','), marker);

        return null;
    }
}