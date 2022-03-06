global with sharing class PartnerReferralcHandler extends EDHU.SObjectHandler 
{
	public class PartnerReferralcHandlerException extends Exception {}
	
    global override void afterInsert(List<SObject> newList){
        System.debug('Overriden beforeInsert');

        List<Partner_Referral__c> emailList = new List<Partner_Referral__c>();
        for(Partner_Referral__c ref : (List<Partner_Referral__c>)newList) {
            if( ref.Referral_Email_Sent__c == false) {
                emailList.add(ref);
            } 
        }
        
        sendPartnerReferralEmails(emailList);   
    }

    global override void afterUpdate(List<SObject> newList, Map<Id, SObject> oldMap){
        System.debug('Overriden beforeInsert');

        List<Partner_Referral__c> emailList = new List<Partner_Referral__c>();
        for(Partner_Referral__c ref : (List<Partner_Referral__c>)newList) {
            if( ref.Referral_Email_Sent__c == false) {
                emailList.add(ref);
            } 
        }
        
        sendPartnerReferralEmails(emailList); 
    }

    /*
    * 
    * This needs to happen in an after trigger, because it relies VERY heavily on Formula fields to be recalculated before this code runs
    * 
    */
    
    public void sendPartnerReferralEmails(List<Partner_Referral__c> newReferralList) 
	{
    	if(newReferralList.size() == 0) return;
    	
        Set<ID> accountIds = new Set<ID>();
        Set<ID> oppoptunityIds = new Set<ID>();
        Set<ID> leadIds = new Set<ID>();
        Set<ID> transfereeIds = new Set<ID>();
        Map<String, Id> templateIdMap = getTemplateIdMap();
        
        List<Partner_Referral__c> referrals = new List<Partner_Referral__c>();
        for (Partner_Referral__c referral : newReferralList) 
        {
        	if(referral.Referral_Method__c != 'Referral email to partner') continue;
        	
            if(referral.Account__c != null) accountIds.add(referral.Account__c);
            if(referral.Opportunity__c != null) oppoptunityIds.add(referral.Opportunity__c);
            if(referral.Lead__c != null) leadIds.add(referral.Lead__c);
            if(referral.Transferee_Job__c != null) transfereeIds.add(referral.Transferee_Job__c);
            referrals.add(referral);
        }
        
        if(referrals.size() == 0) return;

		Map<ID, Account> accounts = getAccounts(accountIds);
        List<Contact> contacts = getReferralContacts(accounts.values());
        Map<ID, List<Contact>> refContactByAccId = mapAccountToContacts(contacts);
        Map<ID, List<String>> refEmailByAccId = getRelatedContactEmails(contacts);
        Map<String, String> emailTemplateNames = getPickListValuesIntoMap();
        Map<ID, Lead> leadMap = getLeadMap(leadIds);
        Map<ID, Opportunity> opportunityMap = getOpportunityMap(oppoptunityIds);
        Map<ID, Transferee_Job__c> transfereeMap = getTransfereeMap(transfereeIds);
        List<PartnerReferralEmailWrapper> emailWrappers = new List<PartnerReferralEmailWrapper>();
        
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        for (Partner_Referral__c referral : referrals) 
        {
            PartnerReferralEmailWrapper wrap = new PartnerReferralEmailWrapper();
            String etName = emailTemplateNames.get(referral.Referral_Type_Filter__c.replace('_', ' '));

            ID templateId = templateIdMap.get(etName);
            if (templateId == null) continue;

            ID relatedRecordId, targetObjectId;
            if(referral.Lead__c != null) {
                relatedRecordId = referral.Lead__c;
                
                if(refContactByAccId.get(referral.Account__c) == null || refContactByAccId.get(referral.Account__c).size() == 0)
                	throw new PartnerReferralcHandlerException('Can\'t find the referral Contact for the related Account. The record ID: ' + referral.Id + '.');
                	
                targetObjectId = refContactByAccId.get(referral.Account__c)[0].Id;
                if (etName == 'Referral Type: Rental Assistance' || etName == 'Referral Type: Roommates')  {
                    wrap.ccRecipients.add(leadMap.get(relatedRecordId).Email);
                }else{
                	Account relatedAccount = (referral.Account__c != null ? accounts.get(referral.Account__c) : null);
	                if(relatedAccount != null && relatedAccount.Copy_Customer_on_Referral__c == true) {
	                	wrap.ccRecipients.add(leadMap.get(relatedRecordId).Email);
	                }
                }
            }
            else if(referral.Opportunity__c != null) {
                relatedRecordId = referral.Opportunity__c;
                
                if(opportunityMap.get(referral.Opportunity__c) == null)
                	throw new PartnerReferralcHandlerException('Can\'t find the Primary Contact for the related Opportunity. The record ID: ' + referral.Id + '.');
                	
                targetObjectId = opportunityMap.get(referral.Opportunity__c).Primary_Contact__c;
                if (etName == 'Referral Type: Rental Assistance' || etName == 'Referral Type: Roommates')  {
                    wrap.ccRecipients.add(opportunityMap.get(relatedRecordId).Primary_Contact__r.Email);
                }else{
	            	Account relatedAccount = (referral.Account__c != null ? accounts.get(referral.Account__c) : null);
	                if(relatedAccount != null && relatedAccount.Copy_Customer_on_Referral__c == true) {
	                	wrap.ccRecipients.add(opportunityMap.get(relatedRecordId).Primary_Contact__r.Email);
	                }
                }
            }
            else if(referral.Transferee_Job__c != null) {
                relatedRecordId = transfereeMap.get(referral.Transferee_Job__c).Opportunity__c;
                targetObjectId = transfereeMap.get(referral.Transferee_Job__c).Opportunity__r.Primary_Contact__c;
                if (etName == 'Referral Type: Rental Assistance' || etName == 'Referral Type: Roommates')  {
                    wrap.ccRecipients.add(transfereeMap.get(referral.Transferee_Job__c).Opportunity__r.Primary_Contact__r.Email);
                }
            }
            
            if (etName == 'Referral Type: Real Estate')  {
                if(String.isBlank(referral.RMC_Consultant_email__c)) continue;
                wrap.toRecipients.add(referral.RMC_Consultant_email__c);
            }else{
            	wrap.toRecipients = refEmailByAccId.get(referral.Account__c);
            }
            
            wrap.ccRecipients.add('housing@shyftmoving.com');
            wrap.saveAsActivity = true;
            wrap.whatId = referral.Id;
            wrap.templateId = templateId;
            wrap.targetObjId = targetObjectId;
            
            emailWrappers.add(wrap);
            emailList.add(sendTemplatedEmail(wrap.toRecipients, wrap.ccRecipients, wrap.templateId, wrap.targetObjId, wrap.whatId, null, wrap.saveAsActivity, null));
            System.debug('wrap: ' + wrap);
        }
        
        if(emailList.size() == 0) return;

		List<Partner_Referral__c> updatedPartnerReferrals = new List<Partner_Referral__c>();
        List<Messaging.SendEmailResult> results = Messaging.sendEmail(emailList);
        for(integer i = 0; i < results.size(); i++) {
            Messaging.SendEmailResult result = results[i];
            if (result.isSuccess() == false) {
                Partner_Referral__c ref = new Partner_Referral__c();
                ref.Id = emailWrappers[i].whatId;
                ref.Referral_Email_Sent__c = false;
                updatedPartnerReferrals.add(ref);
            }else {
                Partner_Referral__c ref = new Partner_Referral__c();
                ref.Id = emailWrappers[i].whatId;
                ref.Referral_Email_Sent__c = true;
                updatedPartnerReferrals.add(ref);
            }
        }
        
        EDHU.TriggerPanel.setBreaker('PartnerReferralc', false);
        // EDHU.TriggerPanel.setMainBreaker(false);
        if(updatedPartnerReferrals.size() > 0) update updatedPartnerReferrals;
        // EDHU.TriggerPanel.setMainBreaker(true);
        EDHU.TriggerPanel.setBreaker('PartnerReferralc', true);
    }
    
    /*
    public void sendPartnerReferralEmails(List<Partner_Referral__c> newReferralList) {
        System.debug('sendPartnerReferralEmails');
        // SETUP TO GET ALL NEEDED INFO FROM RELATED OBJECTS
        Map<String, Id> templateIdMap = getTemplateIdMap();
        Set<Id> accIdSet = getAccIdFromReferrals(newReferralList);
        Set<Id> oppIds = getOppIdFromReferrals(newReferralList);
        Set<Id> ldIds = getLeadIdFromReferrals(newReferralList);
        Set<Id> transfereeIds = getTransfereeIdFromReferrals(newReferralList);

        List<Contact> conList = getReferralContacts(accIdSet);
        Map<Id, List<Contact>> refContactByAccId = mapAccountToContacts(conList);
        Map<Id, List<String>> refEmailByAccId = getRelatedContactEmails(conList);
        Map<String, String> emailTemplateNames = getPickListValuesIntoMap();
        Map<Id, Lead> leadMap = getLeadMap(ldIds);
        Map<Id, Opportunity> opportunityMap = getOpportunityMap(oppIds);
        Map<Id, Transferee_Job__c> transfereeMap = getTransfereeMap(transfereeIds);
        List<PartnerReferralEmailWrapper> emailWrappers = new List<PartnerReferralEmailWrapper>();
        List<Partner_Referral__c> updatedPartnerReferrals = new List<Partner_Referral__c>();

        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        for (Partner_Referral__c ref : newReferralList) {

            PartnerReferralEmailWrapper wrap = new PartnerReferralEmailWrapper();
            String etName = emailTemplateNames.get(ref.Referral_Type_Filter__c.replace('_', ' '));
            System.debug('etName: ' + etName);
            Id templateId = templateIdMap.get(etName);
            if (templateId == null) continue;
            System.debug('found templateId: ' + templateId);

            Id relatedRecordId;
            Id targetObjectId;
            if ( ref.Lead__c != null ) {
                relatedRecordId = ref.Lead__c;
                targetObjectId = refContactByAccId.get(ref.Account__c)[0].Id;
                if (etName == 'Referral Type: Rental Assistance' || etName == 'Referral Type: Roommates')  {
                    wrap.ccRecipients.add(leadMap.get(relatedRecordId).Email);
                }
                System.debug('relatedRecord is lead');
            }
            else if (ref.Opportunity__c != null) {
                relatedRecordId = ref.Opportunity__c;
                targetObjectId = opportunityMap.get(ref.Opportunity__c).Primary_Contact__c;
                if (etName == 'Referral Type: Rental Assistance' || etName == 'Referral Type: Roommates')  {
                    wrap.ccRecipients.add(opportunityMap.get(relatedRecordId).Primary_Contact__r.Email);
                }
                System.debug('relatedRecord is opp');
            }
            else if (ref.Transferee_Job__c != null) {
                relatedRecordId = transfereeMap.get(ref.Transferee_Job__c).Opportunity__c;
                targetObjectId = transfereeMap.get(ref.Transferee_Job__c).Opportunity__r.Primary_Contact__c;
                if (etName == 'Referral Type: Rental Assistance' || etName == 'Referral Type: Roommates')  {
                    wrap.ccRecipients.add(transfereeMap.get(ref.Transferee_Job__c).Opportunity__r.Primary_Contact__r.Email);
                }
                System.debug('relatedRecord is Transferee');
            }
            
            System.debug('refEmailByAccId.get(ref.Account__c): ' + refEmailByAccId.get(ref.Account__c));
            wrap.ccRecipients.add('housing@shyftmoving.com');
            wrap.saveAsActivity = true;
            wrap.whatId = ref.Id;
            wrap.toRecipients = refEmailByAccId.get(ref.Account__c);

            wrap.templateId = templateId;
            wrap.targetObjId = targetObjectId;
            emailWrappers.add(wrap);
            Messaging.SingleEmailMessage email = sendTemplatedEmail(wrap.toRecipients, wrap.ccRecipients, wrap.templateId, wrap.targetObjId, wrap.whatId, null, wrap.saveAsActivity, null);
            emailList.add(email);
            System.debug('wrap: ' + wrap);
            
        }

        List<Messaging.SendEmailResult> results = Messaging.sendEmail(emailList);
        for(integer i = 0; i < results.size(); i++) {
            Messaging.SendEmailResult result = results[i];
            System.debug('SendEmailResult: ' + result);
            if (result.isSuccess() == false) {
                System.debug('Email error: ' + result.getErrors());
                Partner_Referral__c ref = new Partner_Referral__c();
                ref.Id = emailWrappers[i].whatId;
                ref.Referral_Email_Sent__c = false;
                updatedPartnerReferrals.add(ref);
            }
            else {
                System.debug('SendEmailResult: ' + result.isSuccess());
                Partner_Referral__c ref = new Partner_Referral__c();
                ref.Id = emailWrappers[i].whatId;
                ref.Referral_Email_Sent__c = true;
                updatedPartnerReferrals.add(ref);
            }
        }
        
        EDHU.TriggerPanel.setBreaker('PartnerReferralc', false);
        // EDHU.TriggerPanel.setMainBreaker(false);
        update updatedPartnerReferrals;
        // EDHU.TriggerPanel.setMainBreaker(true);
        EDHU.TriggerPanel.setBreaker('PartnerReferralc', true);
    }
	*/

    //
    //
    // UTILITY METHODS FOR
    //
    //
    /*
    @TestVisible
    private Set<Id> getAccIdFromReferrals(List<Partner_Referral__c> referrals) {
        Set<Id> accIdSet = new Set<Id>();
        for (Partner_Referral__c ref : referrals) {
            accIdSet.add(ref.Account__c);
        }
        return accIdSet;
    }

    @TestVisible
    private Set<Id> getOppIdFromReferrals(List<Partner_Referral__c> referrals) {
        Set<Id> oppIdSet = new Set<Id>();
        for (Partner_Referral__c ref : referrals) {
            oppIdSet.add(ref.Opportunity__c);
        }
        return oppIdSet;
    }

    @TestVisible
    private Set<Id> getLeadIdFromReferrals(List<Partner_Referral__c> referrals) {
        Set<Id> ldIdSet = new Set<Id>();
        for (Partner_Referral__c ref : referrals) {
            ldIdSet.add(ref.Lead__c);
        }
        return ldIdSet;
    }

    @TestVisible
    private Set<Id> getTransfereeIdFromReferrals(List<Partner_Referral__c> referrals) {
        Set<Id> trIdSet = new Set<Id>();
        for (Partner_Referral__c ref : referrals) {
            trIdSet.add(ref.Transferee_Job__c);
        }
        return trIdSet;
    }
    
    @TestVisible
    private List<Contact> getReferralContacts(Set<Id> accIds) {
       return [SELECT Id, AccountId, Email FROM Contact WHERE Referral_Contact__c = true AND AccountId IN: accIds];
    }
    */
    
    private Map<ID, Account> getAccounts(Set<ID> ids) {
       	return new Map<ID, Account>([select Copy_Customer_on_Referral__c, (select AccountId, Email from Contacts where Referral_Contact__c = true) from Account where Id in :ids]);
    }
    
    private List<Contact> getReferralContacts(List<Account> records) {
       	List<Contact> result = new List<Contact>();
       	for(Account record : records)
			result.addAll(record.Contacts);
			
       	return result;
    }

    @TestVisible
    private Map<Id, List<String>> getRelatedContactEmails (List<Contact> conList) {
        Map<Id, List<String>> refEmailByAccId = new Map<Id, List<String>>();
        for (Contact con : conList) {
            System.debug('contact: ' + con);
            if( !refEmailByAccId.containskey(con.AccountId) ) {
                refEmailByAccId.put(con.AccountId, new List<String>());
            }
            refEmailByAccId.get(con.AccountId).add(con.Email);
            System.debug('refEmailByAccId.get(con.AccountId): ' + refEmailByAccId.get(con.AccountId));
        }
        return refEmailByAccId;
    }

    @TestVisible
    private Map<Id, List<Contact>> mapAccountToContacts (List<Contact> conList) {
        Map<Id, List<Contact>> refContactByAccId = new Map<Id, List<Contact>>();
        for (Contact con : conList) {
            System.debug('contact: ' + con);
            if( !refContactByAccId.containskey(con.AccountId) ) {
                refContactByAccId.put(con.AccountId, new List<Contact>());
            }
            refContactByAccId.get(con.AccountId).add(con);
            System.debug('refEmailByAccId.get(con.AccountId): ' + refContactByAccId.get(con.AccountId));
        }
        return refContactByAccId;
    }

    // @TestVisible
    // private Map<Id, SObject> getCCEmails(Set<Id> oppIds, Set<Id> ldIds) {
    //     List<Opportunity> oppList = [SELECT Id, Primary_Contact__c, Primary_Contact__r.Email FROM Opportunity WHERE Id IN: oppIds];
    //     List<Lead> ldList = [SELECT Id, Email FROM Lead WHERE Id IN: ldIds];

    //     Map<Id, SObject> ccEmailById = new Map<Id, SObject>();
    //     for (Opportunity opp : oppList) {
    //         ccEmailById.put(opp.Id, opp);
    //     }
    //     for (Lead ld : ldList) {
    //         ccEmailById.put(ld.Id, ld);
    //     }
    //     return ccEmailById;
    // }

    @TestVisible
    private Map<String, Id> getTemplateIdMap() {
        Map<String, Id> templateIdMap = new Map<String, Id>();
        List<EmailTemplate> emailTemplateList = [SELECT Id, Name FROM EmailTemplate WHERE Name LIKE 'Referral Type:%'];
        for (EmailTemplate et : emailTemplateList) {
            templateIdMap.put(et.Name, et.Id);
        }
        return templateIdMap;
    }

    @TestVisible
    private Map<String, String> getPickListValuesIntoMap(){
        Map<String, String> pickListValuesMap = new Map<String, String>();
        Schema.DescribeFieldResult fieldResult = Partner_Referral__c.Referral_Type_Filter__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple){
            String temp = 'Referral Type: ' + pickListVal.getLabel();
            pickListValuesMap.put(pickListVal.getLabel(), temp);
        }
        return pickListValuesMap;
    }

    @TestVisible
    private Map<Id, Lead> getLeadMap(Set<Id> ids) {
        Map<Id, Lead> sobjMap = new Map<Id, Lead>([SELECT Id, Email FROM Lead WHERE Id IN: ids]);
        return sobjMap;
    }
    
    @TestVisible
    private Map<Id, Opportunity> getOpportunityMap(Set<Id> ids) {
        Map<Id, Opportunity> sobjMap = new Map<Id, Opportunity>([SELECT Id, Primary_Contact__c, Primary_Contact__r.Email FROM Opportunity WHERE Id IN: ids]);
        return sobjMap;
    }

    @TestVisible
    private Map<Id, Transferee_Job__c> getTransfereeMap(Set<Id> ids) {
        Map<Id, Transferee_Job__c> sobjMap = new Map<Id, Transferee_Job__c>([SELECT Id, Opportunity__c, Opportunity__r.Primary_Contact__r.Email FROM Transferee_Job__c WHERE Id IN: ids]);
        return sobjMap;
    }

    //  -------------------------------------------------------------------------
    //  HELPER method: sendTemplatedEmail
    //  -------------------------------------------------------------------------
    // public void sendTemplatedEmail(String[] toRecipients, String[] ccRecipients, Id templateId, ID targetObjId, Id whatId, ID orgWideEmailId, Boolean saveAsActivity, Attachment[] attachList ) {
    public Messaging.SingleEmailMessage sendTemplatedEmail(String[] toRecipients, String[] ccRecipients, Id templateId, ID targetObjId, Id whatId, ID orgWideEmailId, Boolean saveAsActivity, Attachment[] attachList ) {
        //  templateId   must be ID of an Email template
        //  targetObjId must be a Contact, User, Lead Id -- also used in merge fields of template recipient.xxxx
        //  whatId    must be an SObject that is used in the merge fields of the template relatedTo.xxxx
        //  fromId    if non null, use current user, otherwise, use this ID (most likely an org wide no reply id)
        //  bcc      not permitted when using templates
        
        // targetObjId is the Lead or Opportunity__r.Primary_Contact that is on the Partner Referral
        // WhatId is the Partner Referral
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        
        email.setToAddresses(toRecipients);
        email.setCcAddresses(ccRecipients);
        
        // set this to the referral object
        email.setWhatId(whatId);
        email.setorgWideEmailAddressId(orgWideEmailId);
        email.setTemplateId(templateId);
        email.setSaveAsActivity(saveAsActivity);      // save email as activity on the targetObjId (i.e. Contact). Note activity can't be saved on Users
        // if(targetObjId.getSobjectType() == Lead.getSObjectType()) {
            email.setTreatTargetObjectAsRecipient(false);
            email.setTargetObjectId(targetObjId);
        // }
        // else {
            
        // }
        System.debug(LoggingLevel.INFO,'** entered sendTemplatedEmail, to:' + toRecipients + ' cc:' + ccRecipients +  ' templateId:' + templateId + ' tagetObjId:' + targetObjId + 
                        ' whatId:' + whatId + ' orgWideEmailId: ' + orgWideEmailId);
        // try {
        //     Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
        //     return;
        // }
        // catch (EmailException e) {
        //     throw new UtilException('[U-02] sendTemplatedEmail error. ' + e.getMessage());
        // }
        return email;
    }

    class PartnerReferralEmailWrapper {
        List<String> toRecipients { get; set; }
        List<String> ccRecipients { get; set; }
        Messaging.SingleEmailMessage email { get; set; }
        Id templateId { get; set; }
        Id targetObjId { get; set; }
        Id whatId { get; set; }
        Boolean saveAsActivity { get; set; }
        Id partnerReferralId { get; set; }
        PartnerReferralEmailWrapper() {
            toRecipients = new List<String>();
            ccRecipients = new List<String>();
        }
        //ID orgWideEmailId { get; set; }
        //List<Attachment> attachList { get; set; }
    }

    public class UtilException extends Exception{}
}