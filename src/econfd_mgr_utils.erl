-module(econfd_mgr_utils).

-export([take_values/2]).

take_values(DefaultList, List) ->
  take_values([], DefaultList, List).

take_values(Result, [], List) ->
  lists:reverse(Result, List);

take_values(Result, [{Key, Default} | DefaultList], List) ->
  case lists:keytake(Key, 1, List) of
      false ->
          take_values([Default | Result], DefaultList, List);
      {value, {Key, Value}, RemainingList} ->
          take_values([Value | Result], DefaultList, RemainingList)
  end.
