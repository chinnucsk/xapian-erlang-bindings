%% This module is a `gen_server' that handles a single port connection.
-module(xapian_server_tests).
-include_lib("xapian/include/xapian.hrl").
-include_lib("xapian/src/xapian.hrl").
-compile([export_all]).

%% Used for testing, then can be moved to an another file
-define(SRV, xapian_server).

%% ------------------------------------------------------------------
%% Tests
%% ------------------------------------------------------------------

-ifdef(TEST).
-include_lib("proper/include/proper.hrl").
-include_lib("eunit/include/eunit.hrl").

-record(document, {docid}).
    

%% ------------------------------------------------------------------
%% Call C++ tests
%% ------------------------------------------------------------------
    
%% @doc Check basic memory operations (malloc, free).
memory_test() ->
    {ok, Server} = ?SRV:open([], []),
    ?SRV:internal_test_run(Server, memory, []),
    ?SRV:close(Server),
    ok.
    

echo_test() ->
    {ok, Server} = ?SRV:open([], []),
    ?assertEqual(?SRV:internal_test_run(Server, echo, <<0,5>>), <<0,5>>),
    Bin = list_to_binary(lists:duplicate(1100, 1)),
    ?assertEqual(?SRV:internal_test_run(Server, echo, Bin), Bin),
    ok.


-define(DOCUMENT_ID(X), X:32/native-unsigned-integer).
    
%% @doc This test checks the work of `ResultEncoder'.
result_encoder_test() ->
    {ok, Server} = ?SRV:open([], []),
    Reply = ?SRV:internal_test_run(Server, result_encoder, [1, 1000]),
    Reply = ?SRV:internal_test_run(Server, result_encoder, [1, 1000]),
    Reply = ?SRV:internal_test_run(Server, result_encoder, [1, 1000]),
    ?SRV:close(Server),
    ?assertEqual(lists:seq(1, 1000), [ Id || <<?DOCUMENT_ID(Id)>> <= Reply ]),
    ok.
    

%% @doc Check an exception.
exception_test() ->
    {ok, Server} = ?SRV:open([], []),
    % ?assertException(ClassPattern, TermPattern, Expr)
    ?assertException(error, 
        #x_error{type = <<"MemoryAllocationDriverError">>}, 
        ?SRV:internal_test_run(Server, exception, [])),
    ?SRV:close(Server),
    ok.


%% ------------------------------------------------------------------
%% Call test generators
%% ------------------------------------------------------------------

testdb_path(Name) -> 
    io:format(user, "~nTest DB: ~s~n ", [Name]),
	TestDir = filename:join(code:priv_dir(xapian), test_db),
	file:make_dir(TestDir),
	filename:join(TestDir, Name).


wrapper(Name) ->
    [{setup, 
      fun() -> ok end, 
      fun(_) -> [{atom_to_list(Name), ?MODULE:Name()}] end}].


run_test_generators_once_test_() ->
    AllFuns = ?MODULE:module_info(exports),
    [wrapper(Name) || {Name, Arity} <- AllFuns, 
                       Arity =:= 0, 
                       lists:suffix("_gen", atom_to_list(Name))].


%% This test tries to create a document with all kinds of fields.
simple_gen() ->
    % Open test
    Path = testdb_path(simple),
    Params = [write, create, overwrite, 
        #x_value_name{slot = 1, name = slot1}, 
        #x_prefix_name{name = author, prefix = <<$A>>}],
    Document =
        [ #x_stemmer{language = <<"english">>}
        , #x_data{value = "My test data as iolist"} 
        %% It is a term without a position.
        , #x_term{value = "Simple"} 
        %% Posting (a term with a position).
        , #x_term{value = "term", position=1} 
        , #x_value{slot = 0, value = "Slot #0"} 
        , #x_value{slot = slot1, value = "Slot #1"} 
        , #x_text{value = "Paragraph 1"} 
        , #x_delta{}
        , #x_text{value = <<"Paragraph 2">>} 
        , #x_text{value = <<"Michael">>, prefix = author} 
        ],
    {ok, Server} = ?SRV:open(Path, Params),
    try
        DocId = ?SRV:add_document(Server, Document),
        DocIdReplaced1 = ?SRV:replace_document(Server, DocId, Document),
        DocIdReplaced2 = ?SRV:replace_document(Server, "Simple", Document),

        ?SRV:delete_document(Server, DocId),
        ?SRV:delete_document(Server, "Simple"),

        [ ?_assert(is_integer(DocId))
        , ?_assertEqual(DocId, DocIdReplaced1)
        , ?_assertEqual(DocId, DocIdReplaced2)
        ]
    after
        ?SRV:close(Server)
    end.


last_document_id_gen() ->
    % Open test
    Path = testdb_path(last_docid),
    Params = [write, create, overwrite],
    Document = [],
    {ok, Server} = ?SRV:open(Path, Params),
    try
        %% The DB is empty.
        NoId = ?SRV:last_document_id(Server),

        %% Add 1 document, check a last id.
        DocId = ?SRV:add_document(Server, Document),
        Last = ?SRV:last_document_id(Server),

        [ {"Db is empty.", ?_assertEqual(undefined, NoId)}
        , ?_assertEqual(DocId, Last)
        ]
    after
        ?SRV:close(Server)
    end.


update_document_test() ->
    Path = testdb_path(update_document),
    Params = [write, create, overwrite],
    {ok, Server} = ?SRV:open(Path, Params),
    try
        DocId = ?SRV:add_document(Server, []),

        %% The document with DocId will be extended.
        ?SRV:update_document(Server, DocId, [#x_term{value = "more"}]),

        %% Cannot add this term again, because the action is `add'.
        ?assertError(#x_error{type  = <<"BadArgumentDriverError">>}, 
            ?SRV:update_document(Server, DocId, 
                [#x_term{action = add, value = "more", ignore = false}])),

        %% Cannot update the document that is not found.
        ?assertError(#x_error{type  = <<"BadArgumentDriverError">>}, 
            ?SRV:update_document(Server, "fail", [])),

        %% Now we can.
        ?SRV:update_or_create_document(Server, "fail", [])
    after
        ?SRV:close(Server)
    end.
    


frequency_test() ->
    Path = testdb_path(frequency),
    Params = [write, create, overwrite],
    Doc = 
    [ #x_term{value = "term", frequency = {cur, 1}}
    , #x_term{value = "term", frequency = {abs, 5}}
    , #x_term{value = "term", frequency = {cur, -1}}
    ],
    {ok, Server} = ?SRV:open(Path, Params),
    try
        ?SRV:add_document(Server, Doc)
    after
        ?SRV:close(Server)
    end.


term_actions_test() ->
    Path = testdb_path(actions),
    Params = [write, create, overwrite],
    Doc = 
    [ #x_term{action = add,     value = "term"}
    , #x_term{action = update,  value = "term"}
    , #x_term{action = set,     value = "term"}
    ],
    {ok, Server} = ?SRV:open(Path, Params),
    try
        ?SRV:add_document(Server, Doc)
    after
        ?SRV:close(Server)
    end.


-record(term, {value, wdf}).
-record(term_ext, {value, positions, position_count, freq, wdf}).
-record(term_pos, {value, positions, position_count}).
-record(short_term, {wdf}).
-record(spy_term, {value, freq}).


term_qlc_gen() ->
    Path = testdb_path(term_qlc),
    Params = [write, create, overwrite],

    %% Create a document with terms
    TermNames = 
    [erlang:list_to_binary(erlang:integer_to_list(X)) 
        || X <- lists:seq(1, 100)],

    Fields = [#x_term{value = Term} || Term <- TermNames], 

    {ok, Server} = ?SRV:open(Path, Params),
    try
        DocId = ?SRV:add_document(Server, Fields),
        Meta = xapian_term_record:record(term, record_info(fields, term)),
        Table = xapian_term_qlc:document_term_table(Server, DocId, Meta),
        Records = qlc:e(qlc:q([X || X <- Table])),
        Values = [Value || #term{value = Value} <- Records],
        Not1Wdf = [X || X = #term{wdf = Wdf} <- Records, Wdf =/= 1],

        %% Lookup order test.
        %% It is an important test.
        %% Actually, it tests the fact, that skip_to("") move an TermIterator 
        %% in the beginning of the document.
        OrderTestQuery = qlc:q([Value || #term{value = Value} <- Table, 
            Value =:= "2" orelse Value =:= "1" orelse Value =:= "3"]),
        OrderTestValues = qlc:e(OrderTestQuery),
        [ ?_assertEqual(Values, lists:sort(TermNames))
        , ?_assertEqual(Not1Wdf, [])
        , ?_assertEqual(OrderTestValues, [<<"1">>, <<"2">>, <<"3">>])
        ]
    after
        ?SRV:close(Server)
    end.



short_term_qlc_gen() ->
    Path = testdb_path(short_term_qlc),
    Params = [write, create, overwrite],
    %% Create a document with terms
    TermNames = 
    [erlang:list_to_binary(erlang:integer_to_list(X)) 
        || X <- lists:seq(1, 100)],

    Fields = [#x_term{value = Term} || Term <- TermNames], 
    
    {ok, Server} = ?SRV:open(Path, Params),
    try
        DocId = ?SRV:add_document(Server, Fields),
        Meta = xapian_term_record:record(short_term, 
            record_info(fields, short_term)),
        Table = xapian_term_qlc:document_term_table(Server, DocId, Meta),
        Q = qlc:q([Wdf || #short_term{wdf = Wdf} <- Table]),
        WdfSum = qlc:fold(fun erlang:'+'/2, 0, Q),
        [ ?_assertEqual(WdfSum, 100) ]
    after
        ?SRV:close(Server)
    end.


term_ext_qlc_gen() ->
    Path = testdb_path(term_ext_qlc),
    Params = [write, create, overwrite],
    
    %% Create a document with terms
    TermNames = 
    [erlang:list_to_binary(erlang:integer_to_list(X)) 
        || X <- lists:seq(1, 100)],

    Fields = [#x_term{value = Term} || Term <- TermNames], 

    {ok, Server} = ?SRV:open(Path, Params),
    try
        DocId = ?SRV:add_document(Server, Fields),
        Meta = xapian_term_record:record(term_ext, 
                    record_info(fields, term_ext)),
        Table = xapian_term_qlc:document_term_table(Server, DocId, Meta),
        Records = qlc:e(qlc:q([X || X <- Table])),

        Not0Pos = 
        [X || X = #term_ext{position_count = Count} <- Records, Count =/= 0],

        NotEmptyPos = 
        [X || X = #term_ext{positions = Poss} <- Records, Poss =/= []],

        [ ?_assertEqual(Not0Pos, [])
        , ?_assertEqual(NotEmptyPos, [])
        ]
    after
        ?SRV:close(Server)
    end.



term_pos_qlc_gen() ->
    Path = testdb_path(term_pos_qlc),
    Params = [write, create, overwrite],

    Fields = 
    [ #x_term{value = "term1", position = [1,2,3]}
    , #x_term{value = "term2", position = [3,2,1]}
    , #x_term{value = "term3", position = [1]}
    , #x_term{value = "term3", position = [2,3]}
    ], 
    {ok, Server} = ?SRV:open(Path, Params),
    try
        DocId = ?SRV:add_document(Server, Fields),
        Meta = xapian_term_record:record(term_pos, 
                record_info(fields, term_pos)),
        Table = xapian_term_qlc:document_term_table(Server, DocId, Meta),

        Term1Records = 
        qlc:e(qlc:q([X || X = #term_pos{value = <<"term1">>} <- Table])),
        Term2Records = 
        qlc:e(qlc:q([X || X = #term_pos{value = <<"term2">>} <- Table])),
        Term3Records = 
        qlc:e(qlc:q([X || X = #term_pos{value = <<"term3">>} <- Table])),
        AllRecords = 
        qlc:e(qlc:q([X || X <- Table])),
        Term1 = #term_pos{
            value = <<"term1">>, position_count = 3, positions = [1,2,3]},
        Term2 = #term_pos{
            value = <<"term2">>, position_count = 3, positions = [1,2,3]},
        Term3 = #term_pos{
            value = <<"term3">>, position_count = 3, positions = [1,2,3]},

        [ ?_assertEqual([Term1], Term1Records)
        , ?_assertEqual([Term2], Term2Records)
        , ?_assertEqual([Term3], Term3Records)
        , ?_assertEqual(erlang:length(AllRecords), 3)
        ]
    after
        ?SRV:close(Server)
    end.



value_count_match_spy_gen() ->
    Path = testdb_path(value_count_mspy),
    Params = [write, create, overwrite, 
        #x_value_name{slot = 1, name = color}],
    {ok, Server} = ?SRV:open(Path, Params),
    try
        %% There are 2 "green" documents.
        Colors = ["Red", "Blue", "green", "white", "black", "green"],
        [add_color_document(Server, Color) || Color <- Colors],

        SpySlot1 = xapian_match_spy:value_count(Server, color),
        Query = "",
        EnquireResourceId = ?SRV:enquire(Server, Query),
        MSetParams = #x_match_set{
            enquire = EnquireResourceId, 
            spies = [SpySlot1]},
        MSetResourceId = ?SRV:match_set(Server, MSetParams),
        Meta = xapian_term_record:record(spy_term, 
                    record_info(fields, spy_term)),

        %% These elements sorted by value.
        Table = xapian_term_qlc:value_count_match_spy_table(
            Server, SpySlot1, Meta),

        %% These elements sorted by freq.
        TopTable = xapian_term_qlc:top_value_count_match_spy_table(
            Server, SpySlot1, 100, Meta),

        Values = qlc:e(qlc:q([Value || #spy_term{value = Value} <- Table])),

        %% "Red" was converted to <<"Red">> because of lookup function call.
        %% Erlang did not match it, but Xapian did.
        RedValues = qlc:e(qlc:q([Value 
            || #spy_term{value = Value} <- Table, Value =:= "Red"])),

        OrderValues = qlc:e(qlc:q([Value || #spy_term{value = Value} <- Table, 
            Value =:= "white" orelse Value =:= "black"])),

        TopAlphOrderValues = 
        qlc:e(qlc:q([Value || #spy_term{value = Value} <- TopTable, 
            Value =:= "white" orelse Value =:= "black"])),

        TopFreqOrderValues = 
        qlc:e(qlc:q([Value || #spy_term{value = Value} <- TopTable, 
            Value =:= "white" orelse Value =:= "green"])),

        [ ?_assertEqual(Values, 
            [<<"Blue">>, <<"Red">>, <<"black">>, <<"green">>, <<"white">>])
        , ?_assertEqual(RedValues, [<<"Red">>])
        , {"Check order", 
            [ ?_assertEqual(OrderValues,        [<<"black">>, <<"white">>])
            , ?_assertEqual(TopAlphOrderValues, [<<"black">>, <<"white">>])
            , ?_assertEqual(TopFreqOrderValues, [<<"green">>, <<"white">>])
            ]}
        , ?_assertEqual(RedValues, [<<"Red">>])
        ]
    after
        ?SRV:close(Server)
    end.
    
    

add_color_document(Server, Color) ->
    Document = [ #x_value{slot = color, value = Color} ],
    DocId = ?SRV:add_document(Server, Document).


term_advanced_actions_gen() ->
    Path = testdb_path(adv_actions),
    Params = [write, create, overwrite],
    {ok, Server} = ?SRV:open(Path, Params),
    try
        DocId = ?SRV:add_document(Server, []),
        U = fun(Doc) ->
            ?SRV:update_document(Server, DocId, Doc)
            end,
        
        Meta = xapian_term_record:record(term, record_info(fields, term)),
        FindTermFn = 
        fun(Value) ->
            DocRes = xapian_server:document(Server, DocId),
            Table = xapian_term_qlc:document_term_table(
                Server, DocRes, Meta, [ignore_empty]),
            ?SRV:release_resource(Server, DocRes),
            qlc:e(qlc:q([X || X = #term{value = Value} <- Table]))
            end,

        FF = fun() -> FindTermFn("term") end,
        UU = fun(Field) -> U([Field]), FF() end,

        Term             = #x_term{value = "term"},
        TermAdd          = Term#x_term{action = add}, 
        TermAddNotIgnore = Term#x_term{action = add, ignore = false}, 
        TermUpdate       = Term#x_term{action = update}, 
        TermUpdateNotIgnore = TermUpdate#x_term{ignore = false}, 
        TermSet          = Term#x_term{action = set}, 
        TermDec          = TermSet#x_term{frequency = -1}, 
        TermSetAbs       = TermSet#x_term{frequency = {abs, 10}}, 
        TermRemoveIgnore = Term#x_term{action = remove, frequency = 0},
        TermRemove       = TermRemoveIgnore#x_term{ignore = false},
        TermRemove2      = TermRemove#x_term{frequency = 123},

        Terms1 = FF(),
        Terms2 = UU(TermAddNotIgnore),

        %% Error will be thrown. Value was not changed.
        ?assertError(#x_error{type = <<"BadArgumentDriverError">>}, 
            UU(TermAddNotIgnore)),

        Terms3 = FF(),

        %% Error will be ignored. Value was not changed.
        Terms4 = UU(TermAdd),

        %% Start changing of WDF
        Terms5 = UU(TermUpdate),
        Terms6 = UU(TermSet),
        Terms7 = UU(TermDec),
        Terms8 = UU(TermSetAbs),

        %% Cannot remove term, because WDF is not matched.
        ?assertError(#x_error{type = <<"BadArgumentDriverError">>}, 
            UU(TermRemove2)),
        Terms9 = FF(),

        %% Delete the term
        Terms10 = UU(TermRemove),

        %% Cannot delete the term twoce
        ?assertError(#x_error{type = <<"InvalidArgumentError">>}, 
            UU(TermRemove)),
        Terms11 = FF(),


        %% Cannot update a non-existing term 
        ?assertError(#x_error{type = <<"BadArgumentDriverError">>}, 
            UU(TermUpdateNotIgnore)),
        Terms12 = FF(),

        %% It will be ignored.
        Terms13 = UU(TermUpdate),

        NormTerm1 = #term{value = <<"term">>, wdf = 1},
        NormTerm2 = #term{value = <<"term">>, wdf = 2},
        NormTerm3 = #term{value = <<"term">>, wdf = 3},
        NormTerm4 = #term{value = <<"term">>, wdf = 10},

        [ ?_assertEqual(Terms1, [])
        , ?_assertEqual(Terms2, [NormTerm1])
        , ?_assertEqual(Terms3, [NormTerm1])
        , ?_assertEqual(Terms4, [NormTerm1])
        , ?_assertEqual(Terms5, [NormTerm2])
        , ?_assertEqual(Terms6, [NormTerm3])
        , ?_assertEqual(Terms7, [NormTerm2])
        , ?_assertEqual(Terms8, [NormTerm4])
        , ?_assertEqual(Terms9, [NormTerm4])
        , ?_assertEqual(Terms10, [])
        , ?_assertEqual(Terms11, [])
        , ?_assertEqual(Terms12, [])
        , ?_assertEqual(Terms13, [])
        ]
    after
        ?SRV:close(Server)
    end.
    


reopen_test() ->
    % Open test
    Path = testdb_path(reopen),
    Params = [write, create, overwrite],
    {ok, Server} = ?SRV:open(Path, Params),
    ?SRV:close(Server),

    {ok, ReadOnlyServer} = ?SRV:open(Path, []),
    ?SRV:close(ReadOnlyServer).


-record(stemmer_test_record, {docid, data}).

stemmer_test() ->
    % Open test with the default stemmer
    Path = testdb_path(stemmer),
    Params = [write, create, overwrite, 
        #x_stemmer{language = <<"english">>},
        #x_prefix_name{name = author, prefix = <<$A>>, is_boolean=true}],
    Document =
        [ #x_data{value = "My test data as iolist (NOT INDEXED)"} 
        , #x_text{value = "Return a list of available languages."} 
        , #x_text{value = "And filter it."} 
        , #x_delta{position=300}
        , #x_text{value = "And other string is here."} 
        , #x_text{value = <<"Michael">>, prefix = author} 
        ],
    {ok, Server} = ?SRV:open(Path, Params),
    try
        %% Test a term generator
        DocId = ?SRV:add_document(Server, Document),
        ?assert(is_integer(DocId)),
        Last = ?SRV:last_document_id(Server),

        %% Test a query parser
        Offset = 0,
        PageSize = 10,
        Meta = xapian_record:record(stemmer_test_record, 
            record_info(fields, stemmer_test_record)),

        Q0 = #x_query_string{string="return"},
        Q1 = #x_query_string{string="return AND list"},
        Q2 = #x_query_string{string="author:michael"},
        Q3 = #x_query_string{string="author:olly list"},
        Q4 = #x_query_string{string="author:Michael"},
        Q5 = #x_query_string{string="retur*", features=[default, wildcard]},
        Q6 = #x_query_string{string="other AND Return"},
        Q7 = #x_query_string{string="list NEAR here"},
        Q8 = #x_query_string{string="list NEAR filter"},

        F = fun(Query) ->
            RecList = ?SRV:query_page(Server, Offset, PageSize, Query, Meta),
            io:format(user, "~n~p~n", [RecList]),
            RecList
            end,
        Qs =
        [Q0, Q1, Q2, Q3, Q4, Q5, Q6, Q7, Q8],
        [R0, R1, R2, R3, R4, R5, R6, R7, R8] = 
        lists:map(F, Qs),
        ?assertEqual(R7, []),
        ?assertEqual(R8, R0)
    after
        ?SRV:close(Server)
    end.



%% ------------------------------------------------------------------
%% Transations tests
%% ------------------------------------------------------------------

transaction_gen() ->
    % Open test
    Path1 = testdb_path(transaction1),
    Path2 = testdb_path(transaction2),
    Params = [write, create, overwrite],
    {ok, Server1} = ?SRV:open(Path1, Params),
    {ok, Server2} = ?SRV:open(Path2, Params),
    Fun = fun([S1, S2]) ->
        test_result
        end,
    BadFun = fun([S1, S2]) ->
        test_result = 1
        end,
    %% Check fallback
    BadFun2 = fun([S1, S2]) ->
        %% Try to kill S1.
        %% Server1 will be killed because of supervision.
        erlang:exit(S1, hello)
        end,
    %% Check fallback when the transaction process is still alive
    BadFun3 = fun([S1, S2]) ->
        erlang:exit(S1, hello),
        %% Sleep for 1 second.
        %% Because this process is active, then the monitor process will 
        %% kill it, because one of the servers is dead.
        timer:sleep(1000)
        end,
    Result1 = ?SRV:transaction([Server1, Server2], Fun, infinity),
    Result2 = ?SRV:transaction([Server1, Server2], BadFun),
    erlang:unlink(Server1),

    %% Wait for DB closing.
    timer:sleep(1000),
    Result3 = ?SRV:transaction([Server1, Server2], BadFun2),

    %% Server1 was killed. Server2 will replace it.
    {ok, Server3} = ?SRV:open(Path1, Params),
    erlang:unlink(Server2),

    %% 
    timer:sleep(1000),
    Result4 = ?SRV:transaction([Server2, Server3], BadFun3),

    %% Server3 is still alive.
    ?SRV:close(Server3),
    #x_transaction_result{
        is_committed=Committed1,
        is_consistent=Consistent1
    } = Result1,
    #x_transaction_result{
        is_committed=Committed2,
        is_consistent=Consistent2
    } = Result2,
    #x_transaction_result{
        is_committed=Committed3,
        is_consistent=Consistent3
    } = Result3,
    #x_transaction_result{
        is_committed=Committed4,
        is_consistent=Consistent4
    } = Result4,
    {"Check transactions' results for good and bad functions.",
        [ ?_assertEqual(Committed1, true)
        , ?_assertEqual(Consistent1, true)
        , ?_assertEqual(Committed2, false)
        , ?_assertEqual(Consistent2, true)
        , ?_assertEqual(Committed3, false)
        , ?_assertEqual(Consistent3, false)
        , ?_assertEqual(Committed4, false)
        , ?_assertEqual(Consistent4, false)
        , ?_assertEqual(erlang:is_process_alive(Server1), false)
        , ?_assertEqual(erlang:is_process_alive(Server2), false)
        , ?_assertEqual(erlang:is_process_alive(Server3), false)
        ]}.


transaction_readonly_error_gen() ->
    % Open test
    Path = testdb_path(transaction1),
    Params = [],
    {ok, Server} = ?SRV:open(Path, Params),
    Fun = fun([S]) ->
        test_result
        end,
    Result = ?SRV:transaction([Server], Fun, infinity),
    ?SRV:close(Server),
    #x_transaction_result{
        is_committed=Committed,
        is_consistent=Consistent,
        reason=Reason
    } = Result,
    {"Cannot start transaction for readonly server.",
        [ ?_assertEqual(Committed, false)
        , ?_assertEqual(Consistent, true)
        , ?_assertEqual(Reason, readonly_db)
        ]}.
    




%% ------------------------------------------------------------------
%% Extracting information
%% ------------------------------------------------------------------

%% The record will contain information about a document.
%% slot1 is a value.
%% docid and data are special fields.
-record(rec_test, {docid, slot1, data}).
-record(short_rec_test, {data}).


read_document_test() ->
    % Open test
    Path = testdb_path(read_document),
    Params = [write, create, overwrite, 
        #x_value_name{slot = 1, name = slot1}],
    Document =
        [ #x_stemmer{language = <<"english">>}
        , #x_data{value = "My test data as iolist"} 
        , #x_value{slot = slot1, value = "Slot #0"} 
        ],
    {ok, Server} = ?SRV:open(Path, Params),
    try
    DocId = ?SRV:add_document(Server, Document),
    Meta = xapian_record:record(rec_test, record_info(fields, rec_test)),
    Rec = ?SRV:read_document(Server, DocId, Meta),
    ?assertEqual(Rec#rec_test.docid, 1),
    ?assertEqual(Rec#rec_test.slot1, <<"Slot #0">>),
    ?assertEqual(Rec#rec_test.data, <<"My test data as iolist">>)
    after
        ?SRV:close(Server)
    end.


read_float_value_gen() ->
    % Open test
    Path = testdb_path(read_float),
    Params = [write, create, overwrite, 
        #x_value_name{type = float, slot = 1, name = slot1}],
    Document1 =
        [ #x_data{value = "My test data as iolist"} 
        , #x_value{slot = slot1, value = 7} 
        ],
    Document2 =
        [ #x_data{value = "My test data as iolist"} 
        , #x_value{slot = slot1, value = 66} 
        ],
    {ok, Server} = ?SRV:open(Path, Params),
    try
        DocId1 = ?SRV:add_document(Server, Document1),
        DocId2 = ?SRV:add_document(Server, Document2),
        Meta = xapian_record:record(rec_test, record_info(fields, rec_test)),
        Rec1 = ?SRV:read_document(Server, DocId1, Meta),
        Rec2 = ?SRV:read_document(Server, DocId2, Meta),

        %% #document{} is the simple container.
        Meta2 = xapian_record:record(document, record_info(fields, document)),
        Offset    = 0,
        PageSize  = 10,
        Query68   = #x_query_value_range{slot=slot1, from=6, to=8},
        Query8    = #x_query_value{op=lower, slot=slot1, value=8},
        Query7    = #x_query_value_range{op=lower, slot=slot1, from=7, to=7},

        RecList68 = ?SRV:query_page(Server, Offset, PageSize, Query68, Meta2),
        RecList8  = ?SRV:query_page(Server, Offset, PageSize, Query8, Meta2),
        RecList7  = ?SRV:query_page(Server, Offset, PageSize, Query7, Meta2),

        [?_assertEqual(Rec1#rec_test.docid, 1)
        ,?_assertEqual(Rec1#rec_test.slot1, 7.0)
        ,?_assertEqual(Rec1#rec_test.data, <<"My test data as iolist">>)
        ,?_assertEqual(Rec2#rec_test.docid, 2)
        ,?_assertEqual(Rec2#rec_test.slot1, 66.0)
        ,?_assertEqual(Rec2#rec_test.data, <<"My test data as iolist">>)
        ,?_assertEqual(RecList68, [#document{docid=1}])
        ,?_assertEqual(RecList7,  [#document{docid=1}])
        ,?_assertEqual(RecList8,  [#document{docid=1}])
        ]
    after
        ?SRV:close(Server)
    end.


short_record_test() ->
    Path = testdb_path(short_rec_test),
    Params = [write, create, overwrite],
    {ok, Server} = ?SRV:open(Path, Params),
    Document = [#x_data{value = "ok"}],
    DocId = ?SRV:add_document(Server, Document),
    Meta = xapian_record:record(short_rec_test, record_info(fields, short_rec_test)),
    Rec = ?SRV:read_document(Server, DocId, Meta),
    ?assertEqual(Rec#short_rec_test.data, <<"ok">>),
    ?SRV:close(Server).


%% @doc Check an exception.
read_bad_docid_test() ->
    % Open test
    Path = testdb_path(read_document),
    Params = [#x_value_name{slot = 1, name = slot1}],
    {ok, Server} = ?SRV:open(Path, Params),
    Meta = xapian_record:record(rec_test, record_info(fields, rec_test)),
    DocId = 2,
    % ?assertException(ClassPattern, TermPattern, Expr)
    ?assertException(error, 
        #x_error{type = <<"DocNotFoundError">>}, 
        ?SRV:read_document(Server, DocId, Meta)),
    ?SRV:close(Server).


%% ------------------------------------------------------------------
%% Books (query testing)
%% ------------------------------------------------------------------


%% These records are used for tests.
%% They describe values of documents.
-record(book, {docid, author, title, data}).
-record(book_ext, {docid, author, title, data,   rank, weight, percent}).


%% These cases will be runned sequencly.
%% `Server' will be passed as a parameter.
%% `Server' will be opened just once for all cases.
cases_gen() ->
    Cases = 
    [ fun single_term_query_page_case/1
    , fun value_range_query_page_case/1
    , fun double_terms_or_query_page_case/1
    , fun special_fields_query_page_case/1

    , fun enquire_case/1
    , fun resource_cleanup_on_process_down_case/1
    , fun enquire_to_mset_case/1
    , fun qlc_mset_case/1

    , fun create_user_resource_case/1

    %% Advanced enquires
    , fun advanced_enquire_case/1
    , fun advanced_enquire_weight_case/1

    %% Info
    , fun match_set_info_case/1
    , fun database_info_case/1
    ],
    Server = query_page_setup(),
    %% One setup for each test
    {setup, 
        fun() -> Server end, 
        fun query_page_clean/1,
        [Case(Server) || Case <- Cases]}.
    

query_page_setup() ->
    % Open test
	Path = testdb_path(query_page),
    ValueNames = [ #x_value_name{slot = 1, name = author}
                 , #x_value_name{slot = 2, name = title}],
    Params = [write, create, overwrite] ++ ValueNames,
    {ok, Server} = ?SRV:open(Path, Params),
    Base = [#x_stemmer{language = <<"english">>}],
    Document1 = Base ++
        [ #x_data{value = "Non-indexed data here"} 
        , #x_text{value = "erlang/OTP"} 
        , #x_text{value = "concurrency"} 
        , #x_value{slot = title, value = "Software for a Concurrent World"} 
        , #x_value{slot = author, value = "Joe Armstrong"} 
        ],
    Document2 = Base ++
        [ #x_stemmer{language = <<"english">>}
        , #x_text{value = "C++"} 
        , #x_value{slot = title, value = "Code Complete: "
            "A Practical Handbook of Software Construction"} 
        , #x_value{slot = author, value = "Steve McConnell"} 
        ],
    %% Put the documents into the database
    [1, 2] = 
    [ ?SRV:add_document(Server, Document) || Document <- [Document1, Document2] ],
    Server.

query_page_clean(Server) ->
    ?SRV:close(Server).

single_term_query_page_case(Server) ->
    Case = fun() ->
        Offset = 0,
        PageSize = 10,
        Query = "erlang",
        Meta = xapian_record:record(book, record_info(fields, book)),
        RecList = ?SRV:query_page(Server, Offset, PageSize, Query, Meta),
        io:format(user, "~n~p~n", [RecList])
        end,
    {"erlang", Case}.

value_range_query_page_case(Server) ->
    Case = fun() ->
        Offset = 0,
        PageSize = 10,
        Query = #x_query_value_range{slot=author, 
                                     from="Joe Armstrong", 
                                     to="Joe Armstrong"},
        Meta = xapian_record:record(book, record_info(fields, book)),
        RecList = ?SRV:query_page(Server, Offset, PageSize, Query, Meta),
        io:format(user, "~n~p~n", [RecList])
        end,
    {"Joe Armstrong - Joe Armstrong", Case}.

double_terms_or_query_page_case(Server) ->
    Case = fun() ->
        Offset = 0,
        PageSize = 10,
        Query = #x_query{op='OR', value=[<<"erlang">>, "c++"]},
        Meta = xapian_record:record(book, record_info(fields, book)),
        RecList = ?SRV:query_page(Server, Offset, PageSize, Query, Meta),
        io:format(user, "~n~p~n", [RecList])
        end,
    {"erlang OR c++", Case}.


%% You can get dynamicly calculated fields.
special_fields_query_page_case(Server) ->
    Case = fun() ->
        Offset = 0,
        PageSize = 10,
        Query = "erlang",
        Meta = xapian_record:record(book_ext, record_info(fields, book_ext)),
        RecList = ?SRV:query_page(Server, Offset, PageSize, Query, Meta),
        io:format(user, "~n~p~n", [RecList])
        end,
    {"erlang (with rank, weight, percent)", Case}.


%% Xapian uses `Xapian::Enquire' class as a hub for making queries.
%% Enquire object can be handled as a resource.
enquire_case(Server) ->
    Case = fun() ->
        Query = "erlang",
        ResourceId = ?SRV:enquire(Server, Query),
        io:format(user, "~n~p~n", [ResourceId]),
        ?SRV:release_resource(Server, ResourceId)
        end,
    {"Simple enquire resource", Case}.


%% If the client is dead, then its resources will be released.
resource_cleanup_on_process_down_case(Server) ->
    Case = fun() ->
        Home = self(),
        Ref = make_ref(),
        spawn_link(fun() ->
                Query = "erlang",
                ResourceId = ?SRV:enquire(Server, Query),
                Home ! {resource_id, Ref, ResourceId}
                end),

        ResourceId = 
        receive
            {resource_id, Ref, ResourceIdI} ->
                ResourceIdI
        end,

        ?assertError(elem_not_found, ?SRV:release_resource(Server, ResourceId))
        end,
    {"Check garbidge collection for resources", Case}.


enquire_to_mset_case(Server) ->
    Case = fun() ->
        Query = "erlang",
        EnquireResourceId = ?SRV:enquire(Server, Query),
        MSetResourceId = ?SRV:match_set(Server, EnquireResourceId),
        io:format(user, "~n ~p ~p~n", [EnquireResourceId, MSetResourceId]),
        ?SRV:release_resource(Server, EnquireResourceId),
        ?SRV:release_resource(Server, MSetResourceId)
        end,
    {"Check conversation", Case}.


%% Tests with QLC.
-include_lib("stdlib/include/qlc.hrl").

qlc_mset_case(Server) ->
    Case = fun() ->
        %% Query is a query to make for retrieving documents from Xapian.
        %% Each document object will be mapped into a document record. 
        %% A document record is a normal erlang record, 
        %% it has structure, described by the user,
        %% using  the `xapian_record:record' call.
        Query = "erlang",
        EnquireResourceId = ?SRV:enquire(Server, Query),
        MSetResourceId = ?SRV:match_set(Server, EnquireResourceId),

        %% Meta is a record, which contains some information about
        %% structure of a document record.
        %% The definition of Meta is incapsulated inside `xapian_record' module.
        Meta = xapian_record:record(book_ext, record_info(fields, book_ext)),

        %% Create QlcTable from MSet. 
        %% After creation of QlcTable, MSet can be removed.
        Table = xapian_mset_qlc:table(Server, MSetResourceId, Meta),
        ?SRV:release_resource(Server, MSetResourceId),

        %% QueryAll is a list of all matched records.
        QueryAll = qlc:q([X || X <- Table]),

        %% Check `lookup' function. This function is used by `qlc' module.
        %% It will be called to find a record by an index.
        QueryFilter = qlc:q(
            [X || X=#book_ext{docid=DocId} <- Table, DocId =:= 1]),
        Queries = [QueryAll, QueryFilter],

        %% For each query...
        [begin
            %% ... evaluate (execute) ...
            Records = qlc:e(Q),
            %% ... and print out.
            io:format(user, "~n ~p~n", [Records])
            end || Q <- Queries
        ],

        %% This case will cause an error, because DocId > 0.
        QueryBadFilter = qlc:q(
            [X || X=#book_ext{docid=DocId} <- Table, DocId =:= 0]),
        ?assertError(bad_docid, qlc:e(QueryBadFilter))
        end,
    {"Check internal_qlc_init", Case}.


create_user_resource_case(Server) ->
    Case = fun() ->
        %% User-defined resource is an object, which is created on C++ side.
        %% We using Erlang references for returning it back to the user.
        %% A reference can be used only with this Server.
        ResourceId = ?SRV:internal_create_resource(Server, bool_weight),
        io:format(user, "User-defined resource ~p~n", [ResourceId])
        end,
    {"Check creation of user-defined resources", Case}.


%% Additional parameters can be passed to `Xapian::Enquire'.
%% We use `#x_enquire' record for this.
advanced_enquire_case(Server) ->
    Case = fun() ->
        Query = #x_enquire{
            value = "Erlang"
        },
        EnquireResourceId = ?SRV:enquire(Server, Query),
        ?assert(is_reference(EnquireResourceId)),
        ?SRV:release_resource(Server, EnquireResourceId)
        end,
    {"Check #x_enquire{}", Case}.


%% We can pass other `Xapian::Weight' object, stored as an user resource.
%% We create new `Xapian::BoolWeight' object as a resource and pass it back
%% as an additional parameter.
advanced_enquire_weight_case(Server) ->
    Case = fun() ->
        Query = #x_enquire{
            value = "Erlang",
            weighting_scheme = xapian_resource:bool_weight(Server)
        },
        EnquireResourceId = ?SRV:enquire(Server, Query),
        ?assert(is_reference(EnquireResourceId)),
        ?SRV:release_resource(Server, EnquireResourceId)
        end,
    {"Check #x_enquire{weight=Xapian::BoolWeight}", Case}.


match_set_info_case(Server) ->
    Case = fun() ->
        Query = "erlang",
        EnquireResourceId = ?SRV:enquire(Server, Query),
        ?assert(is_reference(EnquireResourceId)),
        MSetResourceId = ?SRV:match_set(Server, EnquireResourceId),
        Info = 
        ?SRV:mset_info(Server, MSetResourceId, [matches_lower_bound, size]),
        ?SRV:mset_info(Server, MSetResourceId, xapian_mset_info:properties()),
        ?SRV:release_resource(Server, EnquireResourceId),
        ?SRV:release_resource(Server, MSetResourceId),
        io:format(user, "~nMSet Info: ~p~n", [Info])
        end,
    {"Check mset_info function.", Case}.


database_info_case(Server) ->
    Case = fun() ->
        Info = 
        ?SRV:database_info(Server, [document_count]),
        ?SRV:database_info(Server, xapian_db_info:properties()),
        io:format(user, "~nDB Info: ~p~n", [Info])
        end,
    {"Check database_info function.", Case}.


metadata_gen() ->
    Path = testdb_path(metadata),
    Params = [write, create, overwrite],
    {ok, Server} = ?SRV:open(Path, Params),
    ?SRV:set_metadata(Server, "key", "value"),
    Info = 
    ?SRV:database_info(Server, [{metadata, "key"}]),
    ?SRV:close(Server),
    [?_assertEqual(Info, [{{metadata, "key"}, <<"value">>}])].


%% http://trac.xapian.org/wiki/FAQ/ExtraWeight
extra_weight_gen() ->
    Path = testdb_path(extra_weight),
    Params = [write, create, overwrite],
    {ok, Server} = ?SRV:open(Path, Params),
    Terms = ["Sxapian", "weight"],
    Document = [#x_term{value = X} || X <- Terms],
    DocId = ?SRV:add_document(Server, Document),
    Query = extra_weight_query(2.5, "Sxapian", "weight"),
    Ids = all_record_ids(Server, Query),
    [?_assertEqual(Ids, [DocId])].


%% `Title' and `Body' are queries.
extra_weight_query(Factor, Title, Body) ->
    Scale = #x_query_scale_weight{factor = 2.5, value = Title},
    #x_query{value = [Scale, Body]}.



%% -------------------------------------------------------------------
%%  Multi-DB support
%% -------------------------------------------------------------------

-record(mdocument, {docid, db_name, multi_docid, db_number}).

all_record_ids(Server, Query) ->
    EnquireResourceId = ?SRV:enquire(Server, Query),
    MSetResourceId = ?SRV:match_set(Server, EnquireResourceId),
    Meta = xapian_record:record(document, record_info(fields, document)),
    Table = xapian_mset_qlc:table(Server, MSetResourceId, Meta),
    qlc:e(qlc:q([Id || #document{docid=Id} <- Table])).


all_multidb_records(Server, Query) ->
    EnquireResourceId = ?SRV:enquire(Server, Query),
    MSetResourceId = ?SRV:match_set(Server, EnquireResourceId),
    Meta = xapian_record:record(mdocument, record_info(fields, mdocument)),
    Table = xapian_mset_qlc:table(Server, MSetResourceId, Meta),
    qlc:e(qlc:q([X || X <- Table])).


record_by_id(Server, Query, Id) ->
    EnquireResourceId = ?SRV:enquire(Server, Query),
    MSetResourceId = ?SRV:match_set(Server, EnquireResourceId),
    Meta = xapian_record:record(mdocument, record_info(fields, mdocument)),
    Table = xapian_mset_qlc:table(Server, MSetResourceId, Meta),
    qlc:e(qlc:q([X || X=#mdocument{docid=DocId} <- Table, Id =:= DocId])).


multidb_record_by_id(Server, Query, Id) ->
    EnquireResourceId = ?SRV:enquire(Server, Query),
    MSetResourceId = ?SRV:match_set(Server, EnquireResourceId),
    Meta = xapian_record:record(mdocument, record_info(fields, mdocument)),
    Table = xapian_mset_qlc:table(Server, MSetResourceId, Meta),
    qlc:e(qlc:q([X || X=#mdocument{multi_docid=DocId} <- Table, Id =:= DocId])).


%% Simple usage of a merged DB.
multi_db_gen() ->
    Path1 = #x_database{name=multi1, path=testdb_path(multi1)},
    Path2 = #x_database{name=multi2, path=testdb_path(multi2)},
    Params = [write, create, overwrite],
    Document = [#x_term{value = "test"}],
    {ok, Server1} = ?SRV:open(Path1, Params),
    {ok, Server2} = ?SRV:open(Path2, Params),
    DocId1 = ?SRV:add_document(Server1, Document),
    DocId2 = ?SRV:add_document(Server2, Document),
    ?SRV:close(Server1),
    ?SRV:close(Server2),

    %% Merged server
    {ok, Server} = ?SRV:open([Path1, Path2], []),
    Query    = "test",
    Ids      = all_record_ids(Server, Query),
    Records  = all_multidb_records(Server, Query),
    DbNames  = elements(#mdocument.db_name, Records),
    MultiIds = elements(#mdocument.multi_docid, Records),
    DbNums   = elements(#mdocument.db_number, Records),
    LookupRecords1 = record_by_id(Server, Query, 1),
    LookupRecords2 = record_by_id(Server, Query, 5),
    LookupRecords3 = multidb_record_by_id(Server, Query, 1),
    LookupRecords4 = multidb_record_by_id(Server, Query, 2),
    LookupRecords5 = multidb_record_by_id(Server, Query, 5),

    [?_assertEqual(Ids, [1,1])
    ,?_assertEqual(DbNames, [multi1, multi2])
    ,?_assertEqual(MultiIds, [1,2])
    ,?_assertEqual(DbNums, [1,2])
    ,{"Document is not found by id.",
        [?_assertEqual(LookupRecords5, [])
        ,?_assertEqual(LookupRecords2, [])]}
    ,?_assertEqual(length(LookupRecords1), 2)
    ,?_assertEqual(length(LookupRecords3), 1)
    ,?_assertEqual(length(LookupRecords4), 1)
    ].


elements(Pos, Records) ->
    [erlang:element(Pos, Rec) || Rec <- Records].


remote_db_test() ->
    Params = [writable, link, {port, 6666}],
    DBList = [testdb_path(tcp_remote)],
    xapian_utils:tcp_server(DBList, Params),
    timer:sleep(200),
    DBConfig = #x_tcp_database{port = 6666, host = "127.0.0.1"},
    {ok, Server} = ?SRV:open(DBConfig, [write]),
    ?SRV:close(Server).



%% This test tests the lookup function of a mset qlc table.
%% Besides, it tests `xapian_server:multi_docid/3' function and 
%% other functions for conversation between: 
%% * `docid', `db_number' and `multi_docid';
%% * `db_name' and `db_number'.
prop_multi_db() ->
    Path1 = #x_database{name=multi1, path=testdb_path(multi_docid1)},
    Path2 = #x_database{name=multi2, path=testdb_path(multi_docid2)},
    Path3 = #x_database{name=multi3, path=testdb_path(multi_docid3)},
    Params = [write, create, overwrite],
    Document = [#x_term{value = "test"}],
    {ok, Server1} = ?SRV:open(Path1, Params),
    {ok, Server2} = ?SRV:open(Path2, Params),
    {ok, Server3} = ?SRV:open(Path3, Params),
    Servers = [Server1, Server2, Server3],
    Paths = [Path1, Path2, Path3],
    try
        [?SRV:add_document(S, Document) 
            || X <- lists:seq(1, 1000), 
               S <- Servers ]
    after
        [ ?SRV:close(S) || S <- Servers ]
    end,

    %% Merged server
    {ok, Server} = ?SRV:open(Paths, []),
    Query = "test",
    multidb_record_by_id(Server, Query, 1),
    multidb_record_by_id(Server, Query, 2),
    multidb_record_by_id(Server, Query, 5),

    ?FORALL({DocId, Db}, 
            {range(1,1000), oneof([1, 2, 3, multi1, multi2, multi3])},
        begin
        MultiDocId = ?SRV:multi_docid(Server, DocId, Db),
        Doc = #mdocument{docid=DocId, 
                    multi_docid=MultiDocId, 
                    db_name=multi_sub_db_id_to_name(Db), 
                    db_number=multi_sub_db_name_to_id(Db)},
        equals([Doc], multidb_record_by_id(Server, Query, MultiDocId))
        end).


prop_echo() ->
    {ok, Server} = ?SRV:open([], []),
    ?FORALL(Bin, binary(),
        begin
        equals(Bin, ?SRV:internal_test_run(Server, echo, Bin))
        end).


multi_sub_db_id_to_name(Id) when is_integer(Id) -> 
    list_to_existing_atom("multi" ++ integer_to_list(Id));

multi_sub_db_id_to_name(Name) when is_atom(Name) -> 
    Name.


multi_sub_db_name_to_id(Id) when is_integer(Id) -> 
    Id;

multi_sub_db_name_to_id(Name) when is_atom(Name) -> 
    "multi" ++ IdList = atom_to_list(Name),
    list_to_integer(IdList).


%% -------------------------------------------------------------------
%% Property Testing
%% -------------------------------------------------------------------

run_property_testing_gen() ->
    EunitLeader = erlang:group_leader(),
    erlang:group_leader(whereis(user), self()),
    Res = proper:module(?MODULE),
    erlang:group_leader(EunitLeader, self()),
    ?_assertEqual([], Res). 

-endif.

