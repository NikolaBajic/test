trigger PartnerReferralTrigger on Partner_Referral__c (
    before insert, before update,  before delete,
    after insert,  after update,   after delete,   after undelete) {

    //Initialize the handler
    EDHU.SObjectHandler handler = EDHU.SObjectDispatcher.init('PartnerReferralc');

    //Execute the appropriate dispatch method.
    if(handler != null){ handler.execute(Trigger.operationType, Trigger.new, Trigger.oldMap); }

}