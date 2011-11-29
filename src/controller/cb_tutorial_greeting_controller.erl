-module(cb_tutorial_greeting_controller, [Req]).
-compile(export_all).

before_(_) ->
    {ok, Req:peer_ip() =:= {127, 0, 0, 1}}.

hello('GET', []) ->
    {ok, [{greeting, "Hello, world!"}]}.

list('GET', [], IsMe) ->
    Greetings = boss_db:find(greeting, []),
    {ok, [{greetings, Greetings}, {is_me, IsMe}]}.

create('GET', []) ->
    ok;
create('POST', []) ->
    GreetingText = Req:post_param("greeting_text"),
    NewGreeting = greeting:new(id, GreetingText),
    case NewGreeting:save() of
        {ok, SavedGreeting} ->
            {redirect, [{action, "list"}]};
        {error, ErrorList} ->
            {ok, [{errors, ErrorList}, {new_msg, NewGreeting}]}
    end.

goodbye('POST', [], true) ->
    boss_db:delete(Req:post_param("greeting_id")),
    {redirect, [{action, "list"}]}.

pull('GET', [LastTimestamp]) ->
    {ok, Timestamp, Greetings} = boss_mq:pull("new-greetings", 
        list_to_integer(LastTimestamp)),
    {json, [{timestamp, Timestamp}, {greetings, Greetings}]}.

live('GET', []) ->
    Greetings = boss_db:find(greeting, []),
    Timestamp = boss_mq:now("new-greetings"),
    {ok, [{greetings, Greetings}, {timestamp, Timestamp}]}.
