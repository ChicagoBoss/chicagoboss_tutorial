-module(message, [Id, MessageContents, AccountId]).
-compile(export_all).
-belongs_to(account).

validation_tests() ->
    [{fun() -> length(MessageContents) > 0 end,
            "Message must be non-empty!"},
        {fun() -> length(MessageContents) =< 140 end,
            "Message must be 140 characters or fewer!"}].
