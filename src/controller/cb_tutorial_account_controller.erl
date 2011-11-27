-module(cb_tutorial_account_controller, [Req, SessionID]).
-compile(export_all).

login('GET', []) ->
    {ok, [{redirect, Req:header(referer)}]};
login('POST', []) ->
    Email = Req:post_param("email"),
    Password = Req:post_param("password"),
    Redirect = Req:post_param("redirect"),
    Result = case boss_db:find(account, [email = Email]) of
        [Account] ->
            case Account:check_password(Password) of
                true ->
                    boss_session:set_session_data(SessionID,
                                                  "account",
                                                  Account:id()),
                    true;
                false -> false
            end;
         _ -> false
    end,
    case Result of
        true -> {redirect, Req:post_param("redirect")};
        false ->
            {ok, [{redirect, Redirect}, {email, Email},
              {errors, ["Invalid email/password combination"]}]}
    end.

logout('GET', []) ->
    boss_session:remove_session_data(SessionID, "account"),
    {redirect, "/"}.

create('GET', []) ->
    ok;
create('POST', []) ->
    Email = Req:post_param("email"),
    Password1 = Req:post_param("password1"),
    Password2 = Req:post_param("password2"),
    ValidationTests = [{length(Password1) >= 6, 
            "Password must be at least 6 characters!"},
         {Password1 =:= Password2,
            "Passwords didn't match!"},
         {boss_db:count(account, [email = Email]) =:= 0,
            "An account with that email exists"}],
    ValidationFailures = lists:foldr(fun
            ({true, _}, Acc) -> Acc;
            ({false, Message}, Acc) -> [Message|Acc]
        end, [], ValidationTests),
    Account = boss_record:new(account, [{email, Email}]),
    ErrorList = case ValidationFailures of
        [] ->
            PasswordHash = Account:hash_for_password(Password1),
            Account1 = Account:set(password_hash, PasswordHash),
            case Account1:save() of
                {ok, SavedAccount} ->
                    boss_session:set_session_data(SessionID,
                        "account", SavedAccount:id()),
                    [];
                {error, List} -> List
             end;
        _ -> ValidationFailures
    end,
    case ErrorList of
        [] -> {redirect, [{controller, "message"},
                  {action, "hello"}]};
        _ -> {ok, [{errors, ErrorList}, {account, Account}]}
    end.

view('GET', [Id]) ->
    Account = boss_db:find(Id),
    {ok, [{account, Account}]}.
