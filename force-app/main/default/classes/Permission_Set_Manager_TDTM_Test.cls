/**
 * Created by robertwright on 4/13/21.
 */

@IsTest
private class Permission_Set_Manager_TDTM_Test {
    @IsTest
    static void testBehavior() {
        Permission_Set_Manager_TDTM tdtm = new Permission_Set_Manager_TDTM();
        tdtm.run(new list<User>(),new list<User>(),npsp.TDTM_Runnable.Action.AfterInsert,User.SobjectType.getDescribe(),null);
    }
}