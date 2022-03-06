/******************************************************************************
// File Name:       RecapEmailRestHandler.cls
// Details:         The Apex REST handler for Recap Email requests
// Test Classes:    RecapEmailRestHandlerTests
====================
// Modification Log: (Name - Change Summary - Initial)
// Roman Bulgakov    - 23/09/2020 - created
*******************************************************************************/

public with sharing class RecapEmailRestHandler implements Callable
{
    private String SEND_RECAP_EMAIL_ACTION_NAME = 'Recap Email - Send Email';
    
    public Object call(String action, Map<String, Object> parameters) 
    {
        String recordId = (String)parameters.get('recordId');
        if(String.isBlank(recordId)) throw new PartnerRestEndpoint.PartnerWebhookHandlerException('Invalid request. Missing source record ID.');
        
        SObject record = loadSourceRecord(recordId);
        if(record == null) throw new PartnerRestEndpoint.PartnerWebhookHandlerException('Invalid request. Can not find source record by ID: ' + recordId + '.');
        
        SObject actionRecord = (Test.isRunningTest() ? new FLX_KB__KanBan_Action_Group__c() : [select Id from FLX_KB__KanBan_Action_Group__c where Name = :SEND_RECAP_EMAIL_ACTION_NAME]);
        if(actionRecord == null) throw new PartnerRestEndpoint.PartnerWebhookHandlerException('Can not find action to send Recap Email.');
        
        String startHTML = '<div style="background-color:#EBF1F8;margin:0; padding:30px 0;">' + 
                        '<div style="max-width:768px; margin:10px auto; background-color:#ffffff; padding:75px  30px 30px; border: 1px solid #5281BD;' + 
                        'background-repeat:no-repeat; background-image:url(\'https://shyftmoving123--c.documentforce.com/servlet/servlet.ImageServer?id=0156g000000XZNW&oid=00D6g000001YOmf&lastMod=1604433238000\')">';
        String endHTML = '</div><br><div style="text-align:center; font-size:0.8em;">549 Market St., PMB 57421<br>San Francisco, California 94104-5401 US</div></div>';
        
        List<ID> services = new List<ID>();
        String body = buildBody(record, parameters, services);
        if(services.size() == 0) return false;
        
        System.debug(new Map<String, Object>{
            'actionOrGroupId' => actionRecord.Id,
            'variables' => JSON.serialize(new Map<String, String>{
                'header' => buildHeader(record, parameters),
                'body' => body,
                'footer' => buildFooter(record, parameters),
                'startHTML' => startHTML,
                'endHTML' => endHTML,
                'DISABLE_SAVEPOINT' => 'true',
                'services' => JSON.serialize(services),
                'sourceId' => record.Id,
                'automated' => 'true'
            })
        });
        
        new FLX_KB.API().call('KanBanActionService', 'executeActionOrGroup', new Map<String, Object>{
            'actionOrGroupId' => actionRecord.Id,
            'variables' => JSON.serialize(new Map<String, String>{
                'header' => buildHeader(record, parameters),
                'body' => body,
                'footer' => buildFooter(record, parameters),
                'startHTML' => startHTML,
                'endHTML' => endHTML,
                'DISABLE_SAVEPOINT' => 'true',
                'services' => JSON.serialize(services),
                'sourceId' => record.Id,
                'automated' => 'true'
            })
        });
        
        return true;
    }
    
    private String buildHeader(SObject record, Map<String, Object> parameters)
    {
        String result = 'Hello {FIRST_NAME},<br/><br/>' + 
                        'I’d like to congratulate you on your new position and move to {DESTINATION}! ' + 
                        'I have placed the following referrals on your behalf to {RMC_NAME} and Shyft’s trusted service partners. ' +
                        'Organizing a move takes time, so it is really important for you to schedule the services you need as soon as possible. <br><br>' + 
                        '<ul><li style="margin-bottom:10px;"><b>Moving Your Belongings</b> - Shyft - Click <a href="{LANDING_PAGE_LINK}" target="_blank">here</a> to schedule your video survey. ' + 
                        'We will inventory your belongings and provide you with flexible options shortly after you have confirmed your inventory. ' + 
                        'The name of the app you will be using is Shyft Next!</li></ul>';
            
        if(record instanceof Opportunity)
        {
            result = result.replace('{FIRST_NAME}', toString(getSObjectValue(record, 'Primary_Contact__r.FirstName')));
            result = result.replace('{DESTINATION}', toString(getSObjectValue(record, 'Destination__c')));
            result = result.replace('{RMC_NAME}', toString(getSObjectValue(record, 'Account.RMC__r.Name')));
            result = result.replace('{WORK_START_DATE}', toString(getSObjectValue(record, 'Work_Start_Date__c')));
            result = result.replace('{LANDING_PAGE_LINK}', toString(getSObjectValue(record, 'RMC_Account__r.Landing_Page__c')));
        }else{
            result = result.replace('{FIRST_NAME}', toString(getSObjectValue(record, 'Name')));
            result = result.replace('{DESTINATION}', toString(getSObjectValue(record, 'Destination__c')));
            result = result.replace('{RMC_NAME}', toString(getSObjectValue(record, 'RMC_Account__r.Short_Account_Name__c')));
            result = result.replace('{WORK_START_DATE}', toString(getSObjectValue(record, 'Work_Start_Date__c')));
            result = result.replace('{LANDING_PAGE_LINK}', toString(getSObjectValue(record, 'RMC_Account__r.Landing_Page__c')));
        }

        return result;
    }
    
    private String buildBody(SObject record, Map<String, Object> parameters, List<ID> services)
    {
        return buildOtherPart(record, parameters, services) + buildLifestylePart(record, parameters, services);
    }
    
    private String buildFooter(SObject record, Map<String, Object> parameters)
    {
        String result = '<p>{WEB_SITE_MESSAGE}</p><hr><hr> <p>Our service partners and Shyft strive to provide you with high-quality service every ' + 
                        'step of the way. Should you have any questions or concerns, please do not hesitate to contact me directly.</p>' + 
                        '<p><br>Best,<br>{COACH_NAME}<br>{RMC_PHONE}</p>';
        
        if(record instanceof Opportunity)
        {
            result = result.replace('{COACH_NAME}', toString(getSObjectValue(record, 'Move_Coach_Owner__r.Name')));
            result = result.replace('{WEB_SITE_MESSAGE}', toString(getSObjectValue(record, 'RMC_Account__r.Website_Message__c')));
            result = result.replace('{RMC_PHONE}', toString(getSObjectValue(record, 'Account.RMC_Phone_No__c')));
        }else{
            result = result.replace('{COACH_NAME}', toString(getSObjectValue(record, 'Owner__c')));
            result = result.replace('{WEB_SITE_MESSAGE}', toString(getSObjectValue(record, 'RMC_Account__r.Website_Message__c')));
            result = result.replace('{RMC_PHONE}', toString(getSObjectValue(record, 'RMC_Account__r.Phone')));
        }
        
        return result;
    }
    
    private String buildLifestylePart(SObject record, Map<String, Object> parameters, List<ID> services)
    {
        List<String> templates = new List<String>();
        for(Account nextAccount : [select Recap_Email_Template__c from Account where RecordType.Name = 'Partners' and Recap_Email__c = true and Account_Status__c = 'Active' and Lifestyle_Partnership__c = true order by Name asc nulls first])
        {   
            templates.add(nextAccount.Recap_Email_Template__c);
            if(services != null) services.add(nextAccount.Id);
        }
        
        if(templates.size() == 0) return '';
        
        String result = '<br/><p>Here are direct links to some additional services you might be interested in:</p><br/><ul><li style="margin-bottom:0px;">';
        result += String.join(templates, '</li><li style="margin-bottom:0px;">');
        result += '</li></ul><br/>';
        
        return result;
    }
    
    private String buildOtherPart(SObject record, Map<String, Object> parameters, List<ID> services)
    {
        List<Object> ids = (List<Object>)parameters.get('services');
        if(ids == null || ids.size() == 0) return '';
        
        List<ID> accountsIds = new List<ID>();
        for(Object serviceId : ids)
            accountsIds.add((String)serviceId);
        
        List<String> templates = new List<String>();
        for(Account nextAccount : [select Recap_Email_Template__c from Account where Id in :accountsIds order by Name])
        {
            templates.add(nextAccount.Recap_Email_Template__c);
            services.add(nextAccount.Id);
        }
        
        if(templates.size() == 0) return '';
        
        String result = '<ul style="margin-top: 1em;"><li style="margin-bottom:10px;">';
        result += String.join(templates, '</li><li style="margin-bottom:10px;">');
        result += '</li></ul>';
        
        return result;
    }
    
    private SObject loadSourceRecord(ID recordId)
    {
        if(recordId.getSObjectType() == Lead.getSObjectType()) return [select Name, Destination__c, RMC_Account__r.Short_Account_Name__c, Work_Start_Date__c, RMC_Account__r.Landing_Page__c, RMC_Account__r.Website_Message__c, Owner__c, RMC_Account__r.Phone from Lead where Id = :recordId];
        else return [select Destination__c, Work_Start_Date__c, Account.RMC_Phone_No__c, Account.RMC__r.Name, RMC_Account__r.Landing_Page__c, RMC_Account__r.Website_Message__c, Move_Coach_Owner__r.Name, Primary_Contact__r.FirstName from Opportunity where Id = :recordId];
    }
    
    private Object getSObjectValue(sObject obj, String fieldPath)
    {
        String[] splited = fieldPath.split('\\.',-2);
        for(Integer i = 0; i < splited.size() - 1; i++)
        {
            obj = obj.getSObject(splited[i]); 
            if(obj == null) return null;
        }
        
        return obj.get(splited[splited.size() - 1]);
    }
    
    private String toString(Object value)
    {
        if(value == null) return '';
        if(value instanceof Date) return DateTime.newInstance((Date)value, Time.newInstance(0, 0, 0, 0)).format('MM/dd/yyyy');
        if(value instanceof DateTime) return DateTime.newInstance((Date)value, Time.newInstance(0, 0, 0, 0)).format('MM/dd/yyyy hh:mm a');
        return String.valueOf(value);
    }
}