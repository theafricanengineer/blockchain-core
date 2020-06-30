%%%-------------------------------------------------------------------
%% @doc
%% == Blockchain Transaction Genesis Price Oracle ==
%% @end
%%%-------------------------------------------------------------------
-module(blockchain_txn_gen_price_oracle_v1).

-behavior(blockchain_txn).
-behavior(blockchain_json).
-include("blockchain_json.hrl").

-include("blockchain_utils.hrl").
-include_lib("helium_proto/include/blockchain_txn_gen_price_oracle_v1_pb.hrl").

-export([
    new/1,
    hash/1,
    sign/2,
    price/1,
    fee/1,
    is_valid/2,
    absorb/2,
    print/1,
    to_json/2
]).

-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").
-endif.

-type txn_genesis_price_oracle() :: #blockchain_txn_gen_price_oracle_v1{}.
-export_type([txn_genesis_price_oracle/0]).

%%--------------------------------------------------------------------
%% @doc
%% Create a new genesis price oracle transaction
%% @end
%%--------------------------------------------------------------------
-spec new(Price :: pos_integer()) -> txn_genesis_price_oracle().
new(Price) ->
    #blockchain_txn_gen_price_oracle_v1_pb{price=Price}.

%%--------------------------------------------------------------------
%% @doc
%% Return the sha256 hash of this transaction
%% @end
%%--------------------------------------------------------------------
-spec hash(txn_genesis_price_oracle()) -> blockchain_txn:hash().
hash(Txn) ->
    EncodedTxn = blockchain_txn_gen_gateway_v1_pb:encode_msg(Txn),
    crypto:hash(sha256, EncodedTxn).

%%--------------------------------------------------------------------
%% @doc
%% Sign this transaction. (This is a no-op for this transaction
%% type. It's only valid at genesis block)
%% @end
%%--------------------------------------------------------------------
-spec sign(txn_genesis_price_oracle(), libp2p_crypto:sig_fun()) -> txn_genesis_price_oracle().
sign(Txn, _SigFun) ->
    Txn.

%%--------------------------------------------------------------------
%% @doc
%% Return the price of this transaction
%% @end
%%--------------------------------------------------------------------
-spec price(txn_genesis_price_oracle()) -> pos_integer().
price(Txn) ->
    Txn#blockchain_txn_gen_price_oracle_v1_pb.price.

%%--------------------------------------------------------------------
%% @doc
%% @end
%%--------------------------------------------------------------------
-spec fee(txn_genesis_price_oracle()) -> non_neg_integer().
fee(_Txn) ->
    0.

%%--------------------------------------------------------------------
%% @doc
%% This transaction should only be absorbed when it's in the genesis block
%% @end
%%--------------------------------------------------------------------
-spec is_valid(txn_genesis_price_oracle(), blockchain:blockchain()) -> ok | {error, any()}.
is_valid(_Txn, Chain) ->
    Ledger = blockchain:ledger(Chain),
    case blockchain_ledger_v1:current_height(Ledger) of
        {ok, 0} ->
            ok;
        _ ->
            {error, not_in_genesis_block}
    end.

%%--------------------------------------------------------------------
%% @doc
%% @end
%%--------------------------------------------------------------------
-spec absorb(txn_genesis_price_oracle(), blockchain:blockchain()) -> ok | {error, not_in_genesis_block}.
absorb(Txn, Chain) ->
    Ledger = blockchain:ledger(Chain),
    Price = ?MODULE:price(Txn),
    blockchain_ledger_v1:set_oracle_price(Price, Ledger).

%%--------------------------------------------------------------------
%% @doc
%% @end
%%--------------------------------------------------------------------
-spec print(txn_genesis_price_oracle()) -> iodata().
print(undefined) -> <<"type=genesis_price_oracle, undefined">>;
print(#blockchain_txn_gen_price_oracle_v1_pb{price=P}) ->
    io_lib:format("type=genesis_price_oracle price=~p", [P]).

-spec to_json(txn_genesis_price_oracle(), blockchain_json:opts()) -> blockchain_json:json_object().
to_json(Txn, _Opts) ->
    #{
      type => <<"gen_price_oracle_v1">>,
      hash => ?BIN_TO_B64(hash(Txn)),
      price => price(Txn)
     }.


%% ------------------------------------------------------------------
%% EUNIT Tests
%% ------------------------------------------------------------------
-ifdef(TEST).

new_test() ->
    Tx = #blockchain_txn_gen_gateway_v1_pb{gateway = <<"0">>,
                                           owner = <<"1">>,
                                           location = h3:to_string(?TEST_LOCATION),
                                           nonce=10},
    ?assertEqual(Tx, new(<<"0">>, <<"1">>, ?TEST_LOCATION, 10)).

price_test() ->
    Tx = new(10),
    ?assertEqual(10, price(Tx)).

json_test() ->
    Tx = new(10),
    Json = to_json(Tx, []),
    ?assert(lists:all(fun(K) -> maps:is_key(K, Json) end,
                      [type, hash, price])).


-endif.