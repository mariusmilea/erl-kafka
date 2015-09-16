-module(erl_kafka).
-behaviour(gen_server).

-include_lib("erlanglibs/include/logging.hrl").
-include("producer.hrl").

-define(SERVER, ?MODULE).

%% ------------------------------------------------------------------
%% API Function Exports
%% ------------------------------------------------------------------

-export([start_link/0]).
-export([produce/3, get_kafka_brokers/0]).

%% ------------------------------------------------------------------
%% gen_server Function Exports
%% ------------------------------------------------------------------

-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

-type host()::string().

-export_type([
    host/0
]).

%% ------------------------------------------------------------------
%% API Function Definitions
%% ------------------------------------------------------------------

%% @doc
%% Generates a Kafka message for a given topic.
%% The message is a key value pair.
-spec produce(Topic::binary(), [{Key::binary(), Value::binary()}], Partition::integer()) -> {ok}.
%% @end
produce(Topic, Data, Partition) ->
    gen_server:cast(?SERVER, {produce, Topic, Data, Partition}).

%% @private
%% @doc Starts this gen_server.
%% To be called from the supervisor.
-spec start_link() -> {ok, pid()}.
%% @end
start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%% ------------------------------------------------------------------
%% gen_server Function Definitions
%% ------------------------------------------------------------------

-spec init(_) -> {ok, #state{}}.
init(_) ->
    KafkaBrokers = get_kafka_brokers(),
    {ok, Producer} = brod:start_link_producer(KafkaBrokers),
    {ok, #state{producer=Producer}}.

%% @doc Returns all the Kafka brokers in the configuration as a array of strings
-spec get_kafka_brokers() -> [host()].
%% @end
get_kafka_brokers() ->
    KafkaBrokers = elibs_application:get_env(erl_kafka, kafka_brokers, []),
    case KafkaBrokers of
        [_|_] ->
            [{elibs_types:str(Broker), 6667} || Broker <- KafkaBrokers];
        [] ->
            ?WARNING("No brokers specified in application config.", []),
            []
    end.

%% @doc
%% Not used but required by gen_server.
-spec handle_call(term(), {pid(), term()}, #state{}) -> {noreply, #state{}}.
%% @end
handle_call(_Request, _From, State) ->
    {reply, ok, State}.

%% @doc
%% Handles the connection functionality.
-spec handle_cast(term(), #state{}) -> {noreply, #state{}}.
%% @end
handle_cast({produce, Topic, Data, Partition}, #state{producer=P} = State) ->
    {ok, _} = brod:produce(P, Topic, Partition, [{Topic, Data}]),
    {noreply, State};

handle_cast(_Msg, State) ->
    {noreply, State}.

%% @doc
%% Function that handles the Kafka messages.
-spec handle_info(term(), #state{}) -> {noreply, #state{}}.
%% @end
handle_info(_Info, State) ->
    {noreply, State}.

%% @doc
%% Close Kafka connection.
-spec terminate(term(), #state{}) -> ok.
%% @end
terminate(_Reason, _State) ->
    ok.

%% @doc
%% Not used but required by gen_server.
-spec code_change(term(), #state{}, term()) -> {ok, #state{}}.
%% @end
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% ------------------------------------------------------------------
%% Internal Function Definitions
%% ------------------------------------------------------------------

