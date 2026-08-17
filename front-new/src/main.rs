#[cfg(target_arch = "wasm32")]
use wasm_bindgen::prelude::*;

slint::include_modules!();

#[cfg_attr(
    target_arch = "wasm32",
    wasm_bindgen(start)
)]
pub fn main() -> Result<(), slint::PlatformError> {
    let app = MainWindow::new()?;

    app.run()
}


