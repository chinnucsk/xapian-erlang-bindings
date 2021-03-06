-module(xapian_const).
-export([command_id/1,
         open_mode_id/1,
         qlc_type_id/1,
         test_id/1,
         operator_id/1,
         query_id/1,
         parser_command_id/1,
         stem_strategy_id/1,
         document_part_id/1,
         action_type/1,
         posting_type/1,
         term_type/1,
         value_type_id/1,
         value_type_name/1,
         slot_type_to_command_type/1,
         source_type_id/1,
         db_info_param_id/1,
         mset_info_param_id/1,
         spy_info_param_id/1,
         enquire_command_id/1,
         order_type_id/1,
         sort_order_value_type/1,
         docid_order_type_id/1,
         spy_type_id/1,
         query_parser_type_id/1,
         db_term_iter_type_id/1,
         term_field_id/1,
         document_field_id/1,
         parser_type_id/1,
         generator_type_id/1,
         generator_command_id/1,
         resource_encoding_schema_id/1,
         parse_string_field_id/1,
         parser_feature_id/1,
         generator_feature_id/1]).

-compile({parse_transform, gin}).


%% Command ids
%% Returns an operation for {@see erlang:port_control/3}
command_id(open)                        -> 0;
command_id(last_document_id)            -> 1;
command_id(add_document)                -> 2;
command_id(test)                        -> 3;
command_id(read_document_by_id)         -> 4;
command_id(start_transaction)           -> 5;
command_id(cancel_transaction)          -> 6;
command_id(commit_transaction)          -> 7;
command_id(query_page)                  -> 8;
command_id(set_default_stemmer)         -> 9;
command_id(set_default_prefixes)        -> 10;
command_id(enquire)                     -> 11;
command_id(release_resource)            -> 12;
command_id(match_set)                   -> 13;
command_id(qlc_init)                    -> 14;
command_id(qlc_next_portion)            -> 15;
command_id(qlc_lookup)                  -> 16;
command_id(get_resource_constructors)   -> 17;
command_id(create_resource)             -> 18;
command_id(mset_info)                   -> 19;
command_id(database_info)               -> 20;
command_id(delete_document)             -> 21;
command_id(replace_or_create_document)  -> 22;
command_id(set_metadata)                -> 23;
command_id(update_document)             -> 24;
command_id(update_or_create_document)   -> 25;
command_id(document)                    -> 26;
command_id(open_prog)                   -> 27;
command_id(open_tcp)                    -> 28;
command_id(close)                       -> 29;
command_id(document_info)               -> 30;
command_id(document_info_resource)      -> 31;
command_id(is_document_exist)           -> 32;
command_id(replace_document)            -> 33;
command_id(release_resources)           -> 34;
command_id(match_spy_info)              -> 35;
command_id(create_query_parser)         -> 36;
command_id(parse_string)                -> 37;
command_id(add_spelling)                -> 38;
command_id(add_synonym)                 -> 39;
command_id(remove_synonym)              -> 40;
command_id(clear_synonyms)              -> 41;
command_id(create_term_generator)       -> 42.


%% Open modes of the DB
open_mode_id(read_open)                 -> 0;
open_mode_id(write_create_or_open)      -> 1;
open_mode_id(write_create)              -> 2;
open_mode_id(write_create_or_overwrite) -> 3;
open_mode_id(write_open)                -> 4.


qlc_type_id(mset)                 -> 0;
qlc_type_id(terms)                -> 1;
qlc_type_id(spy_terms)            -> 2;
qlc_type_id(query_parser_terms)   -> 3;
qlc_type_id(database_terms)       -> 4.


%% Identificators for C++ tests
test_id(result_encoder) -> 1;
test_id(exception)      -> 2;
test_id(echo)           -> 3;
test_id(memory)         -> 4.


%% ------------------------------------------------------------
%% Query Header
%% ------------------------------------------------------------

%% From `include/xapian/query.h'
operator_id('AND')          -> 0;
operator_id('OR')           -> 1;
operator_id('AND NOT')      -> 2;
operator_id('XOR')          -> 3;
operator_id('AND MAYBE')    -> 4;
operator_id('FILTER')       -> 5;
operator_id('NEAR')         -> 6;
operator_id('PHRASE')       -> 7;
operator_id('VALUE RANGE')  -> 8;
operator_id('SCALE WEIGHT') -> 9;
operator_id('ELITE SET')    -> 10;
operator_id('VALUE GE')     -> 11;
operator_id('VALUE LE')     -> 12;
operator_id('SYNONYM')      -> 13;

%% They are often used, that is why short version is usefult.
operator_id('greater')      -> operator_id('VALUE GE');
operator_id('lower')        -> operator_id('VALUE LE');
operator_id('less')         -> operator_id('VALUE LE').


query_id(query_group)       -> 1;
query_id(query_value)       -> 2;
query_id(query_value_range) -> 3;
query_id(query_term)        -> 4;
query_id(query_string)      -> 5;
query_id(query_scale_weight) -> 6;
query_id(query_resource)    -> 7.


%% ------------------------------------------------------------
%% Query Parser Header
%% ------------------------------------------------------------

%% From `XapianErlangDriver::queryParserCommand'
parser_command_id(stop)                     -> 0;
parser_command_id(stemmer)                  -> 1;
parser_command_id(stemming_strategy)        -> 2;
parser_command_id(max_wildcard_expansion)   -> 3;
parser_command_id(default_op)               -> 4;
parser_command_id(parser_type)              -> 5; 
parser_command_id(prefix)                   -> 6;
parser_command_id(value_range_processor)    -> 7;
parser_command_id(from_resource)            -> 8;
parser_command_id(stemmer_resource)         -> 9;
parser_command_id(stopper_resource)         -> 10.


%% From `XapianErlangDriver::queryParserType'
parser_type_id(default)  -> 0;
parser_type_id(standard) -> 1.


generator_type_id(default)  -> 0;
generator_type_id(standard) -> 1.


generator_command_id(stop)                     -> 0;
generator_command_id(stemmer)                  -> 1;
generator_command_id(stemming_strategy)        -> 2;
generator_command_id(generator_type)           -> 3; 
generator_command_id(from_resource)            -> 4;
generator_command_id(stemmer_resource)         -> 5;
generator_command_id(stopper_resource)         -> 6.


%% From `XapianErlangDriver::STEM_STRATEGIES'
stem_strategy_id(none)    -> 0;
stem_strategy_id(default) -> 0;
stem_strategy_id(some)    -> 1;
stem_strategy_id(all)     -> 2.


%% Features of QueryParser
parser_feature_id(stop)                    -> 0;
parser_feature_id('BOOLEAN')               -> 1;
parser_feature_id('PHRASE')                -> 2;
parser_feature_id('LOVEHATE')              -> 3;
parser_feature_id('BOOLEAN ANY CASE')      -> 4;
parser_feature_id('WILDCARD')              -> 5;
parser_feature_id('PURE NOT')              -> 6;
parser_feature_id('PARTIAL')               -> 7;
parser_feature_id('SPELLING CORRECTION')   -> 8;
parser_feature_id('SYNONYM')               -> 9;
parser_feature_id('AUTO SYNONYMS')         -> 10;
parser_feature_id('AUTO MULTIWORD SYNONYMS') -> 11;
parser_feature_id('DEFAULT')               -> 12;

parser_feature_id('SYNONYMS') -> 
    parser_feature_id('SYNONYM');

parser_feature_id(boolean) -> 
    parser_feature_id('BOOLEAN');

parser_feature_id(phrase) -> 
    parser_feature_id('PHRASE');

parser_feature_id(lovehate) -> 
    parser_feature_id('LOVEHATE');

parser_feature_id(boolean_any_case) -> 
    parser_feature_id('BOOLEAN ANY CASE');

parser_feature_id(wildcard) -> 
    parser_feature_id('WILDCARD');

parser_feature_id(pure_not) -> 
    parser_feature_id('PURE NOT');

parser_feature_id(partial) -> 
    parser_feature_id('PARTIAL');

parser_feature_id(spelling_correction) -> 
    parser_feature_id('SPELLING CORRECTION');

parser_feature_id(synonym) -> 
    parser_feature_id('SYNONYM');

parser_feature_id(synonyms) -> 
    parser_feature_id('SYNONYM');

parser_feature_id(auto_synonyms) -> 
    parser_feature_id('AUTO SYNONYMS');

parser_feature_id(auto_multiword_synonyms) -> 
    parser_feature_id('AUTO MULTIWORD SYNONYMS');

parser_feature_id(default) -> 
    parser_feature_id('DEFAULT').


%% generator flags
generator_feature_id(spelling)  -> 1;
%% Delimeter 50
%% The default has the same number as a delimeter.
generator_feature_id(default)   -> 50;

%% Other flags
generator_feature_id(positions) -> 51.

%% ------------------------------------------------------------
%% Document
%% ------------------------------------------------------------

document_part_id(stop)              -> 0;
document_part_id(stemmer)           -> 1;
document_part_id(data)              -> 2;
document_part_id(delta)             -> 3;
document_part_id(text)              -> 4;
document_part_id(term_generator)    -> 5;
document_part_id(set_term_gen_pos)  -> 6;

document_part_id(set_posting)       -> 15;
document_part_id(add_posting)       -> 25;
document_part_id(update_posting)    -> 35;
document_part_id(remove_posting)    -> 45;

document_part_id(set_term)          -> 16;
document_part_id(add_term)          -> 26;
document_part_id(update_term)       -> 36;
document_part_id(remove_term)       -> 46;

document_part_id(add_value)         -> 17;
document_part_id(set_value)         -> 27;
document_part_id(update_value)      -> 37;
document_part_id(remove_value)      -> 47;

document_part_id(dec_wdf)                   -> 101;
document_part_id(set_wdf)                   -> 111;
document_part_id(remove_values)             -> 103;
document_part_id(remove_terms)              -> 104;
document_part_id(remove_positions)          -> 105;
document_part_id(remove_term_positions)     -> 106;
document_part_id(remove_term_positions_save)-> 116.


action_type(add)       -> add_value;
action_type(set)       -> set_value;
action_type(update)    -> update_value;
action_type(remove)    -> remove_value.


posting_type(add)     -> add_posting;
posting_type(set)     -> set_posting;
posting_type(update)  -> update_posting;
posting_type(remove)  -> remove_posting.


term_type(add)     -> add_term;
term_type(set)     -> set_term;
term_type(update)  -> update_term;
term_type(remove)  -> remove_term.


%% @doc Convert value <i>encoding</i> type name to its id.
%% A value can be float. This prefix helps to define, which format is passed.
value_type_id(string) -> 0;
value_type_id(double) -> 1.

value_type_name(0) -> string;
value_type_name(1) -> double.


%% @doc Returns a name of a command for encoder.
%% A command is a type of the record, not a type of the value.
%% Types of the record are data, docid, value.
%% Types of the value are string, float.
slot_type_to_command_type(float)  -> float_value;
slot_type_to_command_type(string) -> value;
slot_type_to_command_type(bytes) -> value.


%% @doc Return an id of the term QLC iterator type.
%% Defines the source of a document record used for retrieving information.
source_type_id(document) -> 0;
source_type_id(iterator) -> 1;
source_type_id(both)     -> 2.

%% ------------------------------------------------------------
%% Info
%% ------------------------------------------------------------

db_info_param_id(stop)                          -> 0;
db_info_param_id(has_positions)                 -> 1;
db_info_param_id(document_count)                -> 2;
db_info_param_id(last_document_id)              -> 3;
db_info_param_id(average_length)                -> 4;
db_info_param_id(term_exists)                   -> 5;
db_info_param_id(term_freq)                     -> 6;
db_info_param_id(collection_freq)               -> 7;
db_info_param_id(value_freq)                    -> 8;
db_info_param_id(value_lower_bound)             -> 9;
db_info_param_id(value_upper_bound)             -> 10;
db_info_param_id(document_length_lower_bound)   -> 11;
db_info_param_id(document_length_upper_bound)   -> 12;
db_info_param_id(wdf_upper_bound)               -> 13;
db_info_param_id(document_length)               -> 14;
db_info_param_id(uuid)                          -> 15;
db_info_param_id(metadata)                      -> 16.


mset_info_param_id(stop)                            -> 0;
mset_info_param_id(matches_lower_bound)             -> 1;
mset_info_param_id(matches_estimated)               -> 2;
mset_info_param_id(matches_upper_bound)             -> 3;
mset_info_param_id(uncollapsed_matches_lower_bound) -> 4;
mset_info_param_id(uncollapsed_matches_estimated)   -> 5;
mset_info_param_id(uncollapsed_matches_upper_bound) -> 6;
mset_info_param_id(size)                            -> 7;
mset_info_param_id(max_possible)                    -> 8;
mset_info_param_id(max_attained)                    -> 9;
mset_info_param_id(term_weight)                     -> 10;
mset_info_param_id(term_freq)                       -> 11.

spy_info_param_id(stop)                             -> 0;
spy_info_param_id(document_count)                   -> 1;
spy_info_param_id(value_slot)                       -> 2.

%% ------------------------------------------------------------
%% Enquire
%% ------------------------------------------------------------

enquire_command_id(stop)                     -> 0;
enquire_command_id(x_query)                  -> 1;
enquire_command_id(query_len)                -> 2;
enquire_command_id(order)                    -> 3;
enquire_command_id(docid_order)              -> 4;
enquire_command_id(weighting_scheme)         -> 5;
enquire_command_id(cutoff)                   -> 6;
enquire_command_id(collapse_key)             -> 7.


-spec order_type_id(xapian_type:x_order_type()) -> non_neg_integer().
order_type_id(key)                -> 1;
order_type_id(value)              -> 2;
order_type_id(key_relevance)      -> 3;
order_type_id(relevance_key)      -> 4;
order_type_id(relevance_value)    -> 5;
order_type_id(value_relevance)    -> 6.


sort_order_value_type(X) ->
    if in(X, [key, key_relevance, relevance_key]) -> key;
       in(X, [value, value_relevance, relevance_value]) -> value
       end.


docid_order_type_id(default)    -> 0;
docid_order_type_id(asc)        -> 0;
docid_order_type_id(desc)       -> 1;
docid_order_type_id(undefined)  -> 2;
docid_order_type_id(dont_care)  -> 2.


%% ------------------------------------------------------------
%% Values Count Spy (used with term iterators)
%% ------------------------------------------------------------

spy_type_id(values)     -> 0;
spy_type_id(top_values) -> 1.

query_parser_type_id(unstem)    -> 0;
query_parser_type_id(stop_list) -> 1.

db_term_iter_type_id(synonyms)      -> 0;
db_term_iter_type_id(spellings)     -> 1;
db_term_iter_type_id(synonym_keys)  -> 2;
db_term_iter_type_id(all_terms)     -> 3;
db_term_iter_type_id(metadata_keys) -> 4.


term_field_id(stop)            -> 0;
term_field_id(value)           -> 1;
term_field_id(wdf)             -> 2;
term_field_id(freq)            -> 3;
term_field_id(positions)       -> 4;
term_field_id(position_count)  -> 5;
term_field_id(float_value)     -> 6.

   
%% used with a record
document_field_id(stop)           -> 0;
document_field_id(value)          -> 1;
document_field_id(float_value)    -> 2;
document_field_id(data)           -> 3;
document_field_id(docid)          -> 4;
document_field_id(weight)         -> 5;
document_field_id(rank)           -> 6;
document_field_id(percent)        -> 7;
document_field_id(multi_docid)    -> 8;
document_field_id(db_number)      -> 9;
%% db_name and db_number have the same nature.
document_field_id(db_name)        -> document_field_id(db_number);
document_field_id(collapse_key)   -> 10;
document_field_id(collapse_count) -> 11.


resource_encoding_schema_id(reference)    -> 56;
resource_encoding_schema_id(constructor)  -> 97;
resource_encoding_schema_id(undefined)    -> 61.

parse_string_field_id(stop)                     -> 0;
parse_string_field_id(query_resource)           -> 1;
parse_string_field_id(corrected_query_string)   -> 2.
