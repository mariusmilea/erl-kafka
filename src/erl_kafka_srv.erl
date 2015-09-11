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
    Hosts = [{"172.17.4.253", 9092}],
    {ok, Producer} = brod:start_link_producer(Hosts),
    {ok, #state{producer=Producer}}.

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

