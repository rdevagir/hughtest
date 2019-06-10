public class GRAXAuditTrail extends GRAXCloud {
	public GRAXCloud.CallOutResponse AuditConfig;
	public String ConnectionString = '';
	
	public Integer numberoftables = 0;
	public String schema = '';
	public String query = '';
	public String prefix = '';
	
	public Static String GetTimeMachine(String ObjectType, String ObjectId, String extraFields, String marker, Integer maxKeys, Integer resultsLimit, Boolean reverse, Boolean excludeVersionsWithoutChanges){
		String retValue = '';
		GRAXSettings gxcSettings = new GRAXSettings();
		String Params = '{"orgid":"' + UserInfo.getOrganizationId() + '",' +
						'"objecttype":\"' + ObjectType + '",' +
						'"objectid":"' +  ObjectId + '",' + 
	        			 	'"s3accesskeyid":"' + gxcSettings.graxConfig.s3accesskeyid__c + '",' + 
	        			 	'"s3secretaccesskey":"' + gxcSettings.graxConfig.s3secretaccesskey__c + '",' + 
	        		     	'"s3bucket":"' + gxcSettings.graxConfig.s3bucket__c + '",' + 
	        			 	'"s3region":"' + gxcSettings.graxConfig.s3region__c + '"';

		if(String.isNotBlank(extraFields)) {
			Params += ',"_extraFields":"' + extraFields + '"';
		}

		if(String.isNotBlank(marker)) {
			Params += ',"Marker":"' + marker + '"';
		}

		if(maxKeys <> null && maxKeys > 0) {
			Params += ',"MaxKeys":"' + maxKeys + '"';
		}

		if(resultsLimit > 0) {
			Params += ',"_limit": ' + resultsLimit;
		}

		if(reverse) {
			Params += ',"_reverse":true';
		}

		if(excludeVersionsWithoutChanges) {
			Params += ',"_excludeVersionsWithoutChanges":true';
		}

		Params += '}';
	        			 	
		String url = gxcSettings.ApiURL + '/platforms/amazon/s3/getversions';
		//url = 'http://75a410e6.ngrok.io/graxproxy/api/platforms/amazon/s3/getversions';
	
		GRAXCloud.CallOutResponse callout  = GRAXCloud.calloutnow(url,Params);
		if(callout.success) {
				retValue = callout.response;
		}
        return retValue;
	}
	
	public Static String GetTimeMachineFile(String ObjectType, String ObjectId,String FileName,String prevFileName){
		String retValue = '';
		GRAXSettings gxcSettings = new GRAXSettings();
		String Params = '{"orgid":"' + UserInfo.getOrganizationId() + '",' +
						'"objecttype":\"' + ObjectType + '",' +
						'"objectid":"' +  ObjectId + '",' + 
						'"filename":"' +  FileName + '",' + 
	        			 	'"s3accesskeyid":"' + gxcSettings.graxConfig.s3accesskeyid__c + '",' + 
	        			 	'"s3secretaccesskey":"' + gxcSettings.graxConfig.s3secretaccesskey__c + '",' + 
	        		     	'"s3bucket":"' + gxcSettings.graxConfig.s3bucket__c + '",' + 
	        			 	'"s3region":"' + gxcSettings.graxConfig.s3region__c + '"';

		if(prevFileName <> null) {
			Params += ',"_prevFileName":"' + prevFileName + '"';
		}

		Params += '}';
	        			 	
		String url = gxcSettings.ApiURL + '/platforms/amazon/s3/getfile';
		// url = 'https://683a91cf.ngrok.io/graxproxy/api/platforms/amazon/s3/getfile';

		GRAXCloud.CallOutResponse callout  = GRAXCloud.calloutnow(url,Params);
		if(callout.success) {
				retValue = callout.response;
		}
        return retValue;
	}

	public Static String GetTimeMachineFile(String ObjectType, String ObjectId,String FileName){
		return GetTimeMachineFile(ObjectType, ObjectId, FileName, null);
	}
	
    public String GetAuditSettings(String ConnString){
    		ConnectionString = ConnString;
    		String content = '{"connectionstring" : "' + ConnectionString + '"}';
    		GRAXSettings gxcSettings = new GRAXSettings();
    		String url = gxcSettings.ApiURL + '/platforms/heroku/postgres/getpartitionsize';
    		AuditConfig = GRAXCloud.calloutnow(url,content);
    		ParseConfig();
    		// debug('GRAXAuditTrail.GetAuditSettings',AuditConfig.response);
    		return AuditConfig.response;
    }
    
    public void ParseConfig(){
    		if (AuditConfig.success){
	    		schema = GetAppConfig('schema');
	    		query = GetAppConfig('query');
	    		prefix = GetAppConfig('prefix');
	    		String val = GetAppConfig('numberoftables');
	    		numberoftables = 0;
	    		if (val != '' && val != null)
	    			numberoftables = Integer.valueof(val);
    		}
    }
    
    private String GetAppConfig(String fieldName){
    		String ReturnValue = '';
    		if (AuditConfig.success){
    			JSONParser parser = JSON.createParser(AuditConfig.response);
    			while (parser.nextToken() != null) {
    				if (parser.getCurrentToken() == JSONToken.FIELD_NAME && parser.getText() == fieldName){
        				parser.nextToken();
        				ReturnValue = parser.getText();
        				//debug('GRAXAuditTrail.GetAuditSettings',fieldName + '=' + ReturnValue);
        			}
        		}
    		}
    		return ReturnValue;
    }
    
    public String CreateAuditSettings(String ConnString,Integer NumberOfPartitions){
    		ConnectionString = ConnString;
    		String content = '{"connectionstring" : "' + ConnectionString + '","numberoftables":' + NumberOfPartitions + '}';
    		GRAXSettings gxcSettings = new GRAXSettings();
    		String url = gxcSettings.ApiURL + '/platforms/heroku/postgres/auditinstall';
    		AuditConfig = GRAXCloud.calloutnow(url,content);
    		ParseConfig();
    		//debug('GRAXAuditTrail.GetAuditSettings',AuditConfig.response);
    		return AuditConfig.response;
    }
    
    public String DropAuditParitions(String ConnString,Integer NumberOfPartitions){
    		ConnectionString = ConnString;
    		String content = '{"connectionstring" : "' + ConnectionString + '","numberoftables":' + NumberOfPartitions + '}';
    		GRAXSettings gxcSettings = new GRAXSettings();
    		String url = gxcSettings.ApiURL + '/platforms/heroku/postgres/audituninstall';
    		AuditConfig = GRAXCloud.calloutnow(url,content);
    		ParseConfig();
    		//debug('GRAXAuditTrail.DropAuditParitions',AuditConfig.response);
    		return AuditConfig.response;
    }
    
}