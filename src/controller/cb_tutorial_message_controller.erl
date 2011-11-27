-module(cb_tutorial_message_controller, [Req, SessionID]).
-compile(export_all).

before_(_) ->
    case boss_session:get_session_data(SessionID, "account") of
        undefined ->
            {redirect, [{controller, "account"},
                    {action, "login"}]};
        AccountID ->
            {ok, Req:peer_ip() =:= {127, 0, 0, 1}}
    end.

hello('GET', [], IsLocal) ->
    Messages = boss_db:find(message, []),
    {ok, [{messages, Messages}, {is_local, IsLocal}]};
hello('POST', [], IsLocal) ->
    MessageContents = Req:post_param("message_contents"),
    AccountID = boss_session:get_session_data(SessionID, "account"),
    NewMessage = message:new(id, MessageContents, AccountID),
    case NewMessage:save() of
        {ok, SavedMessage} ->
            {redirect, [{action, "hello"}]};
        {error, ErrorList} ->
            {ok, [{errors, ErrorList}, {new_msg, NewMessage}]}
    end.

goodbye('POST', [], true) ->
    boss_db:delete(Req:post_param("message_id")),
    {redirect, [{action, "hello"}]}.

pull('GET', [LastTimestamp]) ->
    {ok, Timestamp, Messages} = boss_mq:pull("new-messages",
        list_to_integer(LastTimestamp)),
    {json, [{timestamp, Timestamp}, {messages, Messages}]}.

live('GET', []) ->
    Messages = boss_db:find(message, []),
    Timestamp = boss_mq:now("new-messages"),
    {ok, [{messages, Messages}, {timestamp, Timestamp}]}.
