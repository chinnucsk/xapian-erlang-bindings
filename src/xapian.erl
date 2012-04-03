-module(xapian).
-export_type([
    x_string/0, 
    x_slot_name/0, 
    x_slot/0, 
    x_document_index_part/0]).

-export_type([
    x_server/0]).

-include_lib("xapian/include/xapian.hrl").


-type x_string()        :: binary().
-type x_slot_name()     :: atom().
-type x_slot()          :: non_neg_integer().
-type x_position()      :: non_neg_integer().
-type x_wdf()           :: non_neg_integer().

-type x_term()          :: #x_term{}.
-type x_value()         :: #x_value{}.
-type x_data()          :: #x_data{}.
-type x_text()          :: #x_text{}.
-type x_delta()         :: #x_delta{}.

-type x_document_index_part() :: x_term() 
    | x_value() 
    | x_data() 
    | x_delta() 
    | x_text().

-type x_server() :: pid().