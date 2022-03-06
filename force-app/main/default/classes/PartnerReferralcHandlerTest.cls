@IsTest
public with sharing class PartnerReferralcHandlerTest {
    
    static List<String> testNames {get;set;}
    
    @TestSetup
    static void testSetup(){
        
        Account acc1 = createTestAccount('Roommates');
        Account acc2 = createTestAccount('Rental_Assistance');
        Account acc3 = createTestAccount('Temp_Housing');
        List<Account> accList = new List<Account>{acc1, acc2, acc3};
        insert accList;

        Contact con11 = createTestContact(acc1.Id, true);
        Contact con12 = createTestContact(acc1.Id, true);
        Contact con13 = createTestContact(acc1.Id, true);

        Contact con21 = createTestContact(acc2.Id, true);
        Contact con22 = createTestContact(acc2.Id, false);
        Contact con23 = createTestContact(acc2.Id, true);

        Contact con31 = createTestContact(acc3.Id, true);
        Contact con32 = createTestContact(acc3.Id, false);
        Contact con33 = createTestContact(acc3.Id, false);
        List<Contact> conList = new List<Contact>{con11, con12, con13, con21, con22, con23, con31, con32, con33};
        insert conList;

        Lead ld1 = createTestLead();
        Lead ld2 = createTestLead();
        Lead ld3 = createTestLead();
        Lead ld4 = createTestLead();
        Lead ld5 = createTestLead();
        Lead ld6 = createTestLead();
        Lead ld7 = createTestLead();
        Lead ld8 = createTestLead();
        Lead ld9 = createTestLead();
        List<Lead> ldList = new List<Lead>{ld1, ld2, ld3, ld4, ld5, ld6, ld7, ld8, ld9};
        insert ldList;

        Opportunity opp1 = createTestOpportunity(acc1.Id, con11.Id);
        Opportunity opp2 = createTestOpportunity(acc1.Id, con12.Id);
        Opportunity opp3 = createTestOpportunity(acc1.Id, con13.Id);

        Opportunity opp4 = createTestOpportunity(acc2.Id, con21.Id);
        Opportunity opp5 = createTestOpportunity(acc2.Id, con22.Id);
        Opportunity opp6 = createTestOpportunity(acc2.Id, con23.Id);

        Opportunity opp7 = createTestOpportunity(acc3.Id, con31.Id);
        Opportunity opp8 = createTestOpportunity(acc3.Id, con32.Id);
        Opportunity opp9 = createTestOpportunity(acc3.Id, con33.Id);
        List<Opportunity> oppList = new List<Opportunity>{opp1, opp2, opp3, opp4, opp5, opp6, opp7, opp8, opp9};
        insert oppList;

    }
    
    @IsTest
    static void endToEnd(){
        EDHU.TriggerPanel.setMainBreaker(false);
        createPartnerReferralsFromTestSetup();
        EDHU.TriggerPanel.setMainBreaker(true);

        PartnerReferralcHandler handler = new PartnerReferralcHandler();
        List<Partner_Referral__c> refList = [SELECT Name, Account__c, Lead__c, Opportunity__c, 
                                                    Referral_Email_Sent__c, Referral_Type_Filter__c, Referral_Method__c,
                                                    Transferee_Job__c
                                             FROM Partner_Referral__c
                                            ];
        System.debug('refList.size: ' + refList.size());
        
        Test.startTest();
        handler.afterInsert(refList);
        handler.afterUpdate(refList, null);
        Test.stopTest();
        
        List<Partner_Referral__c> updatedRefList = [SELECT Name, Account__c, Account__r.Name, Lead__c, Opportunity__c, 
                                                           Referral_Email_Sent__c, Referral_Type_Filter__c,
                                                           Transferee_Job__c
                                                    FROM Partner_Referral__c
                                                   ];
        System.debug('updatedRefList: ' + updatedRefList);
        for(Partner_Referral__c ref : updatedRefList) {
            System.debug('Name: ' + ref.Account__r.Name);
            System.debug('Email sent: ' + ref.Referral_Email_Sent__c);
            System.assertEquals(true, ref.Referral_Email_Sent__c);
        }
    }
/*
    @IsTest
    static void getAccIdFromReferralsTest(){
        PartnerReferralcHandler handler = new PartnerReferralcHandler();
        List<Partner_Referral__c> refList = [SELECT Name, Account__c, Lead__c, Opportunity__c, 
                                                    Referral_Email_Sent__c, Referral_Type_Filter__c,
                                                    Transferee_Job__c
                                             FROM Partner_Referral__c
                                            ];
        Test.startTest();
            handler.getAccIdFromReferrals(refList);
        Test.stopTest();
    }
    
    @IsTest
    static void getOppIdFromReferralsTest(){
        PartnerReferralcHandler handler = new PartnerReferralcHandler();
        List<Partner_Referral__c> refList = [SELECT Name, Account__c, Lead__c, Opportunity__c, 
                                                    Referral_Email_Sent__c, Referral_Type_Filter__c,
                                                    Transferee_Job__c
                                             FROM Partner_Referral__c
                                            ];
        Test.startTest();
            handler.getOppIdFromReferrals(refList);
        Test.stopTest();
    }

    @IsTest
    static void getLeadIdFromReferralsTest(){
        PartnerReferralcHandler handler = new PartnerReferralcHandler();
        List<Partner_Referral__c> refList = [SELECT Name, Account__c, Lead__c, Opportunity__c, 
                                                    Referral_Email_Sent__c, Referral_Type_Filter__c,
                                                    Transferee_Job__c
                                             FROM Partner_Referral__c
                                            ];
        Test.startTest();
            handler.getLeadIdFromReferrals(refList);
        Test.stopTest();
    }
*/

/**********************************************************
***********************************************************
***********************************************************
***********************************************************
***********************************************************
************ UTILITY METHODS TO HELP WITH TESTS ***********
***********************************************************
***********************************************************
***********************************************************
***********************************************************
**********************************************************/

    private static Map<Id, List<Contact>> getConMap() {
        List<Contact> conList = [SELECT Id, AccountId FROM Contact];
        Map<Id, List<Contact>> conMap = new Map<Id, List<Contact>>();

        for (Contact con : conList) {
            if( !conMap.containsKey(con.AccountId) ) {
                conMap.put(con.AccountId, new List<Contact>());
            }

            conMap.get(con.AccountId).add(con);
        }

        return conMap;
    }

    private static List<Lead> getLeadList() {
        return [SELECT Id FROM Lead];
    }

    private static Map<Id, List<Opportunity>> getOppMap() {
        List<Opportunity> oppList = [SELECT Id, AccountId FROM Opportunity];
        Map<Id, List<Opportunity>> oppMap = new Map<Id, List<Opportunity>>();

        for (Opportunity opp : oppList) {
            if( !oppMap.containsKey(opp.AccountId) ) {
                oppMap.put(opp.AccountId, new List<Opportunity>());
            }

            oppMap.get(opp.AccountId).add(opp);
        }

        return oppMap;
    }

    private static List<partner_Referral__c> createPartnerReferralsFromTestSetup() {
        List<Account> accList = [SELECT Id FROM Account];
        Map<Id, List<Contact>> conMap = getConMap();
        List<Lead> ldList = getLeadList();
        Map<Id, List<Opportunity>> oppMap = getOppMap();


        List<Partner_Referral__c> partnerRefList = new List<Partner_Referral__c>();
        for (Integer i = 0; i < 1; i++) {
            Partner_Referral__c ref = createTestPartnerReferral(accList[0].Id, ldList[i].id, null, false, 'Roommates');
            partnerRefList.add(ref);
        }

        for (Integer i = 0; i < 1; i++) {
            List<Opportunity> oppList = oppMap.get(accList[1].Id);
            Partner_Referral__c ref = createTestPartnerReferral(accList[1].Id, null, oppList[i].Id, false, 'Rental_Assistance');
            partnerRefList.add(ref);
        }

        for (Integer i = 0; i < 1; i++) {
            List<Opportunity> oppList = oppMap.get(accList[2].Id);

            Partner_Referral__c ref = createTestPartnerReferral(accList[2].Id, Math.mod(i,2) == 0 ? ldList[i].id : null,  Math.mod(i,2) != 0 ? oppList[i].id : null,  Math.mod(i,3) == 0 ? true : false, 'Temp_Housing');
            partnerRefList.add(ref);
        }
        insert partnerRefList;
        return partnerRefList;
    }

    private static Account createTestAccount(String referralType) {
        Id recordTypeId = [SELECT Id FROM RecordType WHERE Name = 'Partners' AND SobjectType = 'Account'].Id;
        Integer idx = getRandomIndex();
        Account acc = new Account();
        acc.RecordTypeId = recordTypeId;
        acc.Name = testNames[idx];
        acc.Referral_Type__c = referralType;
        acc.Account_Status__c = 'Active';
        return acc;
    }

    private static Contact createTestContact(Id accId, Boolean setRefContact) {
        Integer idx = getRandomIndex();
        Integer idx2 = getRandomIndex();
        Contact con = new Contact();
        con.LastName = testNames[idx];
        con.Email = testNames[idx] + '@' + testNames[idx2] + '.com';
        con.AccountId = accId;
        con.Referral_Contact__c = setRefContact;
        return con;
    }

    private static Lead createTestLead() {
        Integer idx = getRandomIndex();
        Integer idx2 = getRandomIndex();
        Lead ld = new Lead();
        ld.LastName = testNames[idx];
        ld.Company = idx + ' Company'; 
        ld.Email = testNames[idx] + '@' + testNames[idx2] + '.com';
        return ld;
    }

    private static Opportunity createTestOpportunity(Id accId, Id conId) {
        Integer idx = getRandomIndex();
        Integer idx2 = getRandomIndex();
        Opportunity opp = new Opportunity();
        opp.Name = testNames[idx];
        opp.Alternate_Email__c = testNames[idx] + '@' + testNames[idx2] + '.com';
        opp.AccountId = accId;
        opp.Primary_Contact__c = conId;
        opp.StageName = 'Draft';
        opp.CloseDate = Date.today().addDays(1);
        return opp;
    }

    private static Partner_Referral__c createTestPartnerReferral(Id accId, Id leadId, Id oppId, Boolean refEmailSent, String referralType) {
        Integer idx = getRandomIndex();
        Partner_Referral__c ref = new Partner_Referral__c();
        ref.Name = testNames[idx];
        ref.Account__c = accId;
        ref.Lead__c = leadId;
        ref.Opportunity__c = oppId;
        ref.Referral_Email_Sent__c = refEmailSent;
        ref.Referral_Type_Filter__c = referralType;
        return ref;
    }

    private static Integer getRandomIndex() {
        testNames = new List<String>();
        
        for (Integer i = 0; i < 100; i++) {
            testNames.add('test'+i);
        }
        Double randomNumber = Math.random();
        Integer arraySize = testNames.size();
        Integer randomIndex = (randomNumber *(arraySize-1)).intValue();
        return randomIndex;
    }
}