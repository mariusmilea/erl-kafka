-module(erl_kafka_srv).
-behaviour(gen_server).

-include("producer.hrl").

-define(SERVER, ?MODULE).

%% ------------------------------------------------------------------
%% API Function Exports
%% ------------------------------------------------------------------

-export([start_link/0]).
-export([produce/1]).

%% ------------------------------------------------------------------
%% gen_server Function Exports
%% ------------------------------------------------------------------

-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

%% ------------------------------------------------------------------
%% API Function Definitions
%% ------------------------------------------------------------------

produce(Term) ->
    gen_server:cast(?SERVER, {produce, Term}).

start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%% ------------------------------------------------------------------
%% gen_server Function Definitions
%% ------------------------------------------------------------------

init(Args) ->
    KafkaBrokers = get_kafka_brokers()
    {ok, Producer} = brod:start_link_producer(KafkaBrokers),
    {ok, #state{producer=Producer}}.

get_kafka_brokers() ->
    KafkaBrokers = elibs_application:get_env(erl_kafka, kafka_brokers, []),
    case KafkaBrokers of
        [_|_] ->
            [elibs_types:str(Broker) || Broker <- KafkaBrokers];
        [] ->
            ?WARNING("No brokers specified in application config.", []),
            []
    end.

handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast({produce, Term}, #state{Producer=P} = State) ->
    {ok, _} = brod:produce(),
    {noreply, State};

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% ------------------------------------------------------------------
%% Internal Function Definitions
%% ------------------------------------------------------------------

