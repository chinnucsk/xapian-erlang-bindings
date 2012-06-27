-module(xapian_mset_info).
-export([encode/2,
         decode/2,
         properties/0]).

-import(xapian_common, [
    append_uint8/2,
    append_iolist/2,
    read_document_count/1,
    read_weight/1
]).

-import(xapian_const, [mset_info_param_id/1]).
encode(Params, Bin) when is_list(Params) ->
    append_uint8(mset_info_param_id(stop),
        lists:foldl(fun append_mset_info_param/2, Bin, Params));

encode(Param, Bin) ->
    append_uint8(mset_info_param_id(stop),
        append_mset_info_param(Param, Bin)).

    
decode(Params, Bin) when is_list(Params) ->
    {RevRes, RemBin} = 
    lists:foldl(fun decode_mset_info_param/2, {[], Bin}, Params),
    {lists:reverse(RevRes), RemBin};

decode(Param, Bin) ->
    decode_mset_info_param2(Param, Bin).


append_mset_info_param(Param, Bin) when is_atom(Param) ->
    true = lists:member(Param, properties()),
    append_uint8(mset_info_param_id(Param), Bin);

append_mset_info_param({Param, Term}, Bin) when is_atom(Param) ->
    append_iolist(Term, append_uint8(mset_info_param_id(Param), Bin)).


decode_mset_info_param(Param, {Acc, Bin}) ->
    {Value, RemBin} = decode_mset_info_param2(Param, Bin),
    {[{Param, Value}|Acc], RemBin}.


decode_mset_info_param2(Param, Bin) when is_atom(Param) ->
    decode_param(Param, Bin);

decode_mset_info_param2({Param, _Term}, Bin) when is_atom(Param) ->
    decode_param(Param, Bin).


%% These properties can be accessed without an additional parameter.
properties() ->
    [matches_lower_bound, matches_estimated, matches_upper_bound,
     uncollapsed_matches_lower_bound, uncollapsed_matches_estimated,
     uncollapsed_matches_upper_bound, size, max_possible, max_attained].


decode_param(matches_lower_bound, Bin) ->
    read_document_count(Bin);

decode_param(matches_estimated, Bin) ->
    read_document_count(Bin);

decode_param(matches_upper_bound, Bin) ->
    read_document_count(Bin);

decode_param(uncollapsed_matches_lower_bound, Bin) ->
    read_document_count(Bin);

decode_param(uncollapsed_matches_estimated, Bin) ->
    read_document_count(Bin);

decode_param(uncollapsed_matches_upper_bound, Bin) ->
    read_document_count(Bin);

decode_param(size, Bin) ->
    read_document_count(Bin);

decode_param(max_possible, Bin) ->
    read_weight(Bin);

decode_param(max_attained, Bin) ->
    read_weight(Bin);

decode_param(term_weight, Bin) ->
    read_weight(Bin);

decode_param(term_freq, Bin) ->
    read_document_count(Bin).
