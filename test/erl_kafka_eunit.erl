-module(erl_kafka_eunit).
-include_lib("eunit/include/eunit.hrl").
-include_lib("erlanglibs/include/logging.hrl").

-compile(export_all).

load_brod_test_() ->
   {setup,
    fun() ->
        meck:new(brod),
        meck:expect(brod, start_link_producer, fun(_) -> ok end),
	[]
    end,
    fun(_) ->
        meck:unload(rmq_test_client),
        meck:unload(amqp_channel)
    end,
    fun(_) ->
		RunningApps=application:which_applications(),	
		case lists:keyfind(brod, 1, L) of
			{_,_,_} ->
				true;
			false ->
				false
		end,
		[
			?_assert(Ret)
		]
    end
}. 