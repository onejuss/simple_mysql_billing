#include <sourcemod>
#define PLUGIN_VERSION    "2.0"

public Plugin:myinfo = {
    name = "Mysql_Simple_Billing",
    author = "juss",
    description = "[ANY] MySQL-T check if client's steam id in DB",
    version = PLUGIN_VERSION,
    url = "rullers.ru"
};

new Handle:db;
new g_RowID[MAXPLAYERS + 1] = {-1, ...};

public OnPluginStart()
{
    new String:error[512];

    db = SQL_Connect("mysql_simple_billing", true, error, sizeof(error));

    if(db == INVALID_HANDLE)
    {
        SetFailState(error);
    }

}

public OnClientPostAdminCheck(client)
{
    if(IsFakeClient(client)) return;


    if(CheckCommandAccess(client, "sm_rcon", ADMFLAG_RCON)) return;


    new String:query[512];
    new String:auth[50];
    GetClientAuthId(client, AuthId_Engine, auth, sizeof(auth));

    Format(query, sizeof(query), "SELECT steamid FROM billing WHERE steamid='%s'", auth);


    new Transaction:txn = SQL_CreateTransaction();
    SQL_AddQuery(txn, query, 1); // First query, does steamid exist in database.table

    Format(query, sizeof(query), "SELECT expire_date FROM billing WHERE steamid='%s' AND expire_date >= DATE(now())", auth);
    SQL_AddQuery(txn, query, 2); // Second query, get fresh records by steamid

    Format(query, sizeof(query), "SELECT expire_date FROM billing WHERE steamid='%s' AND expire_date < DATE(now())", auth);
    SQL_AddQuery(txn, query, 3); // Third query, get old records

    Format(query, sizeof(query), "SELECT expire_date FROM billing WHERE steamid='%s' AND expire_date IS NOT NULL", auth);
    SQL_AddQuery(txn, query, 4); // Third query, get old records

    SQL_ExecuteTransaction(db, txn, onSuccess, onError, GetClientUserId(client));


}

public onSuccess(Database database, any data, int numQueries, Handle[] results, any[] queryData)
{
    new client = GetClientOfUserId(data);

    if(client == 0) return;

    if(numQueries <= 0) KickClient(client, "Something went wrong...");

    new String:buffer[512];

    for(new i = 0; i < numQueries; i++)
    {
        if(queryData[i] == 1 && !SQL_FetchRow(results[i])) // steamid not found
        {
            // inserting steam_id to database (and give any new player free 30 day subscription)
            decl String:query[255], String:steamid[32];
            GetClientAuthId(client, AuthId_Steam2,  steamid, sizeof(steamid) );
            new userid = GetClientUserId(client);
            Format(query, sizeof(query), "INSERT INTO billing (steamid, expire_date, joind_dt) VALUES ('%s',NOW() + INTERVAL 30 DAY,CURRENT_TIMESTAMP)", steamid);
          	SQL_TQuery(db, OnRowInserted, query, userid);
            /*KickClient(client, "Welcome! This is a privet server, in order to play you have to subscribe http://yoursite.com");*/
            PrintToChat(client, "Welcome! This is a privet server, in order to play you have to subscribe at http://yoursite.com");
            PrintToChat(client, "We give you 30 day free subscription, your free subscription will end at %s", buffer);
            break;
        }

        if(queryData[i] == 2 && SQL_FetchRow(results[i])) // Fresh records found
        {
            // break loop to not continue next query results.
            //SQL_FetchString(results[i], 0, buffer, sizeof(buffer));
            //PrintToServer("- %s", buffer);
            break;
        }

        if(queryData[i] == 3 && SQL_FetchRow(results[i])) // Old records found
        {
            SQL_FetchString(results[i], 0, buffer, sizeof(buffer));
            KickClient(client, "Sorry, your Subscriptions is ended %s http://yoursite.com", buffer);
            break;
        }

        if(queryData[i] == 4 && !SQL_FetchRow(results[i])) // steamid found, but expire_date of subscrbtion is NULL
        {
            KickClient(client, "Welcome!!! This is a privet server, in order to play you have to subscribe http://yoursite.com");
            break;
        }
    }
}

public onError(Database database, any data, int numQueries, const char[] error, int failIndex, any[] queryData)
{
    PrintToServer("onError");
}

public OnRowInserted(Handle:owner, Handle:hndl, const String:error[], any:userid) {
	new client = GetClientOfUserId(userid);
	if(client == 0) {
		return;
	}
	
	if(hndl == INVALID_HANDLE) {
		LogError("Unable to insert row for client %L. %s", client, error);
		return;
	}
	
	g_RowID[client] = SQL_GetInsertId(hndl);
	
	new Handle:fwd = CreateGlobalForward("PA_OnConnectionLogged", ET_Ignore, Param_Cell, Param_Cell);
	Call_StartForward(fwd);
	Call_PushCell(client);
	Call_PushCell(g_RowID[client]);
	Call_Finish();
	CloseHandle(fwd);
}
