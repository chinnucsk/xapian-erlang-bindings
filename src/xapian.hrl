-record(internal_qlc_info, {
    num_of_objects :: non_neg_integer(),
    resource_number :: non_neg_integer()
}).

-record(internal_qlc_mset_parameters, {
    record_info %% see function xapian_record:record
}).