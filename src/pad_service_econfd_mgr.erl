-module(pad_service_econfd_mgr).
-behaviour(cloudi_service).

%% cloudi_service callbacks
-export([cloudi_service_init/4,
         cloudi_service_handle_request/11,
         cloudi_service_handle_info/3,
         cloudi_service_terminate/3]).

-include_lib("cloudi_core/include/cloudi_logger.hrl").

-record(state,
  {
  }).

-define(DAEMON_NAME_DEFAULT, <<"econfd_daemon_default">>).
-define(ECONFD_DAEMON_PREFIX_FMT, "/econfd/daemons/~s/").

cloudi_service_init(_Args, _Prefix, _Timeout, Dispatcher) ->
  cloudi_service:subscribe(Dispatcher, "status/get"),
  cloudi_service:subscribe(Dispatcher, "daemons/add/post"),
  {ok, #state{}}.

cloudi_service_handle_request(_RequestType, "/econfd/mgr/daemons/add/post", _Pattern,
                              _RequestInfo, Request,
                              _Timeout, _Priority, _TransId, _Pid,
                              #state{} = State, _Dispatcher) ->

  ?LOG_DEBUG("Request ~p", [Request]),

  ServiceModule = 'pad_service_econfd_daemon',

  Return =
  try cloudi_x_jsx:decode(Request, [{return_maps, false}]) of
    Decoded ->
      Name = erlang:binary_to_atom(proplists:get_value(<<"name">>, Decoded, ?DAEMON_NAME_DEFAULT), utf8),
      ServicePrefix = lists:flatten(io_lib:format(?ECONFD_DAEMON_PREFIX_FMT, [Name])),

      case get_service(ServicePrefix) of
        [] ->
          EconfdDaemonServiceConfig = [{type, internal},
                                       {prefix, ServicePrefix},
                                       {module, ServiceModule},
                                       {args, Decoded}],
          {ok, [ServiceId]} = cloudi_service_api:services_add([EconfdDaemonServiceConfig], infinity),
          ?LOG_WARN("Adding service ~s: ~s.", [ServicePrefix, ServiceId]),
          cloudi_x_uuid:uuid_to_string(ServiceId, nodash);
        [{ServicePrefix, ServiceId}] ->
          ?LOG_WARN("Service ~s exists: ~s.", [ServicePrefix, ServiceId]),
          <<"service already exists\n">>
      end
  catch
    _:_ ->
      <<"invalid parameters">>
  end,

  {reply, Return, State};

cloudi_service_handle_request(_RequestType, _Name, _Pattern,
                              _RequestInfo, _Request,
                              _Timeout, _Priority,
                              _TransId, _Pid,
                              #state{} = State, _Dispatcher) ->
    Response = cloudi_x_jsx:encode([{<<"status">>, <<"ok">>}]),
    {reply, Response, State}.

cloudi_service_handle_info(Request, State, _Dispatcher) ->
    ?LOG_WARN("Unknown info \"~p\"", [Request]),
    {noreply, State}.

cloudi_service_terminate(_Reason, _Timeout, #state{}) ->
    ok.

get_service(Prefix) ->
  {ok, Services} = cloudi_service_api:services_status([], 1000),
  L = lists:map(fun({ServiceId, Params}) ->
                  case lists:keyfind(prefix, 1, Params) of
                      {prefix, Prefix} -> {Prefix, ServiceId};
                      _ -> []
                  end
              end,
              Services),
  lists:flatten(L).

%% cloudit test

% data = '{ \
%   "subscriptions": [ \
%     "get_state/get", \
%     "stop/post" \
%   ], \
%   "ip": "172.26.0.3", \
%   "port": 4565, \
%   "name": "econfd_daemon_cloudi", \
%   "callpoint": "default_cp", \
%   "callback_module": "pad_service_econfd_daemon", \
%   "args": [] \
% }'

% cloudit.post("econfd/mgr/daemons/add", data)