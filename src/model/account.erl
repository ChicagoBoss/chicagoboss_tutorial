-module(account, [Id, Email, PasswordHash]).
-compile(export_all).
-has({messages, many}).

hash_for_password(Password) ->
    PasswordSalt = mochihex:to_hex(erlang:md5(Email)),
    mochihex:to_hex(erlang:md5(PasswordSalt ++ Password)).

check_password(Password) ->
    hash_for_password(Password) =:= PasswordHash.

validation_tests() ->
    [{fun() -> string:chr(Email, $@) > 0 end,
            "Email must contain an @ symbol!"}].
