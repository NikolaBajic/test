public without sharing class LeadUtility {
    public LeadUtility() {

    }

    public static String SendSurveybotMessages(String leadId) {
        String results = 'Email: ' + SendSurveybotEmail(leadId);
        results += '  SMS: ' + SendSurveybotSMS(leadId);
        
        return results;
    }

    public static String SendSurveybotEmail(String leadId) {
        Lead l = [SELECT Current_Template_For_Email__c, SurveyBot_GUID__c, Owner.Email FROM Lead WHERE Id =: leadId];

        List<EmailTemplate> templates = [SELECT Id, Name, DeveloperName 
            FROM EmailTemplate WHERE Name =: l.Current_Template_For_Email__c];

        if (templates.size() < 1)
            return 'Email Template Not Found';

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[]{'invalid@emailaddr.es'};
        mail.setToAddresses(toAddresses);
        mail.setUseSignature(false);
        mail.setSaveAsActivity(false);
        mail.setSenderDisplayName('MMPT');
        mail.setTargetObjectId(leadId);
        mail.setTemplateId(templates[0].Id);
        Messaging.SingleEmailMessage mail2 = new Messaging.SingleEmailMessage();

        String mailTextBody;
        String mailHtmlBody;
        String mailSubject;

        // Savepoint sp = Database.setSavepoint();
        try {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail, mail2});
        }
        catch (Exception e) {
            mailTextBody = mail.getPlainTextBody();
            mailHtmlBody = mail.getHTMLBody();
            mailSubject = mail.getSubject();
        }

        // Database.rollback(sp);

        System.debug(mailTextBody);
        System.debug(mailHtmlBody);
        System.debug(mailSubject);

        return SurveybotCalloutUtility.sendEmailToLead(l.SurveyBot_GUID__c, mailTextBody, mailSubject, l.Owner.Email);

    }

    public static String SendSurveybotSMS(String leadId) {
        Lead l = [SELECT Current_Template_For_SMS__c, SurveyBot_GUID__c, Owner.Email FROM Lead WHERE Id =: leadId];

        List<EmailTemplate> templates = [SELECT Id, Name, DeveloperName 
            FROM EmailTemplate WHERE Name =: l.Current_Template_For_SMS__c];

        if (templates.size() < 1)
            return 'SMS Template Not Found';

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[]{'invalid@emailaddr.es'};
        mail.setToAddresses(toAddresses);
        mail.setUseSignature(false);
        mail.setSaveAsActivity(false);
        mail.setSenderDisplayName('MMPT');
        mail.setTargetObjectId(leadId);
        mail.setTemplateId(templates[0].Id);
        Messaging.SingleEmailMessage mail2 = new Messaging.SingleEmailMessage();

        String mailTextBody;
        String mailHtmlBody;

        // Savepoint sp = Database.setSavepoint();
        try {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail, mail2});
        }
        catch (Exception e) {
            mailTextBody = mail.getPlainTextBody();
            mailHtmlBody = mail.getHTMLBody();
        }

        // Database.rollback(sp);

        System.debug(mailTextBody);
        System.debug(mailHtmlBody);

        return SurveybotCalloutUtility.sendSMSToLead(l.SurveyBot_GUID__c, mailTextBody, l.Owner.Email);

    }
}