autocxx::include_cpp! {
    #include "test.hpp"
    safety!(unsafe)
    generate!("AutoCxxTestFunction")
}

pub use ffi::*;
