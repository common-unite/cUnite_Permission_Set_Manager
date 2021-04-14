/**
 * Created by robertwright on 4/13/21.
 */

global with sharing class Permission_Set_Manager_TDTM extends npsp.TDTM_RunnableMutable {

    private static set<npsp.TDTM_Runnable.Action> validActions = new set<npsp.TDTM_Runnable.Action> {
            npsp.TDTM_Runnable.Action.AfterInsert,
            npsp.TDTM_Runnable.Action.AfterUpdate
    };

    global override void run(List<SObject> listNew, List<SObject> listOld,
            npsp.TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult,
            npsp.TDTM_Runnable.DmlWrapper dmlWrapper) {
        if (objResult.SobjectType == User.SobjectType && validActions.contains(triggerAction)) process(listNew);
    }

    @TestVisible
    private static void process(List<SObject> records) {
        map<Id,SObject> recordMap = new Map<Id, SObject>(records);
        if(!test.isRunningTest()) Permission_Set_Manager.syncPermissionSets(recordMap.keySet());
    }
}