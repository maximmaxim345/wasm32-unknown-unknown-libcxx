mod autoffi;

#[cxx::bridge]
mod ffi {
    unsafe extern "C++" {
        include!("test.hpp");

        fn CxxTestFunction(a: i32, b: i32, c: i32) -> i32;
    }
}

pub use autoffi::AutoCxxTestFunction;
pub use ffi::CxxTestFunction;
use iced::widget::{column, container, slider, text};
use iced::{Center, Element, Fill};

#[cfg_attr(target_arch = "wasm32", wasm_bindgen::prelude::wasm_bindgen)]
pub fn start() {
    #[cfg(target_arch = "wasm32")]
    {
        console_log::init().expect("Initialize logger");
        std::panic::set_hook(Box::new(console_error_panic_hook::hook));

        // Call constructors to init global objects in C++ code
        extern "C" {
            fn __wasm_call_ctors();
        }
        unsafe {
            __wasm_call_ctors();
        }
    }

    #[cfg(not(target_arch = "wasm32"))]
    tracing_subscriber::fmt::init();

    iced::application("Rust C++ WASM Interop demo", Demo::update, Demo::view)
        .centered()
        .run()
        .expect("running failed");
}

#[derive(Default)]
pub struct Demo {
    slider: i32,
}

#[derive(Debug, Clone)]
pub enum Message {
    SliderChanged(i32),
}

impl Demo {
    fn update(&mut self, event: Message) {
        match event {
            Message::SliderChanged(value) => self.slider = value,
        }
    }

    fn view(&self) -> Element<Message> {
        let content = column![text("slider").size(50)]
            .spacing(20)
            .push(
                "Use the slider to select a value between \
                 0 and 100:",
            )
            .push(slider(0..=100, self.slider, Message::SliderChanged))
            .push(text(self.slider.to_string()).width(Fill).align_x(Center))
            .push(text(format!(
                "Result of CppFunction({}, 0, 12341): {}",
                self.slider,
                CxxTestFunction(self.slider, 0, 12341)
            )))
            .push(text(format!(
                "Result of AutoCppFunction({}, 0, 12341): {}",
                self.slider,
                AutoCxxTestFunction(self.slider.into(), 0.into(), 12341.into(),).0
            )));
        container(content).center_y(Fill).into()
    }
}

#[cfg(target_arch = "wasm32")]
const ALIGN: usize = 8;

// malloc and free implementations from https://github.com/rusqlite/rusqlite
#[cfg(target_arch = "wasm32")]
#[no_mangle]
pub unsafe extern "C" fn malloc(size: usize) -> *mut u8 {
    let layout = match std::alloc::Layout::from_size_align(size + ALIGN, ALIGN) {
        Ok(layout) => layout,
        Err(_) => return std::ptr::null_mut(),
    };

    let ptr = std::alloc::alloc(layout);
    if ptr.is_null() {
        return std::ptr::null_mut();
    }

    *(ptr as *mut usize) = size;
    ptr.offset(ALIGN as isize)
}

#[cfg(target_arch = "wasm32")]
#[no_mangle]
pub unsafe extern "C" fn free(ptr: *mut u8) {
    let ptr = ptr.offset(-(ALIGN as isize));
    let size = *(ptr as *mut usize);
    let layout = std::alloc::Layout::from_size_align_unchecked(size + ALIGN, ALIGN);

    std::alloc::dealloc(ptr, layout);
}

#[cfg(target_arch = "wasm32")]
#[no_mangle]
pub unsafe extern "C" fn realloc(ptr: *mut u8, new_size: usize) -> *mut u8 {
    let ptr = ptr.offset(-(ALIGN as isize));
    let size = *(ptr as *mut usize);
    let layout = std::alloc::Layout::from_size_align_unchecked(size + ALIGN, ALIGN);

    let ptr = std::alloc::realloc(ptr, layout, new_size + ALIGN);
    if ptr.is_null() {
        return std::ptr::null_mut();
    }

    *(ptr as *mut usize) = new_size;
    ptr.offset(ALIGN as isize)
}

// These silences the linker errors
#[cfg(target_arch = "wasm32")]
#[no_mangle]
pub unsafe extern "C" fn __cxa_allocate_exception() {}

#[cfg(target_arch = "wasm32")]
#[no_mangle]
pub unsafe extern "C" fn __cxa_throw() {}
